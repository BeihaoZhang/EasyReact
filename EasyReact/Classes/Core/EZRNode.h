/**
 * Beijing Sankuai Online Technology Co.,Ltd (Meituan)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// Exception name
extern NSString *EZRNodeExceptionName; 
extern NSString *EZRExceptionReason_CannotModifyEZRNode;

@protocol EZRCancelable, EZRNodeTransformProtocol;
@class EZRListenContext<T>;

/**
 EZRNode 是整个EasyReact 中最关键的一个类，代表一个节点，这个节点拥有一个值，并且可以在后期变化这个值。当值发生变化的时候，监听这个节点的监听者们就可以拿到最新值，并且节点与节点之间可以通过变换 (EZRTransformProtocol) 来连接，当一个节点值变化的时候，其他与之相连的节点会根据变换来改变自己的值。
 */
@interface EZRNode<__covariant T: id> : NSObject

/**
 节点的名字，方便调试和生成节点的拓扑图
 */
@property (nonatomic, readwrite, strong, nullable) NSString *name;

/**
 节点的值，目前只支持强引用。
 节点值的获取是线程安全的。
 */
@property (atomic, readonly, strong, nullable) T value;

/**
 节点的状态,代表节点当前是否是可修改的
 */
@property (atomic, readonly, assign, getter=isMutable) BOOL mutable;

/**
 上游节点
 */
@property (atomic, readonly, copy) NSArray<EZRNode *> *upstreamNodes;

/**
 下游节点
 */
@property (atomic, readonly, copy) NSArray<EZRNode *> *downstreamNodes;

/**
 上游变换
 */
@property (atomic, readonly, copy) NSArray<id<EZRNodeTransformProtocol>> *upstreamTransforms;

/**
 下游变换
 */
@property (atomic, readonly, copy) NSArray<id<EZRNodeTransformProtocol>> *downstreamTransforms;

/**
 是否拥有上游节点
 */
@property (atomic, readonly, assign) BOOL hasUpstreamNode;

/**
 是否拥有下游节点
 */
@property (atomic, readonly, assign) BOOL hasDownstreamNode;

/**
 是否有人监听
 */
@property (atomic, readonly, assign) BOOL hasListener;

/**
 是否是空值，空值是 EZREmpty.empty 而不是 nil。空值的特点是空值不会触发监听者，也不会让下游节点产生变化。
 */
@property (atomic, readonly, assign, getter=isEmpty) BOOL empty;

/**
 指定初始化器，用于初始化一个节点。这时值为 EZREmtpy.empty

 @return 新的节点实例
 */
- (instancetype)init;
/**
 初始化一个节点并给定初始值

 @param value 初始值
 @return 新的节点实例
 */
- (instancetype)initWithValue:(nullable T)value NS_DESIGNATED_INITIALIZER;

/**
 生成一个新的节点并给定初始值

 @param value 初始值
 @return 新的节点实例
 */
+ (instancetype)value:(nullable T)value;

/**
 给新的节点的名字赋值

 @param name 名字
 @return 节点实例
 */
- (instancetype)named:(NSString *)name;

/**
 给新的节点的名字赋值

 @param format 格式化字符串
 @param ... 可变参数
 @return 节点实例
 */
- (instancetype)namedWithFormat:(NSString *)format, ...;

/**
 连接到上游节点，并且与上游节点的值用 transform 来变换。

 @param node 想要连接的上游节点
 @param transform 与上游节点值的变换
 @return 可以取消连接的 Cancelable 对象
 */
- (id<EZRCancelable>)linkTo:(EZRNode *)node transform:(id<EZRNodeTransformProtocol>)transform;

/**
 连接到上游节点，并且保持与上游节点值相同。

 @param node 想要连接的上游节点
 @return 可以取消连接的 Cancelable 对象
 */
- (id<EZRCancelable>)linkTo:(EZRNode *)node;

/**
 从上游节点查找与当前节点相连接的边 如果上游节点和自己不存在关系则查找出来的数组内容为空

 @param to 下游节点
 @return 下游边的数组
 */
- (NSArray<id<EZRNodeTransformProtocol>> *)downstreamTransformsToNode:(EZRNode *)to;

/**
 从下游节点查找与当前节点相连接的边 如果上游节点和自己不存在关系则查找出来的数组内容为空

 @param from 上游节点
 @return 上游边的数组
 */
- (NSArray<id<EZRNodeTransformProtocol>> *)upstreamTransformsFromNode:(EZRNode *)from;
/**
 移除下游节点，与此节点连接的变换也会一并移除。

 @param downstream 要移除的节点
 */
- (void)removeDownstreamNode:(EZRNode *)downstream;

/**
 移除所有下游节点
 */
- (void)removeDownstreamNodes;

/**
 移除上游节点，与此节点连接的变换也会一并移除。
 
 @param upstream 要移除的节点
 */
- (void)removeUpstreamNode:(EZRNode *)upstream;
/**
 移除所有上游节点
 */
- (void)removeUpstreamNodes;

@end

NS_ASSUME_NONNULL_END
