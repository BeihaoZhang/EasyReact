# 内存管理

对于一个基于图论的框架来说，节点和边是最小的部件。实际应用中，这些部件构成了各种有向图。比如一个有环图，它的数据流动就是一个环形，部件之间的持有关系如果不能很好的处理，那么可能就会存在内存问题。EasyReact 的内存管理逻辑非常简单，也非常精巧。可以让框架使用者无需关注太多的细节即可轻松的使用，而不必担心本框架涉及的内存方面的问题。

## 目录

<!-- TOC -->

- [中间节点](#中间节点)
- [生命周期](#生命周期)
- [API使用分析](#api使用分析)
- [关于 self](#关于-self)
- [关于节点环](#关于节点环)

<!-- /TOC -->

## 中间节点

节点包含了 fork、map、filter、skip、take、ignore、select 等多种操作。对于绝大部分的节点操作，都会返回新的节点，并通过某种变换把源节点和新节点连接起来。由于返回的也是节点，这让我们可以用链式方法调用，而不必用变量保存每一次操作返回的节点。举个例子，我们可以对 someNode 先 map 再 filter，而通常我们不关心 map 返回的节点，因为这是一个中间节点，它连接到了最终 filter 操作创建出来的节点上。

## 生命周期

在本框架中，节点、变换、监听边和监听者组成了有向图的结构，维系着数据的响应关系。由于本框架是面向对象的响应式框架，所以节点、变换、监听边和监听者都是对象。不管是否保存了中间节点，如何维持这些对象的生命周期来让整个响应关系保持稳定，是一个重要的问题。

本框架中，节点、变换、监听边和监听者的持有规则如下：

- 一个监听者强持有了其所有上游监听边；
- 一个边的 from 强持有了一个节点，而 to 弱引用了下游节点或者监听者；
- 一个节点强持有了其所有的上游变换，弱引用了其所有下游变换和下游监听边。

也就是说，在一个响应链中，始终是数据的消费者持有了数据的提供者。当数据不再有消费者时，数据的提供者也就没有必要存在了。

## API使用分析

对于某个使用 EZRNode\<T\> 的 API 接口中，通常会暴露一个 EZRNode 节点。
对于这个 API 的使用者来言，会有两种经典的场景。

1. 对一个节点进行变换得到衍生节点，示例如下：

```objective-c
ERNode<NSNumber *> *node = [ERNode value:@1];

ERNode<NSNumber *> *filteredNode = [[node map:^id _Nullable(NSNumber * _Nullable next) {
    return @([next.integerValue * 2]);
}] filter:^BOOL(NSNumber * _Nullable next) {
    return next.integerValue > 0;
}];
```

1. 对一个节点的值进行监听，示例如下：

```objective-c
ERNode<NSNumber *> *node = [ERNode value:@1];

NSObject *listener = [NSObject new];

[[node listenedBy:listener] withBlock:^(id next) {}];
```

需要注意的是，在得到衍生节点的例子中，对节点的每一次变换操作都会得到一个新的衍生节点。所以实际上会有一个中间节点存在。

```plaintext
Node ==MapTransform==> MappedNode ==FilterTransform==> FilteredNode
```

以上的节点衍生关系中存在 3 个节点对象和 2 个变换对象。其强引用关系正好相反，如下：

```plaintext
Node <-- MapTransform <-- MappedNode <-- FilterTransform <-- FilteredNode
```

因此一旦 FilteredNode 被销毁，则其他对象自动释放（是否销毁取决于是否还有其他对象对其强引用）。

在监听节点的例子中，节点和监听者通过监听边来进行连接。

```plaintext
Node ==BlockListenEdge==> Listener
```

以上的监听关系中存在 2 个节点对象和 1 个监听边对象。其强引用关系也正好相反，如下：

```plaintext
Node <-- BlockListenEdge <-- Listener
```

因此一旦 Listener 被销毁，其他对象会自动释放（是否销毁取决于是否还有其他对象对其强引用）。

## 关于 self

需要注意的是通常我们在监听的方法里面会使用到 self，前面提到过 self 已经持有了监听边，如果监听边捕获了 self，将会出现循环引用从而引起内存泄露。例如：

```objective-c
[[someNode listenedBy:self] withBlock:^(id next){
    [self doSomething];
}];

// someNode <-- BlockListenEdge <-- self
//                    |               ↑
//                    └---------------┘
```

为此我们提供了 `@erz_weakify(...)` 和  `@erz_strongify(...)` 来解决循环引用的问题。

最佳实践如下：

```objective-c
@ezr_weakify(self)
[[someNode listenedBy:self] withBlock:^(id next){
    @ezr_strongify(self)
    [self doSomething];
}];

// 其他对象同样需要
@ezr_weakify(someObject)
[[someNode listenedBy:someObject] withBlock:^(id next){
    @ezr_strongify(someObject)
    [someObject doSomething];
}];
```

## 关于节点环

框架设计中已经处理了对上游链路的强引用，所以节点环就会产生循环引用，一旦产生需要记得必要的时刻进行主动的破除操作，例如下面的例子：

```objective-c
EZRNode<NSNumber *> *nodeA = [EZRNode new];
EZRNode<NSNumber *> *nodeB = [EZRNode new];
EZRNode<NSString *> *nodeC = [EZRNode new];

EZRTransform *transformAtoB = [[EZRMapTransform alloc] initWithMapBlock:^NSNumber *(NSNumber *next) {
    return @(next.integerValue * 2);
}];
EZRTransform *transformBtoC = [[EZRMapTransform alloc] initWithMapBlock:^NSString *(NSNumber *next) {
    return next.stringValue;
}];
EZRTransform *transformCtoA = [[EZRMapTransform alloc] initWithMapBlock:^NSNumber *(NSString *next) {
    return @(next.integerValue / 2);
}];
transformAtoB.from = nodeA;
transformAtoB.to = nodeB;
transformBtoC.from = nodeB;
transformBtoC.to = nodeC;
transformCtoA.from = nodeC;
transformCtoA.to = nodeA;

// 强引用关系如下：
// nodeA <-- transformAtoB <-- nodeB <-- transformBtoC <-- nodeC
//   |                                                       ↑
//   └-------------------->transformCtoA---------------------┘
```

这样，全部的 3 个变换和 3 个节点都不会销毁了，所以 **请务必记得在必要的时刻对任意的边或者点进行破除操作**，方法如下：

```objective-c
// 破除边
transformAtoB.from = nil;
// 或破除点
[nodeA removeDownstreamNode:nodeB];
```

通常情况下我们会对两个节点进行同步而不是更多节点，我们提供了`- (id<EZRCancelable>)syncWith:(EZRNode<T> *)otherNode`和`- (id<EZRCancelable>)syncWith:(EZRNode *)otherNode transform:(id (^)(T source))transform revert:(T (^)(id target))revert`这两个便捷的方法，它们都提供了`id<EZRCancelable>`这个对象，通过该对象的`- (void)cancel`方法，我们就可以快速的破除这两个节点的环了，示例如下：

```objective-c
EZRNode<NSNumber *> *nodeA = [EZRNode new];
EZRNode<NSString *> *nodeB = [EZRNode new];
id<EZRCancelable> *cancelable = [nodeA syncWith:nodeB transform:^NSString *(NSNumber *source) {
    return source.stringValue;
} revert:^NSNumber *(NSString *target) {
    return @(source.integerValue);
}];

// 当需要破除时
[cancelable cancel];
```