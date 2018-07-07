# Basic operation

This document provides an overview of common operations in EasyReact and provides corresponding sample code.

## Table of Contents

<!-- TOC -->

- [Create Node](#create-node)
  - [Create Immutable Nodes](#create-immutable-nodes)
  - [Create Mutable Node](#create-mutable-node)
- [Modify Node's Value](#modify-nodes-value)
- [Get Node's value](#get-nodes-value)
  - [Get Instant Value](#get-instant-value)
  - [Listen Node's Value](#listen-nodes-value)
  - [Listen Under Multithreading](#listen-under-multithreading)
- [Connect Two Nodes](#connect-two-nodes)
  - [How To Connect Two Nodes](#how-to-connect-two-nodes)
  - [Disconnect Two Nodes](#disconnect-two-nodes)
  - [Implicitly Connects Two Nodes](#implicitly-connects-two-nodes)
- [Basic Transformation](#basic-transformation)
  - [map](#map)
  - [filter](#filter)
  - [distinctUntilChanged](#distinctuntilchanged)
  - [throttle](#throttle)
  - [skip](#skip)
  - [take](#take)
  - [deliverOn](#deliveron)
  - [delay](#delay)
  - [scan](#scan)
- [Combination](#combination)
  - [combine](#combine)
  - [merge](#merge)
  - [zip](#zip)
- [Branch](#branch)
  - [switch-case-default](#switch-case-default)
  - [if-then-else](#if-then-else)
- [Sync](#sync)
  - [syncwith](#syncwith)
  - [Manual Sync](#manual-sync)
- [High-order Transformation](#high-order-transformation)
  - [flatten](#flatten)
  - [flattenmap](#flattenmap)
- [Graph Traversal](#graph-traversal)
  - [Simple Access](#simple-access)
  - [Accessor Mode](#accessor-mode)

<!-- /TOC -->

## Create Node

A node is an essential part of EasyReact, and it is one of the most important components. Although the upper frame and other supporting libraries may directly provide nodes in the form of return values, it is always necessary to create nodes by yourself.

### Create Immutable Nodes

There are two ways to create an immutable node. One is to give the initial value and the other is to create by `+ new`. like this:

```objective-c
EZRNode *nodeA = [EZRNode value:@15];                 // <- Created with initial value
EZRNode *nodeB = [EZRNode new];                       // <- Created directly, the initial value is EZREmpty.empty
EZRNode<NSNumber *> *nodeC = [EZRNode value:@33];     // <- Create a node with NSNumber generics
```

### Create Mutable Node

EZRNode represents immutable nodes, and more often we need mutable nodes. Creating a mutable node method is the same as an immutable node:

```objective-c
EZRMutableNode *nodeA = [EZRMutableNode value:@15];             // <- Created with initial value
EZRMutableNode *nodeB = [EZRMutableNode new];                   // <- Directly created, initial value is EZREmpty.empty
EZRMutableNode<NSNumber *> *nodeC = [EZRMutableNode value:@33]; // <- Create a variable node with NSNumber generics
```

We can also change an immutable node to a mutable node like this:

```objective-c
EZRNode<NSNumber *> *nodeC = [EZRNode value:@33];
EZRMutableNode<NSNumber *> *mutableNodeC = nodeC.mutablify;
```

Please pay attention, changing the immutability of a node does not return a new instance, so the addresses of mutableNodeC and nodeC are the same. Moreover, the transformation is one-way, and we cannot change the mutable node back to immutable.

We can use the `BOOL mutable` property to determine whether a node is mutable or immutable. Its alias is `isMutable`, like so:

```objective-c
EZRNode<NSNumber *> *nodeC = [EZRNode value:@33];
BOOL mutable = nodeC.mutable;                                 // <- NO
EZRMutableNode<NSNumber *> *mutableNodeC = nodeC.mutablify;
mutable = [nodeC isMutable];                                  // <- YES
mutable = [mutableNodeC isMutable];                           // <- YES
```

## Modify Node's Value

For instances of the EZRMutableNode\<T\> class, the `T value` attribute is writeable and thread-safe. We can modify the value of a variable node by using a dot syntax, like this:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@55];
node.value = @82;
```

Sometimes, you want to re-modify a mutable node to a null value (`EZREmpty.empty`). Since generic constraints generate warnings via dot syntax, you can use the `-(void)clean` method, like this:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@55];
[node clean];                                                 // <- Modify as EZREmpty.empty
Id value = node.value;                                        // <- EZREmpty.empty
```

Sometimes, you also want to pass the process and the receiver to get some extra information, then you can use the `- (void)setValue: (nullable T)value context:(nullable id)context` method to attach a context to the pass-through procedure. Objects like this:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@55];
[node setValue:@83 context:@"See, it's written by File1.m!"];
```

## Get Node's value

A node symbolizes a piece of data. Now or in the future, it is an expectation, so we also have two ways to get instant value and get future value.

### Get Instant Value

For a node, accessing the `T value` attribute is the simplest and most effective way, but due to null values, we may need special attention:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
NSNumber *value = node.value;                               // <- EZREmpty.empty !!!
node.value = @33;
value = node.value;                                         // <- @33
[node clean];
value = node.value;                                         // <- EZREmpty.empty !!!
```

So when we use it, we have to make type judgments, we can judge the node, we can also determine the return value, like this:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
if([node isEmpty]) {                                        // <- can also be node.empty
   NSNumber *value = node.value;
   // Do whatever you want
}

// Or like this:
NSNumber *value = node.value;
if ([value isKindOfClass:NSNumber.class]) {
   // Do whatever you want
} else {
   value = @0;
}
```

As in the following example, you will probably want to give a default value when null. The `- (nullable T)valueWithDefault:(nullable T)defaultValue` method may be helpful to you:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
NSNumber *value = [node valueWithDefault:@0];               // <- @0
node.value = @33;
value = [node valueWithDefault:@0];                         // <- @33
```

For the previous example, you just want to do something when it's not null, you can use the `- (void)getValue:(void (NS_NOESCAPE^_Nullable)(_Nullable T value))processBlock` method:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
[node getValue:^(NSNumber *value) {
   // Not call
}];
Node.value = @33;
[node getValue:^(NSNumber *value) {
   // Do whatever you want
}];
```

### Listen Node's Value

Different from the previous immediate value acquisition, we may be interested in the future value of a node, which needs to be monitored. According to the description in [FrameworkOverview](./FrameworkOverview.md), we need an object such as a listener during the listening process. It is responsible for maintaining this listening behavior.

The simplest way to listen is like this:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withBlock:^(NSNumber *next) {
   NSLog(@"The next value is %@", next);
}];

Node.value = @2;
[node clean];
Node.value = @3;
Listener = nil;
Node.value = @4;
```

The result is as follows:

```plaintext
The next value is 1
The next value is 2
The next value is 3
```

It is not difficult to find through observation that we will not receive a null value during the listening process, and when the listener does not exist, the listening activity will not be performed.

We also mentioned the passing of the context object. We can get its context through the `withContextBlock:` method:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withContextBlock:^(NSNumber *next, id context) {
   NSLog(@"The next value is %@, the context is %@", next, context);
}];

[node setValue:@2 context:@"Hey, it's me"];
```

Its result is as follows:

```plaintext
The next value is 1, the context is (null)
The next value is 2, the context is Hey, it's me
```

### Listen Under Multithreading

By default, the setting thread and listener thread are the same, for example:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
[NSThread currentThread].threadDictionary[@"flag"] = @"This is the main thread";
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withBlock:^(NSNumber *next) {
   NSLog(@"%@: now received %@", [NSThread currentThread].threadDictionary[@"flag"], next);
}];
NSLog (@"node has been listening");
Node.value = @2;
NSLog (@"node value has been set to 2");
Dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
   [NSThread currentThread].threadDictionary[@"flag"] = @ "This is a child thread";
   Node.value = @3;
   NSLog (@"node value has been set to 3");
});
```

Its result is as follows:

```plaintext
This is the main thread: now received 1
node has been listening
This is the main thread: now received 2
node value has been set to 2
This is a child thread: now received 3
node value has been set to 3
```

Maybe this is exactly what you need, but accidentally it can cause mistakes, such as updating the UI in the child thread:

```objective-c
EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"Hello, World"];

@ezr_weakify(self)
[[node listenedBy:self] withBlock:^(NSString *next) {
   @ezr_strongify(self)
   self.someLabel.text = next;
}];

dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
   Node.value = @ "A crash is waiting for you";
});
```

On the other hand, if the listening activity is time-consuming, listening to the new value in the main thread directly makes the program unresponsive:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];

[[node listenedBy:self] withBlock:^(NSNumber *next) {
   For (int i = 0; i < next.intValue; ++i) {
     NSLog(@"Reports: %d", i);
   }
}];

node.value = @19999999;
// God! I haven’t implemented it yet!
```

Use `withBlock:on:` or `withBlockOnMainQueue:` to help us solve this problem:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
NSObject *listener = [NSObject new];
[[node listenedBy:listener] withBlockOnMainQueue:^(NSNumber *next) {
   NSString *thread = [[NSThread currentThread] isMainThread] ? @ "Main thread": @ "Child thread";
   NSLog(@"[listen1] %@: now received %@", thread, next);
}];
[[node listenedBy:listener] withBlock:^(NSNumber *next) {
   NSString *thread = [[NSThread currentThread] isMainThread] ? @ "Main thread": @ "Child thread";
   NSLog(@"[listen2] %@: now received %@", thread, next);
} on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];

NSLog (@"node has been listening");
node.value = @2;
NSLog (@"node value already set to 2");
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
   [NSThread currentThread].threadDictionary[@"flag"] = @ "This is a child thread";
   Node.value = @3;
   NSLog (@"node value has been set to 3");
});
```

Its result is as follows:

```plaintext
node has been listening
[listen2] Child thread: now received 1
node value has been set to 2
[listen2] Child thread: now received 2
node value has been set to 3
[listen2] Child thread: now received 3
[listen1] Main thread: now received 1
[listen1] Main thread: now received 2
[listen1] Main thread: now received 3
```

## Connect Two Nodes

The focus of EasyReact is to let the data flow between nodes, so connecting the nodes is important.

### How To Connect Two Nodes

The two nodes are connected through transformations. In the source directory EasyReact/Classes/Core/NodeTransforms we implement a lot of transformations by default. You can also implement your own transformation by inheriting the EZRTransform class. Once we have created a transformation, you can connect as follows:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRTransform *transform = [EZRTransform new];
transform.from = nodeA;
transform.to = nodeB;

NSLog(@"%@", nodeB.value);                                      // <- @1
```

You can also connect via EZRNode's `linkTo:` or `linkTo:transform`:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRTransform *transform = [EZRTransform new];
[nodeB linkTo:nodeA transform:transform];                       // <- Equivalent to transform.from = nodeA; transform.to = nodeB; Please note the direction

EZRMutableNode<NSNumber *> *nodeC = [EZRMutableNode value:@2];
EZRNode<NSNumber *> *nodeD = [EZRNode new];

[nodeD linkTo:nodeC];                                           // <- is equivalent to [nodeD linkTo:nodeC transform:[EZRTransform new]];
```

### Disconnect Two Nodes

When the two nodes are not related, you need to disconnect the two nodes. If you have a transformed instance, you can modify the from or to attribute to disconnect the two nodes or change the connection:

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
NSLog(@"%@", nodeB.value);                                      // <- @2，no longer changes following nodeA's changes
```

It doesn't matter that there is no transformation instance. EZRNode has ``removeDownstreamNode:``, ``removeUpstreamNode:``, ``removeDownstreamNodes``, ``removeUpstreamNodes`` and several other methods to disconnect from other nodes:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

[nodeB linkTo:nodeA];
[nodeB removeUpstreamNode:nodeA];                               // <- Disconnect all connections to upstream nodeA
[nodeA removeDownstreamNode:nodeB];                             // <- Disconnect all connections to downstream nodeB
[nodeB removeUpstreamNodes];                                    // <- Disconnect all upstream connections
[nodeA removeDownstreamNodes];                                  // <- Disconnect all downstream connections
```

### Implicitly Connects Two Nodes

Many times, creating nodes first, creating transformations, and finally connecting downstreams is our default behavior. For better coding, we provide a derivative transformation:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA fork];
```

It is equivalent to:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

[nodeB linkTo:nodeA transform:[EZRTransform new]];
```

Correspondingly, other transformations also provide a derivative transformation:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA map:^NSNumber *(NSNumber *next){
  return @(next.integerValue * 2);
}];
```

It corresponds to the equivalent of:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [EZRNode new];

EZRMapTransform *mapTransform = [[EZRMapTransform alloc] initWithMapBlock:^NSNumber *(NSNumber *next){
  return @(next.integerValue * 2);
}];
[nodeB linkTo:nodeA transform:mapTransform];
```

This method is more intuitive and simple, so the following describes the transformation, the unified use of derivative forms to introduce.

## Basic Transformation

A basic transformation is a set of unary transformations. Each transformation starts from a node and is calculated to propagate to its downstream nodes. The basic `fork` operation is the same. The following describes all the basic transformations.

### map

The `map:` method is a fairly common transformation method used by EasyReact. Its role is to perform a computation on each non-null value of the upstream node and pass the result to the downstream node synchronously:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSString *> *nodeB = [nodeA map:^NSString *(NSNumber *next){
  return next.stringValue;
}];

NSLog(@"%@", nodeB.value);                                            // <- @"1"
nodeA.value = @2;
NSLog(@"%@", nodeB.value);                                            // <- @"2"
```

Sometimes, every time the result of the map is not related to the current value passed, we can simply handle it with `mapReplace:`:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSString *> *nodeB = [nodeA mapReplace:@"Yohoo, get a value!"];

[[nodeB listenedBy:self] withBlock:^(NSString *next) {
   NSLog(@"%@", next);
}];
nodeA.value = @2;
nodeA.value = @3;

/* prints as follows:
Yohoo, get a value!
Yohoo, get a value!
Yohoo, get a value!
  */
```

It should be noted that the edge of EZRMapTransform created by `mapReplace:` will have its own input parameter, taking care to avoid circular references.

### filter

The effect of `filter:` is to filter each upstream value and pass the matching value to the downstream:

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

For filtering, we have two convenient methods: `ignore:` and `select:`. Their role is to filter the same and different, respectively. For example:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA ignore:@1];
EZRNode<NSNumber *> *nodeC = [nodeA select:@1];

[[nodeB listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"NodeB received %@", next);
}];
[[nodeC listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"NodeC received %@", next);
}];

nodeA.value = @12;
nodeA.value = @1;
nodeA.value = @7;

/* prints as follows:
NodeC received 1
NodeB received 12
NodeC received 1
NodeB received 7
 */
```

### distinctUntilChanged

The `distinctUntilChanged` method passes a transform that does not pass duplicate values to its descendent node, for example:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRNode<NSNumber *> *nodeB = [nodeA distinctUntilChanged];

[[nodeB listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"Received %@", next);
}];

nodeA.value = @1;
nodeA.value = @2;
nodeA.value = @2;
nodeA.value = @1;
nodeA.value = @2;

/* prints as follows:
Received 1
Received 2
Received 1
Received 2
 */
```

### throttle

Throttle describes such an operation: for the upstream value, if there is a new value in a certain period of time will not pass the old value, if there is no new value waiting for the specified time before passing the previous value Downstream. Because the transfer is asynchronous, throttle operations typically require a GCD queue to tell EasyReact where to pass.

The general throttle operation is used to search input for such a requirement to avoid multiple requests to the network:

```objective-c
EZRMutableNode<NSString *> *inputNode = [EZRMutableNode new];
EZRNode<NSString *> *searchNode = [inputNode throttle:1 queue:dispatch_get_main_queue()]; // <- Unit is second

[[searchNode listenedBy:self] withBlock:^(NSString *next) {
   NSLog(@"You want to search for %@", next);
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

/* prints as follows:
You want to search for hello
You want to search for hello world
  */
```

We usually want to listen in the main queue, so the `throttleOnMainQueue:` method quickly provides throttled capabilities to the main queue:

```objective-c
EZRMutableNode<NSString *> *inputNode = [EZRMutableNode new];
EZRNode<NSString *> *searchNode = [inputNode throttleOnMainQueue:1];
```

Equivalent:

```objective-c
EZRMutableNode<NSString *> *inputNode = [EZRMutableNode new];
EZRNode<NSString *> *searchNode = [inputNode throttle:1 queue:dispatch_get_main_queue()];
```

### skip

The skip operation, as its name suggests, skips the first few values:

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

The take operation, as its name implies, is to take only the first few values:

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

As mentioned [above](#Listen Under Multithreading), the values are modified and listened on the same thread under multithreading. We can also use `withBlock:on` or `withBlockOnMainQueue` when listening. However, if it takes a very long time in the transformation process, or when the transformation must be in the main thread, it is not enough to only do the processing on the listener:

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
// Wow, I have to wait for a while
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  nodeA.value = @3; // Oh no, assert failure
});
[super viewDidLoad];
```

At this point `deliverOn:` and `deliverOnMainQueue` come in handy:

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
}]
nodeA.value = @(999.0);
// Um, don't worry
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  nodeA.value = @3; // Um, don't worry
});
```

### delay

The delay operation, as its name implies, is delayed for some time and passed to the downstream node. Since the previously set upstream thread cannot be found at the time of delivery, the delay operation requires a GCD queue to dispatch the delivered task:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSNumber *> *nodeB = [nodeA delay:1 queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
EZRNode<NSNumber *> *nodeC = [nodeA delayOnMainQueue:2];
```

### scan

The scan operation is a slightly more complicated operation. It needs to pass in an initial test value and a block of two input parameters. When the value is passed for the first time in the upstream, the block is called with the initial value and the current value of the upstream. The block's return value is the downstream value and this value is written down. Each time when there is a value passed upstream, the block is called with the value noted above and the current value of the upstream. E.g:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRNode<NSMutableArray<NSNumber *> *> *nodeB = [nodeA scanWithStart:[NSMutableArray array] reduce:^NSMutableArray *(NSMutableArray *last, NSNumber *current) {
  [last addObject:current];
  return last;
}];
[[nodeB listenedBy:self] withBlock:^(NSMutableArray *array) {
  NSLog(@"Received %@", array);
}];
nodeA.value = @1;
nodeA.value = @2;
nodeA.value = @3;
nodeA.value = @4;
nodeA.value = @5;
/* prints as follows:
Received (
    1
)
Received (
    1,
    2
)
Received (
    1,
    2,
    3
)
Received (
    1,
    2,
    3,
    4
)
Received (
    1,
    2,
    3,
    4,
    5
)
 */
```

The process is as follows:

```plaintext
upstream:  -----------1-----------2-----------3-----------4-----------5
                      |           |           |           |           |
start:            []  |           |           |           |           |
                    ↘ ↓           ↓           ↓           ↓           ↓
downstream: ---------[1]-------→[1,2]-----→[1,2,3]---→[1,2,3,4]-→[1,2,3,4,5]
```

## Combination

Combining transformation is a set of multivariate transformations. Each transformation is initiated by multiple nodes. After mutual calculation, it finally propagates to its downstream nodes. In the implementation process, it is usually necessary to manage multiple transformations with one object, such as EasyReact/Core/NodeTransforms/EZRCombineTransformGroup.h in the source code. The following introduces all the combinations of transformations.

### combine

Reactive programming often uses a := b + c as an example. The intent is that a will maintain the sum of the two when the value of b or c changes. How do we embody this in the responsive library, EasyReact? It is through EZRCombine-mapEach operation:

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

Merge operation is actually very easy to understand, merge multiple nodes as upstream, when any node has a new value, the downstream will be updated:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode value:@2];
EZRNode<NSNumber *> *nodeC = [nodeA merge:nodeB];

// The first merge will use the value of the last valued node as the initial value of the downstream node
nodeC.value;                                                  // <- 2
nodeA.value = @3;
nodeC.value;                                                  // <- 3
nodeB.value = @4;
nodeC.value;                                                  // <- 4
```

### zip

A zipper operation is one such operation: it takes multiple nodes as upstream, the first value of all nodes is placed in a tuple, and the second value of all nodes is placed in a tuple... Analogously, the use of these tuples as the value is downstream. It's like a zipper with one buckled:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode value:@1];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode value:@2];
EZRNode<EZTuple2<NSNumber *, NSNumber *> *> *nodeC = [nodeA zip:nodeB];

[[nodeC listenedBy:self] withBlock:^(EZTuple2<NSNumber *, NSNumber *> *tuple) {
   NSLog(@"%@", tuple);
}];
nodeA.value = @3;
nodeA.value = @4;
nodeB.value = @5;
nodeA.value = @6;
nodeB.value = @7;
/* prints as follows:
Received <EZTuple2: 0x60800002b140> (
First = 1;
Second = 2;
Last = 2;
)
Received <EZTuple2: 0x60800002ac40> (
First = 3;
Second = 5;
Last = 5;
)
Received <EZTuple2: 0x600000231ee0> (
First = 4;
Second = 7;
Last = 7;
)
  */
```

The process is as follows:

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

## Branch

Branch transformation is exactly the opposite of combined transformation. It is usually an upstream node that separates different downstream nodes with specific rules. The following is the full branch transformation form.

### switch-case-default

A switch-case-default transformation is an operation that substitutes each upstream value with a given block, finds a unique identifier, and separates these identifiers. We give an example of a separate script:

```objective-c
EZRMutableNode<NSString *> *node = [EZRMutableNode new];
EZRNode<EZRSwitchedNodeTuple<NSString *> *> *nodes = [node switch:^id<NSCopying> _Nonnull(NSString * _Nullable next) {
  NSArray<NSString *> *components = [next componentsSeparatedByString:@"："];
  return components.count > 1 ? components.firstObject: nil;
}];
EZRNode<NSString *> *liLeiSaid = [nodes case:@"Li Lei"];
EZRNode<NSString *> *hanMeimeiSaid = [nodes case:@"Han Meimei"];
EZRNode<NSString *> *aside = [nodes default];
[[liLeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"Li Lei received a speech: %@", next);
}];
[[hanMeimeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"Han Meimei received a speech: %@", next);
}];
[[aside listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"The narration received a speech: %@", next);
}];
node.value = @"In a quiet afternoon";
node.value = @"Li Lei: Hello everybody, I'm Li Lei.";
node.value = @"Han Meimei: Hello everyone, my name is Han Meimei.";
node.value = @"Li Lei: Hello, Han Meimei.";
node.value = @"Han Meimei: Hello Li Lei.";
node.value = @"So they were happy together...";
/* prints as follows:
The narration received a speech: In a quiet afternoon
Li Lei received a speech: Li Lei: Hello everybody, I'm Li Lei.
Han Meimei received a speech: Han Meimei: Hello everyone, my name is Han Meimei.
Li Lei received a speech: Li Lei: Hello, Han Meimei.
Han Meimei received a speech: Han Meimei: Hello Li Lei.
The narration received a speech: So they were happy together...
 */
```

We noticed, "Li Lei received a speech: Li Lei: Hello everybody, I'm Li Lei." All the values in this branch also contain the "Li Lei" part, which is obviously unnecessary, so we may need In the process of splitting modify the original content, switchMap-case-default can be a good solution:

```objective-c
EZRMutableNode<NSString *> *node = [EZRMutableNode new];
// Just change here
EZRNode<EZRSwitchedNodeTuple<id> *> *nodes = [node switchMap:^EZTuple2<id<NSCopying>,id> * _Nonnull(NSString * _Nullable next) {
  NSArray<NSString *> *components = [next componentsSeparatedByString:@"："];
  if (components.count > 1) {
    NSString *actorLines = [next substringFromIndex:components.firstObject.length + 1];
    return EZTuple(components.firstObject, actorLines);
  } else {
    return EZTuple(nil, next);
  }
}];

EZRNode<NSString *> *liLeiSaid = [nodes case:@"Li Lei"];
EZRNode<NSString *> *hanMeimeiSaid = [nodes case:@"Han Meimei"];
EZRNode<NSString *> *aside = [nodes default];
[[liLeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"Li Lei received a speech: %@", next);
}];
[[hanMeimeiSaid listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"Han Meimei received a speech: %@", next);
}];
[[aside listenedBy:self] withBlock:^(NSString *next) {
  NSLog(@"The narration received a speech: %@", next);
}];
node.value = @"In a quiet afternoon";
node.value = @"Li Lei: Hello everybody, I'm Li Lei.";
node.value = @"Han Meimei: Hello everyone, my name is Han Meimei.";
node.value = @"Li Lei: Hello, Han Meimei.";
node.value = @"Han Meimei: Hello Li Lei.";
node.value = @"So they were happy together...";
/* prints as follows:
The narration received a speech: In a quiet afternoon
Li Lei received a speech: Hello everybody, I'm Li Lei.
Han Meimei received a speech: Hello everyone, my name is Han Meimei.
Li Lei received a speech: Hello, Han Meimei.
Han Meimei received a speech: Hello Li Lei.
The narration received a speech: So they were happy together...
 */
```

### if-then-else

Sometimes, you may only want to distinguish whether or not you don't need too many branches. If-then-else happens to meet the need:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
[[[node if:^BOOL(NSNumber *next) {
  return next.integerValue > 0;
}] then:^(EZRNode *node) {
  [[node listenedBy:self] withBlock:^(NSNumber *next) {
    NSLog(@"Eligible: %@", next);
  }];
}] else:^(EZRNode *node) {
  [[node listenedBy:self] withBlock:^(NSNumber *next) {
    NSLog(@"Not Eligible: %@", next);
  }];
}];
node.value = @1;
node.value = @-1;
node.value = @2;
node.value = @0;
node.value = @-3;
/* prints as follows:
Eligible: 1
Not Eligible: -1
Eligible: 2
Not Eligible: 0
Not Eligible: -3
 */
```

If you want to directly get a yes or no two branch nodes, simply use the return value `EZRIFResult` of if:

```objective-c
EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
EZRIFResult *result = [node if:^BOOL(NSNumber *next) {
  return next.integerValue > 0;
}];
EZRNode<NSNumber *> *positiveNode = result.thenNode;
[[positiveNode listenedBy:self] withBlock:^(NSNumber *next) {
  NSLog(@"The positive number is %@", next);
}];
node.value = @1;
node.value = @-1;
node.value = @2;
node.value = @0;
node.value = @-3;
/* prints as follows:
The positive number is 1
The positive number is 2
 */
```

## Sync

EasyReact allows ring connections, and ring connections allow multiple nodes to synchronize. The following describes the operation of synchronization.

### syncwith

For the synchronization of two nodes, `syncWith` can quickly help us establish a synchronous connection of two nodes:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode new];
id<EZRCancelable> cancelable = [nodeA syncWith:nodeB];      // <- cancelable cancels the synchronization of two nodes
nodeA.value = @1;
nodeB.value;                                                // <- @1
nodeB.value = @2;
nodeA.value;                                                // <- @2
[cancelable cancel];
nodeA.value = @3;
nodeB.value;                                                // <- @2
```

In addition to the complete synchronization of the two nodes, we can also add a positive and negative transformation to the synchronization:

```objective-c
EZRMutableNode<NSNumber *> *nodeA = [EZRMutableNode new];
EZRMutableNode<NSNumber *> *nodeB = [EZRMutableNode new];
id<EZRCancelable> cancelable = [nodeA syncWith:nodeB transform:^id _Nonnull(NSNumber * _Nonnull source) {
  return @(source.integerValue / 2);                        // How nodeA changes every time when nodeB changes
} revert:^NSNumber * _Nonnull(NSNumber *  _Nonnull target) {
  return @(target.integerValue * 2);                        // How nodeB changes every time when nodeA changes
}];
nodeA.value = @1;
nodeB.value;                                                // <- @2
nodeB.value = @4;
nodeA.value;                                                // <- @2
```

### Manual Sync

Sometimes we may need more than one object to synchronize. For example, if 3 objects want to synchronize, it is OK to use `syncWith` twice, but it will create 4 transforms:

```plaintext
                nodeA
                 ↑ |
                 | ↓
      nodeC----→nodeB
        ↑         |
        └---------┘
```

Creating 3 transformations is the best:

```plaintext
                nodeA
              ↗   |
            ╱     |
          ╱       |
        /         ↓
      nodeC←----nodeB
```

At this point you need to manually create a few synchronized edges:

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

But **Do not forget to manually disconnect**, otherwise it will cause the node to fail to release.

## High-order Transformation

High-order always gives people a very complex feeling, but mastering it in practical use is of great benefit. A high-order array refers to an array in which each element in the array is also an array. Therefore, a high-order node is a node that refers to the value of the node. ʻEZRNode<EZRNode *>` is one such node. The following describes the higher-order transformation form.

### flatten

The flat transformation is a transformation of `EZRNode<EZRNode<T> *>` to `EZRNode<T>`, which always connects the downstream node to the value of the upstream node, for example:

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
flattenedNode.value;                                                          // <- @2，no longer affected by node A
highOrderNode.value = nodeC;
nodeC.value = @4;
flattenedNode.value;                                                          // <- @4
```

### flattenmap

The flattenmap transformation is equivalent to a series of operations. It first maps the nodes, and the results of the mapping are all nodes. Finally, the flat mapping transformation is performed once more. Why do we need a flat mapping transformation instead of a simple mapping transformation? This is because the mapping transformations must be one-to-one correspondence. Assume that the upstream node has 10 value changes, and the downstream node after the mapping transformation must also have 10 value changes. But what if I have 8 or 12 values that I want to transform? It needs a flat mapping transformation; there are mapping transformations that must all be transformed immediately, and if we need result-delayed transformations, we also need a flat mapping transformation. For example, the following example:

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
  NSLog(@"FlattenMappedNode received %@", next);
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
/* prints as follows:
FlattenMappedNode received 2
FlattenMappedNode received 1
FlattenMappedNode received 7
FlattenMappedNode received 2
FlattenMappedNode received 7
FlattenMappedNode received 2
FlattenMappedNode received 5
FlattenMappedNode received 9
 */
```

## Graph Traversal

Whether you need to debug or modify nodes and edges, you may need to traverse the existing directed circular graph. Here are some methods of graph traversal.

### Simple Access

Nodes and Edges There are many properties and methods for traversal. The from and to attributes of edges are examples, and the nodes are more:

| Type              | Name                         | Role                                               |
| ----------------- | ---------------------------- | -------------------------------------------------- |
| attribute         | upstreamNodes                | all upstream nodes of the current node             |
| attribute         | downstreamNodes              | all downstream nodes of the current node           |
| attribute         | upstreamTransforms           | all upstream transforms of the current node        |
| attribute         | downstreamTransforms         | all downstream transformations of the current node |
| method            | upstreamTransformsFromNode:  | all transforms upstream to another node            |
| method            | downstreamTransformsToNode:  | downstream to all other transforms                 |

In addition, you can get a long piece of text through the node's `graph` method during debugging. It will create a dot-formatted string of all related nodes and edges. You can also use the graphviz tool. Make it a picture.

Need to install graphviz command line tool under Mac OS

```shell
brew install graphviz
```

Generate a picture

```shell
circo -Tpdf test.dot -o test.pdf && open test.pdf
```

All nodes and edges have a name attribute. Setting the name attribute makes it easier to find problems during the debugging process.

### Accessor Mode

For more complexity to access a node and avoid recursion, you can use the accessor pattern to implement the EZRNodeVisitor protocol to write its own logic. Details and examples can be found in the implementation of [EasyReact/Core/EZRNode+Graph.m.](https://github.com/meituan/EasyReact/blob/master/EasyReact/Classes/Core/EZRNode%2BGraph.m)
