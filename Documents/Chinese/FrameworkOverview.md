
# 框架概述

本文档描述了 EasyReact 框架的不同组件的高层描述，并试图解释它们如何协同工作。你可以把本文档作为一个学习起点，并找到更多相关的具体文档。

要寻找例子或者深入理解如何使用 EasyReact，请参考 [README](../../README-Chinese.md) 和 [BasicOperators](./BasicOperators.md)。

## 目录

<!-- TOC -->

- [理论基础](#理论基础)
- [节点](#节点)
- [监听者](#监听者)
- [边](#边)
- [接收者](#接收者)
- [变换](#变换)
- [上游与下游](#上游与下游)
- [监听边](#监听边)
- [连接和数据流动](#连接和数据流动)

<!-- /TOC -->

## 理论基础

本框架的理论基础是图论中的有向有环图。由**节点**和**边**构成了数据的连接，边的方向表达了流动方向。

## 节点

我们用 EZRNode\<T\> 类来表示一个节点。所有 T 类的实例都可以被包装到一个节点中，节点中含有一个`T value`属性，这个值属性用于存放实例。

值得注意的是，节点值也可能是 nil，这使得我们需要区分一个节点到底是存放了 nil 值还是什么都没有存放。所以当我们创建一个新的节点而不给它值时，此节点的值为 EZREmpty 类型的`EZREmpty.empty`，它用来表示值是“空”的这个概念。

我们可以随时通过`- (id)value`这个方法来获得节点当前时刻的值，也可以用点语法`someNode.value`来表示。更多的时候，我们将节点与节点间连接起来，这样一个节点的值就会随着另一个节点的值改变而改变，这种依赖的形式也就是响应式编程的基本思想。

EZRNode\<T\> 类的实例是不可以主动触发变动的，如果想得到一个随意改变值的节点，我们需要 EZRNode\<T\> 的子类 EZRMutableNode\<T\>。 EZRMutableNode\<T\> 有`- (void)setValue:(nullable T)newValue`这个方法用来改变值，也可以用点语法`someNode.value = newValue`来表示。另外我们也可以给数据传递附加一个上下文对象，使用`- (void)setValue:(nullable T)value context:(nullable id)context`方法。整个传递的过程中这个上下文对象会传递给每个节点和边。

## 监听者

监听者在本框架中并没有特定的类型，任意对象都可以作为监听者。监听者是一种特殊的节点，它在整个有向图中是没有下游边的端点。

监听者代表了关心数据变化的主体，也用来维持整个响应链条的内存管理。当一个监听者被销毁的时候，会向上检查所有没有监听者的节点并将之释放（引用计数减一，如果一个节点被一个以上对象强持有则不会销毁）。

## 边

我们用 EZREdge 协议来表示有向边。每个`id<EZREdge>`都有 from 和 to 两个属性来指定来源与去向。from 到 to 的方向也就是数据的流动方向。

## 接收者

我们用 EZRNextReceiver 协议来表示接收者，它表示可以不断接收新值的对象。EZRNextReceiver 协议有个非常重要的`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法，调用这个方法就可以向这个接收者发送新的值。

## 变换

EZREdge 协议有一个子协议 EZRTransformEdge，它表示数据流动中的变换，同时它也满足 EZRNextReceiver 协议。EZRTransformEdge 协议的 from 和 to 属性一定指向一个节点。

每当来源节点执行`setValue:`或者`setValue:context:`的时候，只要值不是空值（`EZREmpty.empty`），就会调用所有的相连的下游边（from 指向该节点的边）的`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法。

EZRTransform 是 EZRTransformEdge 协议的一个默认实现类，它帮助我们实现了 from 和 to 属性的 setter 和 getter，并且实现了 EZRNextReceiver 协议的`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法。它的变换规则是将每一个 from 节点通过`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法传过来的值和上下文对象都原封不动的传递给 to 节点。

想要定制自己的边只需要继承 EZRTransform 类并覆盖`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法就可以了。如果需要向 to 节点传递，请务必使用父类的`next:from:context`方法，将入参 value 改变为想要传递的值，同时保持入参 from 和 context 不变。详细的内容可以参考源代码中 EasyReact/Classes/Core/NodeTransforms 中实现的默认边。

## 上游与下游

数据的流动是有方向的。因此数据的提供者叫做上游，数据的需求者叫做下游。上游和下游是一个逻辑上的概念。

为了方便遍历和深度、广度搜索，每个节点都拥有`upstreamNodes`、`downstreamNodes`、`upstreamTransforms`、`downstreamTransforms`等聚合属性用来获得上下游的边和节点。

另外，一个节点和另一个节点是可能存在多条边的，所以我们可以通过`- (NSArray<id<EZRTransformEdge>> *)upstreamTransformsFromNode:(EZRNode *)from`方法找到连接到 from 节点的所有的上游变换。相应的，`- (NSArray<id<EZRTransformEdge>> *)downstreamTransformsToNode:(EZRNode *)to`方法找到连接到 to 节点的所有的下游变换。

## 监听边

EZREdge 有另外一个子协议 EZRListenEdge，它表示数据流动中的监听行为，同时它也满足 EZRNextReceiver 协议。EZRListenEdge 协议的 from 属性一定指向一个节点，它的 to 属性指向一个 [监听者](#监听者)。

EZRListen 是 EZRListenEdge 协议的一个默认实现类，它帮助我们实现了 from 和 to 属性的 setter 和 getter，并且实现了 EZRNextReceiver 协议的`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法。默认的`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`方法并没有做什么，你可以子类化并且覆盖这个方法。

EZRBlockListen 和 EZRDeliveredListen 是 EZRListen 类的两个子类，可以方便的指定 block 和 GCD 的 queue 来完成监听，通常情况下可以满足我们的需要。

## 连接和数据流动

响应式编程的过程就是描述节点与节点、节点与监听者的关系，最终构成响应图的过程。

本框架中所有的节点关系都是可以后期改变的，所以可以随时通过遍历和修改的方式来改变现有的响应图。

一种特殊情况是节点环。当节点相互成为下游的时候便形成了节点环，例如 a --> b --> c --> a 形成了一个 a, b, c 的三角形节点环。节点环的数据流动是不会循环的，我们通过传递方法`- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context`的参数`senderList`来避免循环。所以当 b 改变的时候，c 会随之改变，然后再改变 a，a 在数据传递的时候发现 senderList 中已经包含了 b 所以不会继续向 b 传递数据，从而终止了循环。
