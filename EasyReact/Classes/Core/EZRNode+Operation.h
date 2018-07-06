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

#import <EasyReact/EZRNode.h>
#import <EasyReact/EZRMetaMacros.h>
#import <EasyTuple/EasyTuple.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const EZRExceptionReason_SyncTransformBlockAndRevertNotInverseOperations;
FOUNDATION_EXTERN NSString * const EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode;
FOUNDATION_EXTERN NSString * const EZRExceptionReason_MapEachNextValueNotTuple;
FOUNDATION_EXTERN NSString * const EZRExceptionReason_CasedNodeMustGenerateBySwitchOrSwitchMapOperation;

@interface EZRNode<T: id> (Operation)

#pragma mark For single upstream

/**
 此操作作用为复制。fork操作会返回新的节点, 此节点会作为原节点的下游。

 @return 新的node, value和原节点保持一致。
 */
- (EZRNode<T> *)fork;

/**
 此操作作用为映射。map操作会返回新的节点，此节点会作为原节点的下游。原节点每一次变化时调用block, 通过block处理每一次变化时的值并得到一个新的值作为这个新节点的value。

 @param block map处理block。
 @return 新的node，value为block的返回值。
 */
- (EZRNode *)map:(id _Nullable (^)(T _Nullable next))block;

/**
 此操作作用为过滤。filter操作会返回新的节点, 此节点会作为原节点的下游。原节点每一次变化时调用block，通过block处理每一次变化时的值并返回一个BOOL类型来决定新的节点是否接收这个值。如果此值被接收，则作为新节点的值。

 @param block filter处理的block。
 @return 新的node, 当block返回YES时，value和原节点值相同，否则value不变。
 */
- (EZRNode<T> *)filter:(BOOL (^)(T _Nullable next))block;

/**
 此操作作用为跳过前N次的值。skip操作会返回新的节点, 此节点会作为原节点的下游。

 @param number 跳过(忽略)的数量
 @return 新的node, 当原节点的值变化超过`number`次之后，新的node的值和原节点的值保持一致。
 */
- (EZRNode<T> *)skip:(NSUInteger)number;

/**
 此操作作用为取前N次的值。take操作会返回新的节点, 此节点会作为原节点的下游。

 @param number 取值的数量
 @return 新的node, 当原节点的值变化数量在`number`次之内，新的node的值和原节点的值保持一致。
 */
- (EZRNode<T> *)take:(NSUInteger)number;

/**
 此操作作用为忽略指定的value。ignore操作会返回新的节点, 此节点会作为原节点的下游。

 @param ignoreValue 要忽略的value
 @return 新的node, 当原节点的值为`ignoreValue`此node的值不变，否则新的node的值和原节点的值保持一致。
 */
- (EZRNode<T> *)ignore:(nullable T)ignoreValue;

/**
 此操作作用为选择指定的value。select操作会返回新的节点, 此节点会作为原节点的下游。

 @param selectedValue 要选择的value
 @return 新的node, 当原节点的值为`selectedValue`此node的和原节点的值保持一致，否则value不变。
 */
- (EZRNode<T> *)select:(nullable T)selectedValue;

/**
 此操作作用为用指定的value替换原节点传来的值。mapReplace操作会返回新的节点, 此节点会作为原节点的下游。

 @param mappedValue 指定的用于替换原值的value
 @return 新的node, 当原节点发生变化时，value为`mappedValue`。
 */
- (EZRNode<T> *)mapReplace:(nullable id)mappedValue;

/**
 此操作作用为只接收不连续重复的值。distinctUntilChanged操作会返回新的节点, 此节点会作为原节点的下游。

 @return 新的node，当原节点传来的值和此node当前值不同时，新的node的值才会发生变化。
 */
- (EZRNode<T> *)distinctUntilChanged;

/**
 此操作用于处理node本身。

 @param thenBlock 要处理的block，参数`node`为调用者本身。
 @return 原node。
 */
- (EZRNode<T> *)then:(void(NS_NOESCAPE^)(EZRNode<T> *node))thenBlock;

/**
 此操作用于在指定队列传输value。deliverOn操作会返回新的节点, 此节点会作为原节点的下游。

 @param queue 指定的队列，用于传输value。
 @return 新的node, value和原节点保持一致。
 */
- (EZRNode<T> *)deliverOn:(dispatch_queue_t)queue;

/**
 此操作用于在主队列传输value。deliverOnMainQueue操作会返回新的节点, 此节点会作为原节点的下游。

 @return 新的node, value和原节点保持一致。
 */
- (EZRNode<T> *)deliverOnMainQueue;

/**
 Sync the current value to another value.
 The other EZRNode's value will be set to the current EZRNode's value even if the current value is empty.

 @note Both current EZRNode and othEZRNode must response to -(void)setValue: method, otherwise you will receive an exception while syncing.
 @param othEZRNode The other EZRNode you want to sync.
 @return a cancelable object which is able to stop syncing.
 */
- (id<EZRCancelable>)syncWith:(EZRNode<T> *)othEZRNode;
- (id<EZRCancelable>)syncWith:(EZRNode *)othEZRNode transform:(id (^)(T source))transform revert:(T (^)(id target))revert;

/**
 此操作用于给node映射后降阶。flattenMap操作会返回新的节点, 此节点会作为原节点的下游。原节点的value经过block处理map为node后，再降阶处理。

 @param block map处理block，接收一个value，返回一个node，再用于降阶。
 @return 新的node，value为map后返回的节点的value.
 */
- (EZRNode *)flattenMap:(EZRNode * _Nullable (^)(T _Nullable next))block;


/**
 此操作用于给node降阶。flatten操作会返回新的节点, 此节点会作为原节点的下游。当原节点的value为EZRNode时，新的节点值发生变化，等于原节点的value的value。

 @return 新的node。
 */
- (EZRNode *)flatten;

/**
 Changes value if and only if the value does not change again in `interval` seconds.
 @discusstion If a value does not last for `interval` seconds, its listeners / downstreamNodes will not receive this value.
 An throttled empty value will not notify its listeners or downdstreams no matter how long it remains empty.
 The listener or downstream blocks will always be invoked in the main queue.
 If you want to dispatch those blocks to a specified queue, use `-throttle:queue:` method.
 @note It is NOT a real time mechanism, just like an NSTimer.
 @param timeInterval The time interval in seconds, MUST be greater than 0.
 @return A new EZRNode which change its value iff the value lasts for a given interval.
 */
- (EZRNode<T> *)throttleOnMainQueue:(NSTimeInterval)timeInterval;

/**
 Changes value if and only if the value does not change again in `interval` seconds.
 @discusstion If a value does not last for `interval` seconds, its listeners / downstreamNodes will not receive this value.
 An throttled empty value will not notify its listeners or downdstreams no matter how long it remains empty.
 @note It is NOT a real time mechanism, just like an NSTimer.
 @param timeInterval The time interval in seconds, MUST be greater than 0.
 @param queue The queue which listener block will be invoked in.
 @return A new EZRNode which change its value iff the value lasts for a given interval.
 */
- (EZRNode<T> *)throttle:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue;

/**
 此操作作用为在指定队列延迟传递原node的值。delay操作会返回新的节点, 此节点会作为原节点的下游。

 @param timeInterval 延迟时间，单位为秒。
 @param queue 指定的队列，用于传递value。
 @return 新的node，value和原节点保持一致。
 */
- (EZRNode<T> *)delay:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue;

/**
 此操作作用为在主队列延迟传递原node的值。delay操作会返回新的节点, 此节点会作为原节点的下游。

 @param timeInterval 延迟时间，单位为秒。
 @return 新的node，value和原节点保持一致。
 */
- (EZRNode<T> *)delayOnMainQueue:(NSTimeInterval)timeInterval ;

/**
 此操作作用为reduce node每一次变化时的值。scan操作会返回新的节点, 此节点会作为原节点的下游。每次一node变化时，调用reduceBlock, 返回一个running值，供下次变化时再次传入reduceBlock。
 
 @param startingValue 起始值。
 @param reduceBlock reduce操作的block。参数如下：
    <pre>@textblock
         running     - 上一次reduce的结果
         next        - 当前node的值
    @/textblock</pre>
 @return 新的node，value为running值。
 */
- (EZRNode *)scanWithStart:(nullable id)startingValue reduce:(id (^)(id _Nullable running, T _Nullable next))reduceBlock;

/**
 此操作作用为reduce node每一次变化时的值。scan操作会返回新的节点, 此节点会作为原节点的下游。每次一node变化时，调用reduceBlock, 返回一个running值，供下次变化时再次传入reduceBlock。

 @param startingValue 起始值。
 @param reduceBlock reduce操作的block。参数如下：
     <pre>@textblock
         running     - 上一次reduce的结果
         next        - 当前node的值
         index       - 次数
     @/textblock</pre>
 @return 新的node，value为running值。
 */
- (EZRNode *)scanWithStart:(nullable id)startingValue reduceWithIndex:(id (^)(id _Nullable running, T _Nullable next, NSUInteger index))reduceBlock;

#pragma mark For multipart upstreamNodes

/**
 此操作作用为合并多个node，产生一个新的节点，便于一次性处理多个node的结果。combine操作会返回新的节点，此节点会作为多个原节点的下游。当各个node的值都不为EZREmpty时，新节点的值发生变化。

 @param nodes 要合并的多个node。
 @return 新的node，值为ZTupleBase类型，即各个原node的value组成的元组。
 */
+ (EZRNode<__kindof EZTupleBase *> *)combine:(NSArray<EZRNode *> *)nodes;

/**
 此操作将当期节点和传递进来的节点做合并， 效果等同 [EZRNode combine:@[self, node]]

 @param node 将要合并的node
 @return 新的node，值为ZTupleBase类型，即当前node和传递来的node的value组成的元组。
 */
- (EZRNode<EZTuple2<T, id> *> *)combine:(EZRNode *)node;
/**
 此操作作用为合并多个node，产生一个新的节点，便于把多个node当成一个node来用。merge操作会返回新的节点, 此节点会作为多个原节点的下游。当多个node的任何一个node变化时，新的节点的值发生变化。

 @param nodes 要合并的多个node。
 @return 新的node。
 */
+ (EZRNode *)merge:(NSArray<EZRNode *> *)nodes;

/**
 此操作将当期节点和传递进来的节点做合并操作， 效果等同 [EZRNode merge:@[self, node]]

 @param node 将要合并的node
 @return 新的node。
 */
- (EZRNode *)merge:(EZRNode *)node;

/**
 Zips several EZRNodes into one.
 @discussion The value of the zipped value is an EZRNode which contains an array of values.
 The content of the array is the k-th (k >= 1) value of all the sources.
 If any value in the sources is empty, the initial value of the zipped value will be empty as well.
 Any nil value from the sources will be converted to NSNull.null since an array MUST NOT contain a nil.
 The array will change its content iff all the sources have recieved at least one new value.
 You can add / remove upstreamNodes after creating the zipped value.
 The zipped value will be re-calculated after adding / removing an upstream.
 @param nodes An array of source EZRNodes. It should NOT be empty.
 @return An EZRNode contains an array of zipped values.
 */
+ (EZRNode<__kindof EZTupleBase *> *)zip:(NSArray<EZRNode *> *)nodes;

/**
 此操作将当期节点和传递进来的节点做zip打包， 效果等同 [EZRNode zip:@[self, node]]

 @param node 将要打包的节点
 @return 新的node
 */
- (EZRNode<EZTuple2<T, id> *> *)zip:(EZRNode *)node;

@end

#define EZRCombine(...)  _EZRCombine(__VA_ARGS__)
#define EZRZip(...) _EZRZip(__VA_ARGS__)

EZR_MapEachFakeInterfaceDef(15)

#define EZRIFResultTable(_) \
_(EZRNode<T> *, thenNode) \
_(EZRNode<T> *, elseNode);

EZTNamedTupleDef(EZRIFResult, T)

#define EZRSwitchedNodeTupleTable(_) \
_(id<NSCopying>, key) \
_(EZRNode<T> *, node);

EZTNamedTupleDef(EZRSwitchedNodeTuple, T)

@interface EZRIFResult<T> (Extension)

- (EZRIFResult<T> *)then:(void (NS_NOESCAPE ^)(EZRNode<T> *node))thenBlock;
- (EZRIFResult<T> *)else:(void (NS_NOESCAPE ^)(EZRNode<T> *node))elseBlock;

@end


@interface EZRNode<T: id> (SwitchCase)

- (EZRNode<EZRSwitchedNodeTuple<T> *> *)switch:(id<NSCopying> _Nullable (^)(T _Nullable next))switchBlock;

- (EZRNode<EZRSwitchedNodeTuple<id> *> *)switchMap:(EZTuple2<id<NSCopying>, id> *(^)(T _Nullable next))switchMapBlock;

- (EZRNode *)case:(nullable id<NSCopying>)key;

- (EZRIFResult<T> *)if:(BOOL (^)(T _Nullable next))block;

- (EZRNode *)default;

@end

NS_ASSUME_NONNULL_END

