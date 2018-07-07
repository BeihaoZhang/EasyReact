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
#import <EasyFoundation/EasyFoundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const EZRExceptionReason_SyncTransformBlockAndRevertNotInverseOperations;
FOUNDATION_EXTERN NSString * const EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode;
FOUNDATION_EXTERN NSString * const EZRExceptionReason_MapEachNextValueNotTuple;
FOUNDATION_EXTERN NSString * const EZRExceptionReason_CasedNodeMustGenerateBySwitchOrSwitchMapOperation;

@interface EZRNode<T: id> (Operation)

#pragma mark - For single upstream

/**
 This operation is a copy action. Fork operation will return a new node as the receiver's downstream.

 @return    New node, whose value keeping same as the receiver
 */
- (EZRNode<T> *)fork;

/**
 Map operation will return a new node as the receiver's downstream. The block will be called each time the receiver changes, and a new value will be assigned to the returned node after executing the block and processing the changing value of the receiver.

 @param block   Processing block of map operation
 @return        New node, whose value is the return value of the block
 */
- (EZRNode *)map:(id _Nullable (^)(T _Nullable next))block;

/**
 Filters operation will return a new node as the receiver's downstream. The block will be called each time the receiver changes, processing the changing value of the receiver and returning a BOOL value deciding whether new node will receive this value. If this value is received, it will be the value of the new node.

 @param block   Processing block of filter operation
 @return        New node, whose value will equal to receiver's value if block returns YES. Otherwise, value won't change.
 */
- (EZRNode<T> *)filter:(BOOL (^)(T _Nullable next))block;

/**
 Skips the first N times value. Skip operation will return a new node as the receiver's downstream.

 @param number  The number of values needed to be skipped(ignored)
 @return        New node, whose value will be same as the receiver's value after the first 'number' times changes of the receiver
 */
- (EZRNode<T> *)skip:(NSUInteger)number;

/**
 Takes the first N times value. Take operation will return a new node as the receiver's downstream.

 @param number  The number of values needed to be taken
 @return        New node, whose value will be same as the receiver's value within the first 'number' times changes of the receiver
 */
- (EZRNode<T> *)take:(NSUInteger)number;

/**
 Ignores the specific value. Ignore operation will return a new node as the receiver's downstream.

 @param ignoreValue     Value needed to be ignored
 @return                New node, whose value will keep unchanged if the receiver's value equals to 'ignoreValue', otherwise the value of new node will keep same with the receiver's value
 */
- (EZRNode<T> *)ignore:(nullable T)ignoreValue;

/**
 Selects the specific value. Select operation will return a new node as the receiver's downstream.

 @param selectedValue   The value needed to be selected
 @return                New node, whose value will keep the same with the receiver's value if the receiver's value equals to 'selectedValue', otherwise, the value of new node will keep unchanged.
 */
- (EZRNode<T> *)select:(nullable T)selectedValue;

/**
 Uses the specific value instead of the value passing from the receiver. MapReplace operation will return a new node as the receiver's downstream.

 @param mappedValue     The value used to replace the value passing from the receiver.
 @return                New node, whose value will be 'mappedValue' when the receiver's value changes.
 */
- (EZRNode *)mapReplace:(nullable id)mappedValue;

/**
 Only receives value that not repeated continuously. DistinctUntilChanged operation will return a new node as the receiver's downstream.

 @return        New node, whose value will only change when the value passing from the receiver is diffrent from current value.
 */
- (EZRNode<T> *)distinctUntilChanged;

/**
 This operation is used to process the node itself.

 @param thenBlock   Processing block, the parameter 'node' is the caller itself.
 @return            The receiver
 */
- (EZRNode<T> *)then:(void(NS_NOESCAPE^)(EZRNode<T> *node))thenBlock;

/**
 This operation is used to transmit value through the specific queue. DeliverOn operation will return a new node as the receiver's downstream.

 @param queue       The specific queue, using to transmit value
 @return            New value, whose value keeps the same with the receiver's value
 */
- (EZRNode<T> *)deliverOn:(dispatch_queue_t)queue;

/**
 This operation is used to transmit value through the main queue. DeliverOnMainQueue operation will return a new node as the receiver's downstream.

 @return            New value, whose value keeps the same with the receiver's value
 */
- (EZRNode<T> *)deliverOnMainQueue;

/**
 Synchronizes the current value with another value.
 The other EZRNode's value will be set to the current EZRNode's value even if the current value is empty.

 @note Both current EZRNode and othEZRNode must response to -(void)setValue: method, otherwise you will receive an exception while syncing.
 
 @param othEZRNode  The other EZRNode you want to sync.
 @return            A cancelable object which is able to stop syncing.
 */
- (id<EZRCancelable>)syncWith:(EZRNode<T> *)othEZRNode;

/**
 Sync the current value to another value.
 The other EZRNode's value will be set to the current EZRNode's value even if the current value is empty.

 @param othEZRNode  The other EZRNode you want to sync.
 @param transform   Current nodes's value will use transform to other node.
 @param revert      The other node's value will use revert to current node.
 @return            A cancelable object which is able to stop syncing.
 */
- (id<EZRCancelable>)syncWith:(EZRNode *)othEZRNode transform:(id (^)(T source))transform revert:(T (^)(id target))revert;

/**
 The operation used to reduce order after mapping node. FlattenMap operation will return a new node as the receiver's downstream. The value of the receiver will transfer to a node after block execution, and then be reduced order.

 @param block   Processing block of map, receiving a value and returning a node for reducing order.
 @return        New node, whose value is the returned node's value of mapping block
 */
- (EZRNode *)flattenMap:(EZRNode * _Nullable (^)(T _Nullable next))block;

/**
 The operation used to reduce order of node. Flatten operation will return a new node as the receiver's downstream. When the receiver's value is a EZRNode, the value of new node will change, and will equal to the value of the receiver's value.

 @return        New node
 */
- (EZRNode *)flatten;

/**
 Changes value if and only if the value does not change again in `interval` seconds.
 
 @discusstion If a value does not last for `interval` seconds, its listeners / downstreamNodes will not receive this value.
 An throttled empty value will not notify its listeners or downdstreams no matter how long it remains empty.
 The listener or downstream blocks will always be invoked in the main queue.
 If you want to dispatch those blocks to a specified queue, use `-throttle:queue:` method.
 
 @note It is NOT a real time mechanism, just like an NSTimer.
 
 @param timeInterval    The time interval in seconds, MUST be greater than 0.
 @return                A new EZRNode which change its value if and only if the value lasts for a given interval.
 */
- (EZRNode<T> *)throttleOnMainQueue:(NSTimeInterval)timeInterval;

/**
 Changes value if and only if the value does not change again in `interval` seconds.
 
 @discusstion If a value does not last for `interval` seconds, its listeners / downstreamNodes will not receive this value.
 An throttled empty value will not notify its listeners or downdstreams no matter how long it remains empty.
 
 @note It is NOT a real time mechanism, just like an NSTimer.
 
 @param timeInterval    The time interval in seconds, MUST be greater than 0.
 @param queue           The queue which listener block will be invoked in.
 @return                A new EZRNode which change its value if and only if the value lasts for a given interval.
 */
- (EZRNode<T> *)throttle:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue;

/**
 Delays the passing value from the receiver in specific queue. Delay operation will return a new node as the receiver's downstream.

 @param timeInterval    Delayed time interval, in second
 @param queue           The specific queue for passing value
 @return                New node, whose value equals to the receiver's value.
 */
- (EZRNode<T> *)delay:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue;

/**
 Delays the passing value from the receiver in the main queue. Delay operation will return a new node as the receiver's downstream.

 @param timeInterval    Delayed time interval, in second
 @return                New node, whose value equals to the receiver's value.
 */
- (EZRNode<T> *)delayOnMainQueue:(NSTimeInterval)timeInterval;

/**
 Reduces the changing value of node each time. Scan operation will return a new node as the receiver's downstream. Each time the node changes, 'reduceBlock' will be called and will return a running value for passing to the 'reduceBlock' again at next change.
 
 @param startingValue   Beginning Value
 @param reduceBlock     Block for reducing, with parameters:
    <pre>@textblock
         running     - Reducing result last time
         next        - Current value of node
    @/textblock</pre>
 @return                New node, whose value is running value.
 */
- (EZRNode *)scanWithStart:(nullable id)startingValue reduce:(id (^)(id _Nullable running, T _Nullable next))reduceBlock;

/**
 Reduces the changing value of node each time. Scan operation will return a new node as the receiver's downstream. Each time the node changes, 'reduceBlock' will be called and will return a running value for passing to the 'reduceBlock' again  at next change.

 @param startingValue   Beginning Value
 @param reduceBlock     Block for reducing, with parameters:
     <pre>@textblock
         running     - Reducing result last time
         next        - Current value of node
         index       - index of the value changes, starts from 0.
     @/textblock</pre>
 @return                New node, whose value is running value.
 */
- (EZRNode *)scanWithStart:(nullable id)startingValue reduceWithIndex:(id (^)(id _Nullable running, T _Nullable next, NSUInteger index))reduceBlock;

#pragma mark For multipart upstreamNodes

/**
 Combines mutiple nodes into one node, for the convenience of processing mutiple nodes in one time. Combine operation will return a new node as the muliple nodes' downstream. The new node value will change when none of the muliple nodes' values is EZREmpty.

 @param nodes       Nodes that will be combined
 @return            New node, which is kind of EZTupleBase, is a tuple consitituted by muliple nodes.
 */
+ (EZRNode<__kindof EZTupleBase *> *)combine:(NSArray<EZRNode *> *)nodes;

/**
 Combines the receiver and the passing node together, same as [EZRNode combine:@[self, node]]

 @param node        Node that will be combined
 @return            New node, which is kind of EZTupleBase, is a tuple consitituted by the receiver and passing node.
 */
- (EZRNode<EZTuple2<T, id> *> *)combine:(EZRNode *)node;

/**
 Merges mutiple nodes into one node, for the convenience of processing mutiple nodes in one time. Merge operation will return a new node as mutiple nodes' downstream. If any of those nodes changes, the value of new node will change.
 
 @param nodes       Node that will be merged
 @return            New node
 */
+ (EZRNode *)merge:(NSArray<EZRNode *> *)nodes;

/**
 Merges the current node and the passing node together, same as [EZRNode merge:@[self, node]]

 @param node        Node that will be merged
 @return            New node
 */
- (EZRNode *)merge:(EZRNode *)node;

/**
 Zips several EZRNodes into one.
 
 @discussion The value of the zipped value is an EZRNode which contains an array of values.
 The content of the array is the k-th (k >= 1) value of all the sources.
 If any value in the sources is empty, the initial value of the zipped value will be empty as well.
 Any nil value from the sources will be converted to NSNull.null since an array MUST NOT contain a nil.
 The array will change its content if and only if all the sources have recieved at least one new value.
 You can add / remove upstreamNodes after creating the zipped value.
 The zipped value will be re-calculated after adding / removing an upstream.
 
 @param nodes       An array of source EZRNodes. It should NOT be empty.
 @return            An EZRNode contains an array of zipped values.
 */
+ (EZRNode<__kindof EZTupleBase *> *)zip:(NSArray<EZRNode *> *)nodes;

/**
 Zips current node with the passing node together, same as [EZRNode zip:@[self, node]]

 @param node        EZRNode that will be zipped with current node
 @return            New EZRNode
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

/**
 Using the return key of 'switchBlock' to group the future values of current node. If there is no corresponding downstream node for current key, a new node will be created. it is usually used to separate various return nodes, and we can get the specific key value node through 'if', 'case', 'default' operation afterwards.

 @param switchBlock         Block used for grouping
 @return                    EZRNode whose value is kind of EZRSwitchedNodeTuple
 */
- (EZRNode<EZRSwitchedNodeTuple<T> *> *)switch:(id<NSCopying> _Nullable (^)(T _Nullable next))switchBlock;


/**
 Using the return key of 'switchBlock' to group the future values of current node. If there is no corresponding downstream node for current key, a new node will be created. it is usually used to separate various return nodes, and wen can get the specific key value node through 'if', 'case', 'default' operation afterwards.
 
 @param switchMapBlock      Block used for grouping
 @return                    EZRNode whose value is kind of EZRSwitchedNodeTuple
 */
- (EZRNode<EZRSwitchedNodeTuple<id> *> *)switchMap:(EZTuple2<id<NSCopying>, id> *(^)(T _Nullable next))switchMapBlock;

/**
 Filters the node created by - [EZRNode switch:] or - [EZRNode switchMap:] into the one that corresponds to specific key.

 @param key         Specific key
 @return            Node whose value corresponds to specific key.
 */
- (EZRNode *)case:(nullable id<NSCopying>)key;

/**
 Separates current node into node that satisfies condition and node not satisfies. like [[EZRNode switch:] case:@YES] and [[EZRNode switch:] case:@NO]

 @param block       Judge rules for separating node
 @return            Tuple of node after separation
 */
- (EZRIFResult<T> *)if:(BOOL (^)(T _Nullable next))block;

/**
 Operation that matches nil. nil could be also used as key

 @return            Node using nil as key
 */
- (EZRNode *)default;

@end

NS_ASSUME_NONNULL_END
