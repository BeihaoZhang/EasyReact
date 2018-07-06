# 内存管理

EasyReact 的内存管理逻辑非常简单，但是也非常精巧。可以让框架使用者无需关注太多的细节即可轻松的使用，也不必担心带来理解上的困惑。

对于一个基于图论的框架来说，节点和边是最小的单元，通常你会构造一个非常庞大的有向有环图的结构，如果我们疲于让开发者来维护这些节点和有向边的生命周期来说，那么开发者也会无情的抛弃我们。

## EasyReact 中的核心概念

### EZRNode

表示了图论中点的概念，同时也代表了一个值未来的预期，一个点可以被监听者关心，或者是被下游的节点关心。

### EZRTransformProtocol

表示了图论中有向边的概念，边的上游是节点，是数据流的来源者。

#### EZRTransformEdge

表示了一种从节点指向节点的边，这种边关心的是如何将数据加工并且传递给下游节点。

#### EZRListenEdge

表示了一种从节点指向监听者的边，这种边的关心的是如何在未来值发送变化时传递给监听者。

### Listener

监听者是一种特殊类型的节点，关于数据节点在未来发生的数据变化。

## 中间Node

Node 包含了fork, map, filter, skip, take, ignore, select等操作。对于绝大部分的Node操作，会返回新的Node，并通过某种Transform把原Node和新的Node连接起来。由于返回的是Node，这让我们可以用链式方法调用，而不必保存每一次操作返回的Node。举个例子，我们可以对Node先map再filter，而通常我们不关心map返回的Node，因为这是一个中间Node，它连接到了最终filter操作创建出来的Node上。

## Life Time

在本框架中，Node、Listener 和 Transform组成了图的结构，维系着数据的响应关系。由于本框架是面向对象的响应式框架，所以Node、Listener和Transform都是对象。不管是否保存了中间Node，对于如何维持这些对象的生命周期来让整个响应关系保持稳定，是一个重要的问题。

本框架中，Node、Listener 和 Transform的规则如下：

- 一个Listener 强持有了其所有Upstream Transform。
- 一个Transform的`from`强持有了一个Node，而`to`弱引用了一个Node。
- 一个Node 强持有了其所有Upstream Transform，弱引用了其所有Downstream Transform。

也就是说，在一个响应链中，始终是数据的消费者持有了数据的提供者。当数据不再有消费者时，数据的提供者也就没有必要存在了。

## API使用分析

对于某个使用 EZRNode 的 API 接口中，通常会暴露一个 EZRNode 节点。
对于这个 API 的使用者来言，会有两种经典的场景。 

1. 对一个节点进行变换得到衍生节点， 示例如下：

```ObjC

ERNode<NSNumber *> *node = [ERNode value:@1];

ERNode<NSNumber> *filteredNode = [[node map:^id _Nullable(NSNumber * _Nullable next) {

    return @([next.integerValue *2]);

}] filter:^BOOL(NSNumber * _Nullable next) {

    return next.integerValue > 0;
}];
```

2. 对一个节点的值进行监听， 示例如下：

```ObjC

ERNode<NSNumber *> *node = [ERNode value:@1];

NSObject *listener = [NSObject new];

[[node listenedBy:listener] withBlock:^(id next) {}];
```

需要注意的是，在得到衍生节点的 case 中 ，对 Node 的每一次变换操作都会得到一个新的衍生节点。 所以在内存结构中其实有一个中间节点存在。

```

Node ----> MapedNode ----> FilteredNode
```

以上的节点衍生关系中存在 3个节点对象 和 2个有向边对象。

在监听节点的 case 中， 其实也是存在一条 有向边 来传递上游节点值的变化到监听者。

```

Node ----> Listener
```

## 内存管理设计原则

在前面的使用场景中，我们注意到的是无论是对节点的衍生，或者是监听，都会产生很多中间节点和有向边的实例，这些实例参与了计算和传递数据的工作，因此它们的生命周期应该被自动管理。

在内存中的边和节点那些才是使用者关心的？

通常我们对一个节点进行如果有兴趣，那么我们可能直接对其监听， 如果这个节点的数据需要加工才能使用，我们会对去进行衍生，然后再监听，这些节点的共同点是他们都是末端节点。因此答案也就显而易见了。

所以我们的内存持有关系是与数据流传递的方向相反。

数据从上游节点流向有向边，在有向边中被加工之后传递给下游节点/监听者。

而持有关系是下游节点持有上游的边，边来持有上游的节点。中点节点和边像一条铁链一样呗下游节点持有，在下游节点销毁的时候自动断开关系。

他们在代码中的实现如下：

```ObjC

@protocol EZRTransformProtocol <NSObject>

@property (atomic, strong, nullable) EZRNode *from;


@property (atomic, weak, nullable) id to;

@end


@interface EZRNode () {
    NSMutableSet<id<EZRTransformEdge>> *_upstreamTransforms;
    NSHashTable<id<EZRTransformEdge>> *_downstreamTransforms;
    NSHashTable<id<EZRListenEdge>> *_listenTransforms;

}
```

## 关于 self

需要注意的是通常我们在监听的方法里面会使用到self 这时候 由于 self 已经持有了 ListenTransform， 如果捕获了 self，将会出现内存泄露。

```ObjC

[[someNode listenedBy:self] withBlock:^(id next){
    [self dosomething ]
}];

self ----> ListenTransform ----> Block ----> self
```

为此我们提供了 `@erz_weakify(self)` 和  `@erz_strongify(self)` 来解决循环引用的问题。

最佳实践如下

```objectivec

@ezr_weakify(self)
[[someNode listenedBy:self] withBlock:^(id next){
    @ezr_strongifu(self)
    [self dosomething ]
}];
```
