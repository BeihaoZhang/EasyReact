# Framework Overview

This document describes high-level descriptions of the different components of the EasyReact framework and attempts to explain how they work together. You can use this document as a starting point for learning and find more relevant specific documents.

For examples or an in-depth understanding of how to use EasyReact, refer to [README](../../README.md) and [BasicOperators](./BasicOperators.md).

## Table of Contents

<!-- TOC -->

- [Theoretical Basis](#theoretical-basis)
- [Node](#node)
- [Listener](#listener)
- [Edge](#edge)
- [Recipient](#recipient)
- [Transform](#transform)
- [Upstream and Downstream](#upstream-and-downstream)
- [Listening Edge](#listening-edge)
- [Connection and Data Flow](#connection-and-data-flow)

<!-- /TOC -->

## Theoretical Basis

The theoretical basis of this framework is the directed and ring diagram in graph theory. The connection of data is formed by **node** and **edge**, and the direction of the edge expresses the flow direction.

## Node

We use the EZRNode\<T\> class to represent a node. All instances of the T class can be wrapped into a node. The node contains a `T value` attribute. This value attribute is used to store the instance.

It's worth noting that the node value may also be nil, which makes it necessary to distinguish whether a node holds nil or nothing. So when we create a new node without giving it a value, the value of this node is `EZREmpty.empty` of type EZREmpty, which is used to indicate the concept of the value being 'empty'.

We can use the `- (id)value` method at any time to get the node's current value, or it can be represented by the dot syntax `someNode.value`. More often, we connect nodes to nodes so that the value of one node changes as the value of another node changes. The form of this dependency is the basic idea of reactive programming.

An instance of the EZRNode\<T\> class cannot actively trigger changes. If you want to get a node that changes its value arbitrarily, we need a subclass of EZRNode\<T\> EZRMutableNode\<T\>. EZRMutableNode\<T\> has `- (void)setValue:(nullable T)newValue` this method to change the value. It can also be represented by the dot syntax `someNode.value = newValue`. In addition, we can also attach a context object to the data transfer, using the `- (void)setValue: (nullable T)value context: (nullable id)context` method. This context object is passed to each node and edge throughout the pass.

## Listener

The listener does not have a specific type in this framework, and any object can act as a listener. A listener is a special kind of node that has no downstream edge in the entire directed graph.

The listener represents the main body concerned with data changes and is also used to maintain the memory management of the entire response chain. When a listener is destroyed, all nodes with no listener are checked upwards and released (the reference count is decremented by one. If a node is strongly held by more than one object it will not be destroyed).

## Edge

We use the EZREdge protocol to represent directed edges. Each `id<EZREdge>` has two attributes from and to specify the source and destination. The direction from to to is also the direction of data flow.

## Recipient

We represent the receiver with the EZRNextReceiver protocol, which represents an object that can continuously receive new values. The EZRNextReceiver protocol has a very important `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` method. Call this method to send new values to this receiver.

## Transform

The EZREdge protocol has a sub-protocol called EZRTransformEdge, which represents the transformation in data flow and it also satisfies the EZRNextReceiver protocol. The from and to attributes of the EZRTransformEdge protocol must point to a node.

Whenever the source node executes `setValue:` or `setValue:context:`, as long as the value is not null (`EZREmpty.empty`), all connected downstream edges are called (from points to the node's edge) `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` method.

EZRTransform is a default implementation of the EZRTransformEdge protocol that helps us implement setters and getters for the from and to attributes, and implements the EZRNextReceiver protocol `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` method. Its transformation rule is to pass each value of the from-node to `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` methods and the context object is not pass to the to node.

To customize your own edges just inherit the EZRTransform class and override the `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` methods. If you need to pass to the to node, be sure to use the parent's `next:from:context` method to change the input parameter value to the value you want to pass, while keeping the input parameters from and context unchanged. Detailed content can refer to the default edge implemented in EasyReact/Classes/Core/NodeTransforms in the source code.

## Upstream and Downstream

The flow of data is directional. Therefore, the provider of data is called upstream, and the demander of data is called downstream. Upstream and downstream are logical concepts.

In order to facilitate traversal and depth, breadth search, each node has an aggregation attribute such as `upstreamNodes`, `downstreamNodes`, `upstreamTransforms`, `downstreamTransforms` and so on to obtain the upstream and downstream edges and nodes.

In addition, it is possible for one node and another node to have multiple edges, so we can find all upstream connections to the from node from the `- (NSArray<id<EZRTransformEdge>> *)upstreamTransformsFromNode:(EZRNode *)from` method. Transform. Correspondingly, the `-(NSArray<id<EZRTransformEdge>>*)downstreamTransformsToNode:(EZRNode*)to` method finds all downstream transforms connected to the to node.

## Listening Edge

EZREdge has another sub-protocol, EZRListenEdge, which represents the listening activity in the data flow and it also satisfies the EZRNextReceiver protocol. The from attribute of the EZRListenEdge protocol must point to a node whose to attribute points to a [listener](#Listener).

EZRListen is a default implementation of the EZRListenEdge protocol that helps us implement setters and getters for the from and to attributes and implements the EZRNextReceiver protocol `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` method. The default `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context` methods does nothing, you can subclass and override this method.

EZRBlockListen and EZRDeliveredListen are two subclasses of the EZRListen class that can easily specify the block and GCD queues to complete the listener, usually to meet our needs.

## Connection and Data Flow

The process of responsive programming is the process of describing the relationship between nodes and nodes, nodes and listeners, and ultimately the response diagram.

All the node relationships in this framework can be changed later, so the existing response graphs can be changed at any time by traversing and modifying.

A special case is the node ring. A node ring is formed when nodes become downstream. For example, a --> b --> c --> a forms a triangular cycle of a, b, c nodes. The data flow of the node cycle will not be looped. We avoid it by passing the argument `senderList` of the method `- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`. So when b changes, c will change, and then change a, a found in the senderList data transmission b will not continue to pass data to b, thus ending the loop.
