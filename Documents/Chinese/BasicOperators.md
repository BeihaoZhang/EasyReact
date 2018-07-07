# 基本操作

本文档概要地介绍了 EasyReact 中的常见操作，并提供了对应的示例代码。

## 目录

<!-- TOC -->

- [创建节点](#创建节点)
  - [创建不变节点](#创建不变节点)
  - [创建可变节点](#创建可变节点)
- [修改节点的值](#修改节点的值)
- [获取节点的值](#获取节点的值)
  - [获取即时值](#获取即时值)
  - [监听节点值](#监听节点值)
  - [多线程下的监听](#多线程下的监听)
- [连接两个节点](#连接两个节点)
  - [如何连接两个节点](#如何连接两个节点)
  - [断开两个节点](#断开两个节点)
  - [隐式的连接两个节点](#隐式的连接两个节点)
- [基本变换](#基本变换)
  - [map](#map)
  - [filter](#filter)
  - [distinctUntilChanged](#distinctuntilchanged)
  - [throttle](#throttle)
  - [skip](#skip)
  - [take](#take)
  - [deliverOn](#deliveron)
  - [delay](#delay)
  - [scan](#scan)
- [组合](#组合)
  - [combine](#combine)
  - [merge](#merge)
  - [zip](#zip)
- [分支](#分支)
  - [switch-case-default](#switch-case-default)
  - [if-then-else](#if-then-else)
- [同步](#同步)
  - [syncWith](#syncwith)
  - [手动同步](#手动同步)
- [高阶变换](#高阶变换)
  - [flatten](#flatten)
  - [flattenMap](#flattenmap)
- [图遍历](#图遍历)
  - [简单访问](#简单访问)
  - [访问器模式](#访问器模式)

<!-- /TOC -->

## 创建节点

节点是 EasyReact 的基本部件，也是最重要的部件之一，虽然上层框架和其他的支持库中可能都直接以返回值的形式提供了节点，但是自己创建节点总是需要的。

### 创建不变节点

创建不变的节点有两种方式，一种是给出初始值，另一种是直接 new 出来。像这样：

```objective-c
EZRNode *nodeA = [EZRNode value:@15];                 // <- 以初始值创建
EZRNode *nodeB = [EZRNode new];                       // <- 直接创建，初始值为 EZREmpty.empty
EZRNode<NSNumber *> *nodeC = [EZRNode value:@33];     // <- 创建带 NSNumber 泛型的节点
```

### 创建可变节点

EZRNode 代表了不可变的节点，而更多的时候，我们需要可变的节点。创建可变的节点方法是和不可变节点一样的：

```objective-c
EZRMutableNode *nodeA = [EZRMutableNode value:@15];               // <- 以初始值创建
EZRMutableNode *nodeB = [EZRMutableNode new];                     // <- 直接创建，初始值为 EZREmpty.empty
EZRMutableNode<NSNumber *> *nodeC = [EZRMutableNode value:@33];   // <- 创建带 NSNumber 泛型的可变节点
```

我们也可以将一个不可变节点变为可变节点，像这样：

```objective-c
EZRNode<NSNumber *> *nodeC = [EZRNode value:@33];
EZRMutableNode<NSNumber *> *mutableNodeC = nodeC.mutablify;
```

改变节点的不可变性并不会返回新的实例，所以 mutableNodeC 和 nodeC 的地址是相同的。而且变换是单向的，我们也无法将可变节点重新变为不要可变的，请大家注意。

我们可以通过`BOOL mutable`属性来判断一个节点是可变还是不可变的，它的别名是`isMutable`，像这样：

```objective-c
EZRNode<NSNumber *> *nodeC = [EZRNode value:@33];
BOOL mutable = nodeC.mutable;                                 // <- NO
EZRMutableNode<NSNumber *> *mutableNodeC = nodeC.mutablify;
mutable = [nodeC isMutable];                                  // <- YES
mutable = [mutableNodeC isMutable];                           // <- YES
```

## 修改节点的值

对于 EZRMutableNode\<T\> 类的实例来说，`T value`属性是可写并且线程安全的。我们可以通过点语法来修改一个可变节点的值，像这样：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@55];
node.value = @82;
```

有的时候，你希望将一个可变节点重新修改为空值（`EZREmpty.empty`)，由于泛型约束通过点语法会产生警告，你可以使用`- (void)clean`方法，像这样：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@55];
[node clean];                                                   // <- 修改为 EZREmpty.empty
id value = node.value;                                          // <- EZREmpty.empty
```

有的时候，你还希望传递过程和接收者获取一些额外的信息，这时你可以利用`- (void)setValue:(nullable T)value context:(nullable id)context`方法给传递过程附加一个上下文对象，像这样：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@55];
[node setValue:@83 context:@"看，是File1.m写的！"];
```

## 获取节点的值

一个节点就象征着一个数据，现在的或者未来的，它是一种预期，所以我们也对应的有获取即时值和获取未来值两种方式。

### 获取即时值

对于一个节点来说，访问`T value`属性是最简单有效的形式，但是由于空值，我们可能需要特殊注意一下：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
NSNumber *value = node.value;                               // <- EZREmpty.empty !!!
node.value = @33;
value = node.value;                                         // <- @33
[node clean];
value = node.value;                                         // <- EZREmpty.empty !!!
```

所以我们在使用的时候不得不进行类型判断，可以对节点进行判断，也可以对返回值进行判断，像这样：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
if([node isEmpty]) {                                       // <- 也可以是 node.empty
  NSNumber *value = node.value;
  // 做你想做的事情吧
}

// 或者这样：
NSNumber *value = node.value;
if ([value isKindOfClass:NSNumber.class]) {
  // 做你想做的事情吧
} else {
  value = @0;
}
```

就像后面的例子那样，你很可能想在空值的时候给个默认值，这时`- (nullable T)valueWithDefault:(nullable T)defaultValue`方法可能对你很有帮助：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
NSNumber *value = [node valueWithDefault:@0];               // <- @0
node.value = @33;
value = [node valueWithDefault:@0];                         // <- @33
```

而对于前面的例子，你只是想要在非空值的时候才做一些动作，则可以使用`- (void)getValue:(void(NS_NOESCAPE ^ _Nullable)(_Nullable T value))processBlock`方法：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
[node getValue:^(NSNumber *value) {
  // 不会执行
}];
node.value = @33;
[node getValue:^(NSNumber *value) {
  // 做你想做的事情吧
}];
```

### 监听节点值

区别于前面的立即值获取，我们可能对一个节点的未来值感兴趣，这就需要通过监听的手段。根据 [FrameworkOverview](./FrameworkOverview.md) 中描述的，我们在监听的过程中，需要监听者这样一个对象，它负责维持这个监听行为。

最简单的监听方式就像这样：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withBlock:^(NSNumber *next) {
  NSLog(@"下一个值是 %@", next);
}];

node.value = @2;
[node clean];
node.value = @3;
listener = nil;
node.value = @4;
```

它的结果如下：

```plaintext
下一个值是 1
下一个值是 2
下一个值是 3
```

通过观察不难发现，在监听过程中我们不会收到空值，并且当监听者不存在的时候，监听的行为也不会执行。

前面也提到过上下文对象的传递，我们可以通过`withContextBlock:`方法来获得其上下文：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withContextBlock:^(NSNumber *next, id context) {
  NSLog(@"下一个值是 %@，上下文是 %@", next, context);
}];

[node setValue:@2 context:@"嘿，是我"];
```

它的结果如下：

```plaintext
下一个值是 1，上下文是 （null)
下一个值是 2，上下文是 嘿，是我
```

### 多线程下的监听

默认情况下，设置线程和监听线程是一致的，例如：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
[NSThread currentThread].threadDictionary[@"flag"] = @"这是主线程";
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withBlock:^(NSNumber *next) {
  NSLog(@"%@：现在收到了 %@", [NSThread currentThread].threadDictionary[@"flag"], next);
}];
NSLog(@"node 已经进行监听了");
node.value = @2;
NSLog(@"node 值已经设置为 2 了");
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  [NSThread currentThread].threadDictionary[@"flag"] = @"这是某个子线程";
  node.value = @3;
  NSLog(@"node 值已经设置为 3 了");
});
```

它的结果如下：

```plaintext
这是主线程：现在收到了 1
node 已经进行监听了
这是主线程：现在收到了 2
node 已经值设置为 2 了
这是某个子线程：现在收到了 3
node 已经值设置为 3 了
```

也许这正是你所需要的，但是一不小心就可能造成错误，例如在子线程更新 UI：

```objective-c
EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"你好，世界"];

@ezr_weakify(self)
[[node listenedBy:self] withBlock:^(NSString *next) {
  @ezr_strongify(self)
  self.someLabel.text = next;
}];

dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  node.value = @"一个崩溃在等着你";
});
```

相对的，如果监听行为非常耗时，在主线程监听到新的值会直接让程序无响应：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];

[[node listenedBy:self] withBlock:^(NSNumber *next) {
  for (int i = 0; i < next.intValue; ++i) {
    NSLog(@"报数：%d", i);
  }
}];

node.value = @19999999;
// 天啊，还没执行到我
```

使用`withBlock:on:`或者`withBlockOnMainQueue:`就可以帮助我们解决此类问题：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withBlockOnMainQueue:^(NSNumber *next) {
  NSString *thread = [[NSThread currentThread] isMainThread] ? @"主线程" : @"子线程";
  NSLog(@"[监听1]%@：现在收到了 %@", thread, next);
}];
[[node listenedBy:listener] withBlock:^(NSNumber *next) {
  NSString *thread = [[NSThread currentThread] isMainThread] ? @"主线程" : @"子线程";
  NSLog(@"[监听2]%@：现在收到了 %@", thread, next);
} on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];

NSLog(@"node 已经进行监听了");
node.value = @2;
NSLog(@"node 值已经设置为 2 了");
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  [NSThread currentThread].threadDictionary[@"flag"] = @"这是某个子线程";
  node.value = @3;
  NSLog(@"node 值已经设置为 3 了");
});
```

它的结果如下：

```plaintext
node 已经进行监听了
[监听2]子线程：现在收到了 1
node 值已经设置为 2 了
[监听2]子线程：现在收到了 2
node 值已经设置为 3 了
[监听2]子线程：现在收到了 3
[监听1]主线程：现在收到了 1
[监听1]主线程：现在收到了 2
[监听1]主线程：现在收到了 3
```

## 连接两个节点

EasyReact 的重点就是让节点之间的数据流动起来，所以连接节点是很重要的。

### 如何连接两个节点

两个节点是通过变换来连接的，在源码目录 EasyReact/Classes/Core/NodeTransforms 中我们默认实现了了很多的变换，你也可以通过继承 EZRTransform 类来实现自己的变换，一旦我们创建好一个变换后，就可以通过如下方式进行连接了：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRTransform *transform = [EZRTransform new];
transform.from = nodeA;
transform.to = nodeB;

NSLog(@"%@", nodeB.value);                                      // <- @1
```

也可以通过 EZRNode 的 `linkTo:` 或者 `linkTo:transform` 来实现连接：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRTransform *transform = [EZRTransform new];
[nodeB linkTo:nodeA transform:transform];                       // <- 相当于 transform.from = nodeA; transform.to = nodeB； 请注意方向

EZRMutableNode<NSNumber *> *nodeC = [EZRMutableNode value:@2];
EZRNode<NSNumber *> *nodeD = [EZRNode new];

[nodeD linkTo:nodeC];                                           // <- 相当于 [nodeD linkTo:nodeC transform:[EZRTransform new]];
```

### 断开两个节点

当两个节点不在相关的时候，你需要断开两个节点，如果你还有变换的实例，可以修改 from 或者 to 的属性来断开这两个节点或者改变连接：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRTransform *transform = [EZRTransform new];
[nodeB linkTo:nodeA transform:transform];
NSLog(@"%@", nodeB.value);                                      // <- @1
nodeA.value = @2;
NSLog(@"%@", nodeB.value);                                      // <- @2
transform.to = nil;
nodeA.value = @3;
NSLog(@"%@", nodeB.value);                                      // <- @2，不再跟随 nodeA 的变化而变化了
```

没有变换的实例也没有关系，EZRNode 有`removeDownstreamNode:`、`removeUpstreamNode:`、`removeDownstreamNodes`、`removeUpstreamNodes`等多种方法来断开与其他节点的连接：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

[nodeB linkTo:nodeA];
[nodeB removeUpstreamNode:nodeA];                             // <- 断开与上游 nodeA 的全部连接
[nodeA removeDownstreamNode:nodeB];                           // <- 断开与下游 nodeB 的全部连接
[nodeB removeUpstreamNodes];                                  // <- 断开所有的上游连接
[nodeA removeDownstreamNodes];                                // <- 断开所有的下游连接
```

### 隐式的连接两个节点

很多时候先创建节点再创建变换最后连接下游是我们默认的行为，为了更好的编码，我们提供了衍生变换的方式：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA fork];
```

它等价于：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

[nodeB linkTo:nodeA transform:[EZRTransform new]];
```

相应的，其他变换也都提供了衍生变换的方式：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA map:^NSNumber *(NSNumber *next){
  return @(next.integerValue * 2);
}];
```

它对应等同于：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRMapTransform *mapTransform = [[EZRMapTransform alloc] initWithMapBlock:^NSNumber *(NSNumber *next){
  return @(next.integerValue * 2);
}];
[nodeB linkTo:nodeA transform:mapTransform];
```

这种方式更直观和简单，所以下面在介绍变换的时候，会统一使用衍生的形式来介绍。

## 基本变换

基本变换是一组一元变换形式，每次变换是由一个节点出发，经过计算向其下游节点进行传播的，最基本的`fork`操作就是如此，下面介绍下全部的基本变换形式。

### map

`map:`方法是 EasyReact 相当常用的一个变换方法，它的作用是对上游节点的每一个非空值进行一次计算，并将得到的结果同步的传递给下游节点：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSString *> *nodeB = [nodeA map:^NSString *(NSNumber *next){
  return next.stringValue;
}];

NSLog(@"%@", nodeB.value);                                            // <- @"1"
nodeA.value = @2;
NSLog(@"%@", nodeB.value);                                            // <- @"2"
```

有的时候，可能每次 map 的结果和当前传递的值并没有关系，这样我们就可以用`mapReplace:`来简单处理：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSString *> *nodeB = [nodeA mapReplace:@"叮铃，有值啦！"];

[[nodeB listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"%@", next);
}];
nodeA.value = @2;
nodeA.value = @3;

/* 打印如下：
叮铃，有值啦！
叮铃，有值啦！
叮铃，有值啦！
 */
```

需要注意的是`mapReplace:`创建的边 EZRMapTransform 里面会强持有其入参，注意避免循环引用。

### filter

`filter:`的作用是过滤每个上游的值，将符合条件的值传递给下游：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA filter:^BOOL(NSNumber *next){
  return next.integerValue > 5;
}];

NSLog(@"%@", nodeB.value);                                            // <- EZREmpty()
nodeA.value = @6;
NSLog(@"%@", nodeB.value);                                            // <- @6
nodeA.value = @3;
NSLog(@"%@", nodeB.value);                                            // <- @6
```

对于过滤我们还有两个便捷的方法：`ignore:`和`select:`，它们的作用是分别过滤相同的和不同的，例如：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA ignore:@1];
EZRNode<NSNumber *> *nodeC = [nodeA select:@1];

[[nodeB listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"NodeB 收到 %@", next);
}];
[[nodeC listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"NodeC 收到 %@", next);
}];

nodeA.value = @12;
nodeA.value = @1;
nodeA.value = @7;

/* 打印如下：
NodeC 收到 1
NodeB 收到 12
NodeC 收到 1
NodeB 收到 7
 */
```

### distinctUntilChanged

`distinctUntilChanged`方法将一个不传递重复值的变换传递给其衍生节点，例如：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA distinctUntilChanged];

[[nodeB listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"收到 %@", next);
}];

nodeA.value = @1;
nodeA.value = @2;
nodeA.value = @2;
nodeA.value = @1;
nodeA.value = @2;

/* 打印如下：
收到 1
收到 2
收到 1
收到 2
 */
```

### throttle

节流描述了这样的一种操作，对于上游的值来说，在一定的时间内如果有新的值则不会传递旧的值，如果等待到指定的时间没有新的值再将之前的值传递到下游。由于传递是异步的，所以阀门操作一般需要指定一个 GCD 的队列来告诉 EasyReact 在哪里进行传递。

一般阀门的操作用于搜索输入这样的需求上用来避免多次请求网络：

```objective-c
EZRMutableNode<NSString *> *inputNode = [EZRMutableNode new];
EZRNode<NSString *> *searchNode = [inputNode throttle:1 queue:dispatch_get_main_queue()];             // <- 单位是秒

[[searchNode listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"想要搜索的是 %@", next);
}];

inputNode.value = @"h";
inputNode.value = @"he";
inputNode.value = @"hel";
inputNode.value = @"hell";
inputNode.value = @"hello";

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
  inputNode.value = @"hello ";
  inputNode.value = @"hello w";
  inputNode.value = @"hello wo";
  inputNode.value = @"hello wor";
  inputNode.value = @"hello worl";
  inputNode.value = @"hello world";
});

/* 打印如下：
想要搜索的是 hello
想要搜索的是 hello world
 */
```

大家通常都想要在主队列完成监听，所以`throttleOnMainQueue:`方法快速的提供了阀门到主队列的能力：

```objective-c
EZRMutableNode<NSString *> *inputNode = [EZRMutableNode new];
EZRNode<NSString *> *searchNode = [inputNode throttleOnMainQueue:1];
```

等价于

```objective-c
EZRMutableNode<NSString *> *inputNode = [EZRMutableNode new];
EZRNode<NSString *> *searchNode = [inputNode throttle:1 queue:dispatch_get_main_queue()];
```

### skip

跳过操作顾名思义就是跳过前几个值：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSNumber *> *nodeB = [nodeA skip:2];
NSLog(@"%@", nodeB.value);                                            // <- EZREmpty()
nodeA.value = @1;
NSLog(@"%@", nodeB.value);                                            // <- EZREmpty()
nodeA.value = @2;
NSLog(@"%@", nodeB.value);                                            // <- EZREmpty()
nodeA.value = @3;
NSLog(@"%@", nodeB.value);                                            // <- @3
```

### take

拿取操作顾名思义就是只拿取前几个值：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSNumber *> *nodeB = [nodeA take:2];
NSLog(@"%@", nodeB.value);                                            // <- EZREmpty()
nodeA.value = @1;
NSLog(@"%@", nodeB.value);                                            // <- @1
nodeA.value = @2;
NSLog(@"%@", nodeB.value);                                            // <- @2
nodeA.value = @3;
NSLog(@"%@", nodeB.value);                                            // <- @2
```

### deliverOn

[前面](#多线程下的监听)提到了在多线程下值的修改和监听是同一线程的，我们也可以使用`withBlock:on`或者`withBlockOnMainQueue`在监听的时候进行处理。但是如果在变换的过程中耗时非常长，或者遇到变换中必须在主线程的时候，只在监听上做处理已经满足不了需要了：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSNumber *> *nodeB = [nodeA map:^NSNumber *(NSNumber *next) {
    [NSThread sleepForTimeInterval:next.doubleValue];
    return next;
}];
EZRNode<NSNumber *> *nodeC = [nodeB map:^NSNumber *(NSNumber *next) {
    NSAssert([[NSThread currentThread] isMainThread], @"");
    return next;
}];
nodeA.value = @(999.0);
// 哇，又要等一会了
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    nodeA.value = @3; // 不好，要断言失败了
});
[super viewDidLoad];
```

这时`deliverOn:`和`deliverOnMainQueue`就派上用场了：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
dispatch_queue_t queue = dispatch_queue_create("someQueue", DISPATCH_QUEUE_SERIAL);
EZRNode<NSNumber *> *nodeB = [[nodeA deliverOn:queue] map:^NSNumber *(NSNumber *next) {
    [NSThread sleepForTimeInterval:next.doubleValue];
    return next;
}];
EZRNode<NSNumber *> *nodeC = [[nodeB deliverOnMainQueue] map:^NSNumber *(NSNumber *next) {
    NSAssert([[NSThread currentThread] isMainThread], @"");
    return next;
}];
nodeA.value = @(999.0);
// 嗯，不担心
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    nodeA.value = @3; // 嗯，不担心
});
```

### delay

延迟操作顾名思义就是推迟一段时间后传递给下游节点，由于传递的时候已经找不到之前上游设置的线程，所以延迟操作需要一个 GCD 的队列来派发传递的任务：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSNumber *> *nodeB = [nodeA delay:1 queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
EZRNode<NSNumber *> *nodeC = [nodeA delayOnMainQueue:2];
```

### scan

扫描操作是个稍微复杂一点的操作，它需要传入一个初试值和一个两个入参的 block。当上游第一次有值传递过来的时候，会以初始值和上游当前值调用这个 block，block 的返回值就是下游的值并且这个值会被记下来。以后每次上游有值传递过来的时候，都会以上一次记下来的值和上游当前值调用这个 block，以此循环。例如：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSMutableArray<NSNumber *> *> *nodeB = [nodeA scanWithStart:[NSMutableArray array] reduce:^NSMutableArray *(NSMutableArray *last, NSNumber *current) {
  [last addObject:current];
  return last;
}];
[[nodeB listenedBy:self] withBlock:^(NSMutableArray *array) {
  NSLog(@"接收到 %@", array);
}];
nodeA.value = @1;
nodeA.value = @2;
nodeA.value = @3;
nodeA.value = @4;
nodeA.value = @5;
/* 打印如下：
接收到 (
    1
)
接收到 (
    1,
    2
)
接收到 (
    1,
    2,
    3
)
接收到 (
    1,
    2,
    3,
    4
)
接收到 (
    1,
    2,
    3,
    4,
    5
)
 */
```

其过程如下：

```plaintext
upstream:  -----------1-----------2-----------3-----------4-----------5
                      |           |           |           |           |
start:            []  |           |           |           |           |
                    ↘ ↓           ↓           ↓           ↓           ↓
downstream: ---------[1]-------→[1,2]-----→[1,2,3]---→[1,2,3,4]-→[1,2,3,4,5]
```

## 组合

组合变换是一组多元变换形式，每次变换是由多个节点出发，经过相互计算最终向其下游节点进行传播。在实现的过程中，通常需要借助一个对象把多个变换管理起来，例如源码中的 EasyReact/Core/NodeTransforms/EZRCombineTransformGroup.h。下面介绍下全部的组合变换形式。

### combine

响应式编程经常会使用 a := b + c 来举例，意图是当 b 或者 c 的值发生变化的时候，a 会保持两者的加和。那么在响应式库 EasyReact 中，我们是怎样体现的呢？就是通过 EZRCombine-mapEach 操作：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode value:@2];
EZRNode<NSNumber *> *nodeC = [EZRCombine(nodeA, nodeB) mapEach:^NSNumber *(NSNumber *a, NSNumber *b) {
  return @(a.integerValue + b.integerValue);
}];

nodeC.value;                                                  // <- 1 + 2 = 3
nodeA.value = @4;
nodeC.value;                                                  // <- 4 + 2 = 6
nodeB.value = @6;
nodeC.value;                                                  // <- 4 + 6 = 10
```

### merge

合并操作其实很好理解，合并多个节点作为上游，当任何一个节点有新值的时候，下游都会更新：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode value:@2];
EZRNode<NSNumber *> *nodeC = [nodeA merge:nodeB];

// 首次合并会以最后有值的节点的值作为下游节点的初始值
nodeC.value;                                                  // <- 2
nodeA.value = @3;
nodeC.value;                                                  // <- 3
nodeB.value = @4;
nodeC.value;                                                  // <- 4
```

### zip

拉链操作是这样的一种操作：它将多个节点作为上游，所有的节点的第一个值放在一个元组里，所有的节点的第二个值放在一个元组里……以此类推，以这些元组作为值的就是下游。它就好像拉链一样一个扣着一个：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode value:@2];
EZRNode<EZTuple2<NSNumber *, NSNumber *> *> *nodeC = [nodeA zip:nodeB];

[[nodeC listenedBy:self] withBlock:^(EZTuple2<NSNumber *, NSNumber *> *tuple) {
  NSLog(@"接收到 %@", tuple);
}];
nodeA.value = @3;
nodeA.value = @4;
nodeB.value = @5;
nodeA.value = @6;
nodeB.value = @7;
/* 打印如下：
接收到 <EZTuple2: 0x60800002b140>(
  first = 1;
  second = 2;
  last = 2;
)
接收到 <EZTuple2: 0x60800002ac40>(
  first = 3;
  second = 5;
  last = 5;
)
接收到 <EZTuple2: 0x600000231ee0>(
  first = 4;
  second = 7;
  last = 7;
)
 */
```

其过程如下：

```plaintext
nodeA:  -------1-------3-------4---------------6
               |        ╲        ╲
               |          ╲          ╲
               |            ╲            ╲
               |              ╲              ╲
nodeB:  -------2-----------------+-----5--------+------7
               |                   ╲   |          ╲    |
               ↓                     ↘ ↓            ↘  ↓
nodeC:  -----(1,2)-------------------(3,5)-----------(4,7)
```

## 分支

分支变换与组合变换恰好相反，它通常是由一个上游节点以特定的规则分离出不同的下游节点。下面是全部的分支变换形式。

### switch-case-default

switch-case-default 变换是通过给出的 block 将每个上游的值代入，求出唯一标识符，再分离这些标识符的一种操作。我们举例一个分离剧本的例子：

```objective-c
EZRMutableNode<NSString *> *node = [EZRMutableNode new];
EZRNode<EZRSwitchedNodeTuple<NSString *> *> *nodes = [node switch:^id<NSCopying> _Nonnull(NSString * _Nullable next) {
  NSArray<NSString *> *components = [next componentsSeparatedByString:@"："];
  return components.count > 1 ? components.firstObject: nil;
}];
EZRNode<NSString *> *liLeiSaid = [nodes case:@"李雷"];
EZRNode<NSString *> *hanMeimeiSaid = [nodes case:@"韩梅梅"];
EZRNode<NSString *> *aside = [nodes default];
[[liLeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"李雷节点接到台词： %@", next);
}];
[[hanMeimeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"韩梅梅节点接到台词： %@", next);
}];
[[aside listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"旁白节点接到台词： %@", next);
}];
node.value = @"在一个宁静的下午";
node.value = @"李雷：大家好，我叫李雷。";
node.value = @"韩梅梅：大家好，我叫韩梅梅。";
node.value = @"李雷：你好韩梅梅。";
node.value = @"韩梅梅：你好李雷。";
node.value = @"于是他们幸福的在一起了";
/* 打印如下：
旁白节点接到台词： 在一个宁静的下午
李雷节点接到台词： 李雷：大家好，我叫李雷。
韩梅梅节点接到台词： 韩梅梅：大家好，我叫韩梅梅。
李雷节点接到台词： 李雷：你好韩梅梅。
韩梅梅节点接到台词： 韩梅梅：你好李雷。
旁白节点接到台词： 于是他们幸福的在一起了
 */
```

我们注意到，“李雷节点接到台词： 李雷：大家好，我叫李雷。”这个分支里面所有的值还包含“李雷”这个部分，这显然是不必要的，所以我们可能需要在拆分的过程中修改原始的内容，switchMap-case-default 就可以很好的解决了：

```objective-c
EZRMutableNode<NSString *> *node = [EZRMutableNode new];
// 只需要改下面这里
EZRNode<EZRSwitchedNodeTuple<id> *> *nodes = [node switchMap:^EZTuple2<id<NSCopying>,id> * _Nonnull(NSString * _Nullable next) {
  NSArray<NSString *> *components = [next componentsSeparatedByString:@"："];
  if (components.count > 1) {
    NSString *actorLines = [next substringFromIndex:components.firstObject.length + 1];
    return EZTuple(components.firstObject, actorLines);
  } else {
    return EZTuple(nil, next);
  }
}];

EZRNode<NSString *> *liLeiSaid = [nodes case:@"李雷"];
EZRNode<NSString *> *hanMeimeiSaid = [nodes case:@"韩梅梅"];
EZRNode<NSString *> *aside = [nodes default];
[[liLeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"李雷节点接到台词： %@", next);
}];
[[hanMeimeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"韩梅梅节点接到台词： %@", next);
}];
[[aside listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"旁白节点接到台词： %@", next);
}];
node.value = @"在一个宁静的下午";
node.value = @"李雷：大家好，我叫李雷。";
node.value = @"韩梅梅：大家好，我叫韩梅梅。";
node.value = @"李雷：你好韩梅梅。";
node.value = @"韩梅梅：你好李雷。";
node.value = @"于是他们幸福的在一起了";
/* 打印如下：
旁白节点接到台词： 在一个宁静的下午
李雷节点接到台词： 大家好，我叫李雷。
韩梅梅节点接到台词： 大家好，我叫韩梅梅。
李雷节点接到台词： 你好韩梅梅。
韩梅梅节点接到台词： 你好李雷。
旁白节点接到台词： 于是他们幸福的在一起了
 */
```

### if-then-else

有的时候，你可能只想要区分是否，并不需要太多的分支，这时 if-then-else 刚好满足需要：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
[[[node if:^BOOL(NSNumber *next) {
  return next.integerValue > 0;
}] then:^(EZRNode *node) {
  [[node listenedBy:self] withBlock:^(NSNumber *next) {
    NSLog(@"符合条件的有：%@", next);
  }];
}] else:^(EZRNode *node) {
  [[node listenedBy:self] withBlock:^(NSNumber *next) {
    NSLog(@"不符合条件的有：%@", next);
  }];
}];
node.value = @1;
node.value = @-1;
node.value = @2;
node.value = @0;
node.value = @-3;
/* 打印如下：
符合条件的有：1
不符合条件的有：-1
符合条件的有：2
不符合条件的有：0
不符合条件的有：-3
 */
```

如果想直接拿到是或否两个分支节点，直接使用 if 的返回值`EZRIFResult`就可以了：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
EZRIFResult *result = [node if:^BOOL(NSNumber *next) {
  return next.integerValue > 0;
}];
EZRNode<NSNumber *> *positiveNode = result.thenNode;
[[positiveNode listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"正数的有：%@", next);
}];
node.value = @1;
node.value = @-1;
node.value = @2;
node.value = @0;
node.value = @-3;
/* 打印如下：
正数的有：1
正数的有：2
 */
```

## 同步

EasyReact 是允许环形连接的，环形的连接使得多个节点可以进行同步。下面介绍关于同步的操作。

### syncWith

针对于两个节点的同步，`syncWith`可以快速的帮我们建立两个节点的同步连接：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode new];
id<EZRCancelable> cancelable = [nodeA syncWith:nodeB];      // <- cancelable 用于取消两个节点的同步
nodeA.value = @1;
nodeB.value;                                                // <- @1
nodeB.value = @2;
nodeA.value;                                                // <- @2
[cancelable cancel];
nodeA.value = @3;
nodeB.value;                                                // <- @2
```

除了两个节点的完全同步，我们还可以给同步加正逆变换：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode new];
id<EZRCancelable> cancelable = [nodeA syncWith:nodeB transform:^id _Nonnull(NSNumber * _Nonnull source) {
  return @(source.integerValue / 2);                        // nodeB 每次变的时候 nodeA 怎么变
} revert:^NSNumber * _Nonnull(NSNumber *  _Nonnull target) {
  return @(target.integerValue * 2);                        // nodeA 每次变的时候 nodeB 怎么变
}];
nodeA.value = @1;
nodeB.value;                                                // <- @2
nodeB.value = @4;
nodeA.value;                                                // <- @2
```

### 手动同步

有的时候我们可能还需要多个对象同步，例如 3 个对象想要同步，使用`syncWith`两次是可以的，但是会创建 4 条变换：

```plaintext
                nodeA
                 ↑ |
                 | ↓
      nodeC----→nodeB
        ↑         |
        └---------┘
```

创建 3 条变换是最理想的：

```plaintext
                nodeA
              ↗   |
            ╱     |
          ╱       |
        /         ↓
      nodeC←----nodeB
```

这时你需要手动来创建同步的几条边：

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeC = [EZRMutableNode new];
[nodeB linkTo:nodeA];
[nodeC linkTo:nodeB];
[nodeA linkTo:nodeC];
nodeA.value = @1;
nodeB.value;                                                // <- @1
nodeC.value;                                                // <- @1
nodeB.value = @2;
nodeC.value;                                                // <- @2
nodeA.value;                                                // <- @2
nodeC.value = @3;
nodeA.value;                                                // <- @3
nodeB.value;                                                // <- @3
```

但是**不要忘记手动断开连接**，否则会导致节点无法释放。

## 高阶变换

高阶总是给人一种十分复杂的感觉，然而在实际的使用中掌握它是有很大好处的。高阶数组是指代数组中每个元素也是数组的数组，所以高阶节点就是指代节点的值也是节点的节点。`EZRNode<EZRNode *>`就是一个这样的节点。下面会介绍高阶变换形式。

### flatten

扁平变换就是把`EZRNode<EZRNode<T> *>`扁平到`EZRNode<T>`的一种变换，它将下游节点始终连接到上游节点的值上，例如：

```objecitve-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeC = [EZRMutableNode new];
EZRMutableNode<EZRNode<NSNumber *> *> *highOrderNode = [EZRMutableNode new];
EZRNode<NSNumber *> *flattenedNode = [highOrderNode flatten];
highOrderNode.value = nodeA;
nodeA.value = @1;
flattenedNode.value;                                                          // <- @1
highOrderNode.value = nodeB;
nodeB.value = @2;
flattenedNode.value;                                                          // <- @2
nodeA.value = @3;
flattenedNode.value;                                                          // <- @2，不再受 node A 影响了
highOrderNode.value = nodeC;
nodeC.value = @4;
flattenedNode.value;                                                          // <- @4
```

### flattenMap

扁平映射变换相当于这样的一系列操作，它先将节点进行映射变换，并且映射的结果统统都是节点，最后再扁平变换一次。为什么我们需要扁平映射变换而不是简单的映射变换呢？是因为映射变换一定是一一对应的，假设上游节点有 10 个值的变化，映射变换后的下游节点一定也有 10 个值的变化。但如果我有 8 个或者 12 个值想要变换呢？那就需要扁平映射变换了；还有映射变换一定都是立即变换的，如果我们需要结果延迟变换，我们也需要扁平映射变换。例如下面的例子：

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
EZRNode<NSNumber *> *flattenMappedNode = [node flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
  NSInteger value = next.integerValue;
  EZRMutableNode<NSNumber *> *insideNode = [EZRMutableNode new];
  EZRNode<NSNumber *> *returnNode = [insideNode deliverOnMainQueue];
  while(value != 0) {
    insideNode.value = @(value % 10);
    value /= 10;
  }
  return returnNode;
}];
[[flattenMappedNode listenedBy:self] withBlock:^(NSNumber * _Nullable next) {
  NSLog(@"FlattenMappedNode 收到了 %@", next);
}];
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  node.value = @12;
});
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  node.value = @0;
});
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  node.value = @27;
});
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  node.value = @9527;
});
/* 打印如下：
FlattenMappedNode 收到了 2
FlattenMappedNode 收到了 1
FlattenMappedNode 收到了 7
FlattenMappedNode 收到了 2
FlattenMappedNode 收到了 7
FlattenMappedNode 收到了 2
FlattenMappedNode 收到了 5
FlattenMappedNode 收到了 9
 */
```

## 图遍历

无论是调试的需要还是修改节点和边，你可能都需要在现有的有向有环图中进行遍历，下面就介绍图遍历的一些方法。

### 简单访问

节点和边有很多属性和方法是用来遍历的，边的 from 和 to 属性就是例子，而节点更多：

| 类型              | 名称                          | 作用                      |
| ----------------- | ---------------------------- | -----------------------  |
| 属性              | upstreamNodes                | 当前节点的所有上游节点        |
| 属性              | downstreamNodes              | 当前节点的所有下游节点        |
| 属性              | upstreamTransforms           | 当前节点的所有上游变换        |
| 属性              | downstreamTransforms         | 当前节点的所有下游变换        |
| 方法              | upstreamTransformsFromNode:  | 上游到达另一个节点的所有的变换 |
| 方法              | downstreamTransformsToNode:  | 下游到达另一个节点的所有的变换 |

除此之外，你可以在调试期间通过节点的`graph`方法来获得一段长文本，它将所有的与之相关的节点和边做成一个 dot 格式的字符串，你也可以用 graphviz 工具来把它生成为一张图片。

Mac OS 下 需要安装 graphviz 命令行工具

```shell
brew install graphviz
```

生成图片

```shell
circo -Tpdf test.dot -o test.pdf && open test.pdf
```

所有的节点和边都有一个 name 属性，设置 name 属性可以在调试过程中更容易发现问题。

### 访问器模式

想要更多的访问一个节点而避免递归这样的复杂度，可以使用访问器模式，实现 EZRNodeVisitor 协议写出自己的逻辑即可。详情和例子可以参考 [EasyReact/Core/EZRNode+Graph.m.](https://github.com/meituan/EasyReact/blob/master/EasyReact/Classes/Core/EZRNode%2BGraph.m) 的实现。
