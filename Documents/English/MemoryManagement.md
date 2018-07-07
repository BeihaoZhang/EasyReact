# Memory Management

For a graph-theory-based framework, nodes and edges are the smallest components. In practice, these components constitute various directed graphs. For example, with a cycline graph, its data flow is a ring. If the hold relationship between components is not well handled, there may be a memory problem. EasyReact's memory management logic is very simple and very sophisticated. This allows the framework user to use it without having to worry about too much detail, without having to worry about the memory aspects of the framework.

## Table of Contents

<!-- TOC -->

- [Middle Node](#middle-node)
- [Life Cycle](#life-cycle)
- [API Usage Analysis](#api-usage-analysis)
- [About self](#about-self)
- [About Node Cycle](#about-node-cycle)

<!-- /TOC -->

## Middle Node

Nodes include fork, map, filter, skip, take, ignore, select, and many other operations. For most of the node operations, the new node is returned and the source node and the new node are connected through some kind of transformation. Since the return is also a node, this allows us to use chained methods instead of saving the nodes returned by each operation with variables. For example, we can first map and then filter on someNode, and usually we don't care about the node returned by map, because this is an intermediate node that is connected to the node created by the final filter operation.

## Life Cycle

In this framework, nodes, transforms, listened edges, and listeners form a directed graph structure that maintains the data response relationship. Because this framework is an object-oriented, responsive framework, nodes, transforms, listeners, and listeners are all objects. Regardless of whether intermediate nodes are saved or not, how to maintain the life cycle of these objects to keep the entire response relationship stable is an important issue.

In this framework, the rules for holding nodes, transforms, listening edges, and listeners are as follows:

- A listener holds all its upstream listening edges;
- An edge of from holds a node, and to weak references a downstream node or listener;
- A node strongly holds all its upstream transforms, weakly referencing all its downstream transforms and downstream listening edges.

That is, in a response chain, consumers who always have data hold data providers. When the data no longer has a consumer, the data provider does not need to exist.

## API Usage Analysis

For an API interface that uses EZRNode\<T\>, an EZRNode node is usually exposed.
There are two classic scenarios for users of this API.

1. Transform a node to get a derived node, as shown in the following example:

```objective-c
ERNode<NSNumber *> *node = [ERNode value:@1];

ERNode<NSNumber *> *filteredNode = [[node map:^id _Nullable(NSNumber * _Nullable next) {
    return @([next.integerValue * 2]);
}] filter:^BOOL(NSNumber * _Nullable next) {
    return next.integerValue > 0;
}];
```

1. Listen to the value of a node, as shown in the following example:

```objective-c
ERNode<NSNumber *> *node = [ERNode value:@1];

NSObject *listener = [NSObject new];

[[node listenedBy:listener] withBlock:^(id next) {}];
```

It should be noted that in the example of obtaining a derived node, a new derived node is obtained for each transformation operation of the node. So there will actually be an intermediate node.

```plaintext
Node ==MapTransform==> MappedNode ==FilterTransform==> FilteredNode
```

There are 3 node objects and 2 transformation objects in the above node-derived relationship. Its strong citation relationship is just the opposite, as follows:

```plaintext
Node <-- MapTransform <-- MappedNode <-- FilterTransform <-- FilteredNode
```

So once the FilteredNode is destroyed, other objects are automatically released (whether or not it is destroyed depends on whether there are other objects for strong references to it).

In the listened node example, nodes and listeners connect by listening for edges.

```plaintext
Node ==BlockListenEdge==> Listener
```

There are 2 node objects and 1 listening edge object in the above listening relationship. Its strong citation relationship is just the opposite, as follows:

```plaintext
Node <-- BlockListenEdge <-- Listener
```

So once the Listener is destroyed, other objects are automatically released (whether it is destroyed or not, depending on whether there are other objects that strongly reference it).

## About self

It should be noted that usually we will use self in the method of listening. As mentioned above, self already holds the listening edge. If the listening edge captures self, a retain cycle will occur, causing a memory leak. E.g:

```objective-c
[[someNode listenedBy:self] withBlock:^(id next){
    [self doSomething];
}];

// someNode <-- BlockListenEdge <-- self
//                    |               ↑
//                    └---------------┘
```

For this purpose we provide `@erz_weakify(...)` and `@erz_strongify(...)` to solve the problem of retain cycle.

The best practices are as follows:

```objective-c
@ezr_weakify(self)
[[someNode listenedBy:self] withBlock:^(id next){
    @ezr_strongify(self)
    [self doSomething];
}];

// Other objects also need
@ezr_weakify(someObject)
[[someNode listenedBy:someObject] withBlock:^(id next){
    @ezr_strongify(someObject)
    [someObject doSomething];
}];
```

## About Node Cycle

In the framework design, a strong reference to the upstream link has been processed, so the node cycle will generate a retain cycle, and if it is necessary to remember the necessary moments to take the initiative to break the operation, such as the following example:

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

// The strong reference relationship is as follows:
// nodeA <-- transformAtoB <-- nodeB <-- transformBtoC <-- nodeC
//   |                                                       ↑
//   └-------------------->transformCtoA---------------------┘
```

In this way, all 3 transforms and 3 nodes will not be destroyed, so **Please remember to remove any arbitrary edge or node** when necessary, the method is as follows:

```objective-c
// Remove edge
transformAtoB.from = nil;
// or remove node
[nodeA removeDownstreamNode:nodeB];
```

Normally we will synchronize two nodes instead of more nodes. We provide `- (id<EZRCancelable>)syncWith:(EZRNode<T> *)otherNode` and `- (id<EZRCancelable>)syncWith:(EZRNode *)otherNode transform:(id(^)(T source))transform revert:(T(^)(id target))revert` these two convenient methods, they all provide `id<EZRCancelable>` this Objects, through the object's `- (void)cancel` method, we can quickly break the ring of these two nodes, an example is as follows:

```objective-c
EZRNode<NSNumber *> *nodeA = [EZRNode new];
EZRNode<NSString *> *nodeB = [EZRNode new];
id<EZRCancelable> *cancelable = [nodeA syncWith:nodeB transform:^NSString *(NSNumber *source) {
    return source.stringValue;
} revert:^NSNumber *(NSString *target) {
    return @(source.integerValue);
}];

// If need to remove it
[cancelable cancel];
```
