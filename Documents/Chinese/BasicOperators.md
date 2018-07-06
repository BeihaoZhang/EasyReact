# 基本操作

本文档概要地介绍了 EasyReact 中的常见操作，并提供了对应的示例代码。

**监听一个 Node**

- [在监听Node的时候获取Node的立即值](#在监听Node的时候获取Node的立即值)

- [监听Node后续值的变化](#监听Node后续值的变化)

**基本变换**


- map

- filter


**组合变换**

- combine

- zip

**双向变换**

- syncWith

**高阶变换**

- flatten

- flattenMap

**使用Transform动态组合**

- 使用`EZRTransform`连连接两个Node

- 使用其他Transform连接两个Node

- 断开Node的关系


## 监听一个Node

### 在监听Node的时候获取Node的立即值

一个Node代表了一系列未来值的变化，但是Node为保存一个 最后一次的值。

 如果一个Listener开始监听到这个Node，如果当前Node不为 `Empty` 则Listener会立即收到上一次Node所保留的值。

```objectivec
EZRNode<NSNumber *> *node = [EZRNode value:@1];
NSObject *listener = [NSObject new];
// print 1
[[node listenedBy:listener] withBlock:(NSNumber * _Nullable next) {
  NSLog(@"%@", next);
}]
```

### 监听Node后续值的变化

由于 `EZRNode` 是不可变的，不能对其进行赋值，这里我们使用 `EZRNode` 的子类 `EZRMutableNode` 来演示。在未来值被传递时，Listener 会收到最新的值。

```objectivec
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
NSObject *listener = [NSObject new];
// print 1 2 3 
[[node listenedBy:listener] withBlock:(NSNumber * _Nullable next) {
  NSLog(@"%@", next);
}]

node.value = @1;
node.value = @2;
node.value = @3
```

## 基本变换

### map

`map:` 方法使用了一个具有映射功能的Transform来连接两个Node，生成的新Node会是当前Node的Downstream Node。

当Upstream Node的值发生变化时，会在Transform中先被处理再传递给新Node。

```objectivec
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
EZRNode<NSString *> *stringNode = [node map:^id _Nullable(NSNumber * _Nullable next) {
  return [next stringValue];
}];
NSObject *listener = [NSObject new];

// print @"10" @"20"
[[stringNode listenedBy:listener] withBlock:^(NSString * _Nullable next) {
  NSLog(@"%@", next);
}];

node.value = @10;
node.value = @20;
```

### filter

`filter:` 方法使用了一个具有过滤功能的Transform来连接两个Node，生成的新Node会是当前Node的Downstream Node。

当Upstream Node的值发生变化时，只有满足过滤条件的值才会传递给Downstream Node。

```objectivec
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
EZRNode<NSNumber *> *filteredNode = [node filter:^BOOL(NSNumber * _Nullable next) {
  return [next integerValue] > 5;
}];
NSObject *listener = [NSObject new];

// only print @10
[[filteredNode listenedBy:listener] withBlock:^(NSString * _Nullable next) {
  NSLog(@"%@", next);
}];

node.value = @1;
node.value = @10;
```

## 组合变换

### combine

`combine:` 方法组合了多个Node，在多个Node发生值变化的时候，将所有Node的最新值打包为元组（Tuple）传递到Downstream Node。

```objectivec
EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode new];
EZRMutableNode<NSString *> *node2 = [EZRMutableNode new];
EZRNode<ZTuple2<NSNumber *, NSString *> *> *combinedNode = [EZRNode combine:@[node1, node2]];

NSObject *listener = [NSObject new];
// print (10, A) (20, A) (20, B)
[[combinedNode listenedBy:listener] withBlock:^(ZTuple2<NSNumber *,NSString *> * next) {
  NSLog(@"%@", next);
}];

node1.value = @1;
node1.value = @10;
node2.value = @"A";
node1.value = @20;
node2.value = @"B";
```

### zip

`zip:` 方法像拉链一样，一一匹配多个Node，将多个Node的值打包为一个元组（Tuple）传递到Downstream Node。

```objectivec
EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode new];
EZRMutableNode<NSString *> *node2 = [EZRMutableNode new];
EZRNode<ZTuple2<NSNumber *, NSString *> *> *zipedNode = [EZRNode zip:@[node1, node2]];

NSObject *listener = [NSObject new];

// print (1, A) (10, B)
[[zipedNode listenedBy:listener] withBlock:^(ZTuple2<NSNumber *,NSString *> * _Nullable next){
  NSLog(@"%@", next);
}];

node1.value = @1;
node1.value = @10;
node2.value = @"A";
node1.value = @20;
node2.value = @"B";
```

## 双向变化

### syncWith

`syncWith:` 可以同步两个Node，当其中任意一个Node发生变化时，都会同步到另外一个。

```objectivec
EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *node2 = [EZRMutableNode new];
NSObject *listener = [NSObject new];


[[node1 listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
  NSLog(@"node1:%@", next);
}];
[[node2 listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
  NSLog(@"node2:%@", next);
}];

[node1 syncWith:node2];

node1.value = @1;
node2.value = @2;
// print 
2018-04-26 11:35:20.215441+0800 EasyReact_Example[34073:3694571] node1:1
2018-04-26 11:35:20.216315+0800 EasyReact_Example[34073:3694571] node2:1
2018-04-26 11:35:20.217479+0800 EasyReact_Example[34073:3694571] node2:2
2018-04-26 11:35:20.218413+0800 EasyReact_Example[34073:3694571] node1:2
```

## 高阶变换

### flatten

`flatten` 方法适用于传递Node的Node。 此方法将多个Node的序列合并为单个序列， 并且在任意一个Node值产生变化时都传递给最新的Downstream Node。

```objectivec
EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *node2 = [EZRMutableNode new];
EZRMutableNode<EZRNode<NSNumber *> *> *highOrderNode = [EZRMutableNode new];
EZRNode<NSNumber *> *flattenedNode = [highOrderNode flatten];

NSObject *listener = [NSObject new];
// print 1 2
[[flattenedNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
  NSLog(@"%@", next);
}];

highOrderNode.value = node1;
node1.value = @1;
highOrderNode.value = node2;
node2.value = @2;
```

### flattenMap

`flattenMap:` = `map:` + `flatten`, 也就是说在一个Node的值发生变化时，将值生成一个新的Node，再将这些新Node压平放回单层的序列中。通常可以用来扩展值的变化序列。

```objectivec
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];

EZRNode *flattenNode = [node flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
  EZRMutableNode *innerNode = [EZRMutableNode value:next];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    innerNode.value = @([next integerValue] * 10);
  });
  return innerNode;
}];

self.listener = [NSObject new];
[[flattenNode listenedBy:self] withBlock:^(NSNumber * _Nullable next) {
  NSLog(@"%@", next);
}];
node.value = @10;


// will print  10 after 0.5s print 100 

```

## 使用Transform动态组合

### 使用`EZRTransform`连连接两个Node

一个Transform对象可以通过设置 `form` 和 `to` 来连接两个Node。

```objectivec
EZRMutableNode<NSNumber *> *serverNode = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *labelNode = [EZRNode new];

NSObject *listener = [NSObject new];

[[labelNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
  NSLog(@"%@", next);
}];
EZRTransform *transform = [EZRTransform new];
transform.from = serverNode;
transform.to = labelNode;
// should print 1
serverNode.value = @2;
// should print 2
```

### 使用其他Transform连接两个Node

`EZRTransform`本身是没有变换的，他会保持传递来的值，并将其传递下去。当这种不改变值的Transform对象不能满足我们对数据加工处理的需求时，我们可以通过`EZRTransform`的子类，诸如 `EZRMapTransform`等，这种带有对数据加工操作的Transform，来对上游传递来的值进行变换。

```objectivec
EZRMutableNode<NSNumber *> *serverNode = [EZRMutableNode value:@1];
EZRNode<NSString *> *labelNode = [EZRNode new];

NSObject *listener = [NSObject new];

[[labelNode listenedBy:listener] withBlock:^(NSString * _Nullable next) {
  NSLog(@"%@", next);
}];
EZRTransform *transform = [[EZRMapTransform alloc] initWithMapBlock:^id _Nullable(NSNumber * value) {
  return [NSString stringWithFormat:@"price :￥%@", value.stringValue];
}];
transform.from = serverNode;
transform.to = labelNode;
// should print @"price :1"
serverNode.value = @2;
// should print @"price :2"
```

## 断开Node的关系

当我们不再需要两个Node同步数据的时候我们只需要断开Transform的连接即可。

```objectivec
EZRMutableNode<NSNumber *> *serverNode = [EZRMutableNode new];
EZRNode<NSString *> *labelNode = [EZRNode new];

NSObject *listener = [NSObject new];

[[labelNode listenedBy:listener] withBlock:^(NSString * _Nullable next) {
  NSLog(@"%@", next);
}];
EZRTransform *transform = [EZRTransform new];
transform.from = serverNode;
transform.to = labelNode;
serverNode.value = @1;
// should print @"price :1"

transform.to = nil;
serverNode.value = @2;
// nothing happen 
```
