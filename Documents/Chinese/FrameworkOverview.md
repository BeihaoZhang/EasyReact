# Framework Overview

本文档描述了EasyReact框架的不同组件的高层描述，并试图解释它们如何协同工作。也就是说，你可以把本文档作为一个学习起点，并找到更多相关的具体文档。

要寻找例子或者深入理解如何使用EasyReact，请参考README或者Design Guidelines。

## 理论基础

本框架的理论基础是图论中的有向图。由“点”和“边”构成了数据的连接和流动关系。即，一个点可以有多条有向边与之连接，而一条有向边则可以连接任意两个点。

## Node

一个Node, 被`EZRNode`类型表示。Node对应了有向图里的"点"。任何对象都可以包装为一个Node, 它有一个`value`属性，用于存放对象。

值得注意的是，`nil`也是可以被Node处理的。当创建一个新的node而不给它任何value时，此Node的value为`EZREmpty`类型，用来表示数据是"空"的这个概念。

从静态的角度看，Node本身存储了value，可以通过访问`value`方法来获得一个即时值。

从动态的角度来看，Node是对变化后的未来的值的一种封装。如一个Node B，它的数据来自Node A，那么Node B就是未来Node A传递过来的值的一种封装。重要的是，依赖这种封装，我们便可以用Node对象先构建连接关系和处理流程，而不必等先得到值再进行命令式的处理，这也是响应式编程的基本思想。


## Listener

一个Listener，表示一个监听者。在本框架中并没有特定的类型，任意对象都可以作为Listener。Listener可以看作是一种特殊的"点"，如同Node一样，同样可以构成有向图。和Node不同的是，Listener在整个有向图中为端点，即它没有下游，Listener接收的值也不需要向下传递。

## Transform

一个Transform, 被`id<EZRTransformProtocol>`类型表示。Transform的含义是"变换"，代表了一种数据加工。同时，可以通过Transform的`from`和`to`属性指定数据的来源和去向，从而构建连接关系。从构建连接关系的功能上来看，Transform和有向图的边的概念是一致的。

举个例子，如`EZRMapTransform`，它是`EZRNodeTransform`的子类，这种边可以让数据先经过map操作产生新的数据，再将新的数据向下游传递。

## Upstream & Downstream

数据的流动是有方向的。我们把数据的提供者叫做Upstream（上游），而把数据的需求者叫做DownStream（下游）。本框架中，Upstream和Downstream并没有对应的实体类，这只是一个逻辑上的概念。但是框架中的Node和Transform，却有"上游"和"下游"的区别。分为4种情况：

1. ### Upstream Node

如果点B的Upstream Node是点A，则表示点B和点A通过Transform产生了连接关系，数据流动方向是：从点A经过Transform传递到点B。

2. ### Downstream Node

如果点B的Downstream Node是点C，则表示点C和点B通过Transform产生了连接关系，数据流动方向是：从点B经过Transform传递到点C。

3. ### Upstream Transform

如果点B的Upstream Transform是边U，则表示点B通过边U和某个点X产生了连接关系，数据流动方向是：从点X经过边U传递到点B。

4. ### Downstream Transform

如果点B的Downstream Transform是边D，则表示点B通过边D和某个点Y产生了连接关系，数据流动方向是：从点B经过边D传递到点Y。

## 连接和传递

通过Node、Listener和Transform构建连接关系之后，就构成了一条响应链。

连接规则是：

- Node可以有Upstream Transform, 这个上游边的一端连接到Node本身，而另一端是一个Node；
- Node可以有Downstream Transform，这个下游边的一端连接到Node本身，而另一端是一个Node或Listener;
- Node的Upstream Transform的另一端所连接的Node，叫做这个Node的Upstream Node, 即“上游点”；
- Node的Downstream Transform的另一端所连接的Node，叫做这个Node的Downstream Node, 即“下游点”；如果这个Node的Downstream Transform的另一端所连接的不是Node而是其他类型的对象，则这个对象叫做Node的Listener;
- Node和Node之间，以及Node和Listener之间并不具备连接能力，本质上还是通过Transform将它们连接。

数据传递规则是：

1. 数据从Node出发，流向它的全部的Downstream Transform。
3. 每一个Downstream Transform给数据进行变换后，继续传递给它所连接的Node或Listener。当Transform另一端没有连接到任何对象，则数据流动结束。
4. 当数据流动到了Listener，即数据流动到了端点，数据流动结束。
5. 当数据流动到了Node，并且Node存在Downstream Transform，回到步骤2，否则数据流动结束。

