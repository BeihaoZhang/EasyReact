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

#import <EasyReact/ERNode.h>
#import <EasyReact/ERMetaMacros.h>
#import <ZTuple/ZTuple.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *ERExceptionReason_SyncTransformBlockAndRevertNotInverseOperations;
extern NSString *ERExceptionReason_FlattenOrFlattenMapNextValueNotERNode;
extern NSString *ERExceptionReason_MapEachNextValueNotTuple;

@class ERAction;

@interface ERNode<T: id> (Operation)

#pragma mark For single upstream

- (ERNode *)map:(id _Nullable (^)(T _Nullable next))block;
- (ERNode<T> *)filter:(BOOL (^)(T _Nullable next))block;
- (ERNode<T> *)skip:(NSUInteger)number;
- (ERNode<T> *)take:(NSUInteger)number;
- (ERNode<T> *)ignore:(nullable T)ignoreValue;
- (ERNode<T> *)mapReplace:(nullable id)mappedValue;
- (ERNode<T> *)distinctUntilChanged;

/**
 Sync the current value to another value.
 The other ERNode's value will be set to the current ERNode's value even if the current value is empty.

 @note Both current ERNode and otherNode must response to -(void)setValue: method, otherwise you will receive an exception while syncing.
 @param otherNode The other ERNode you want to sync.
 @return a cancelable object which is able to stop syncing.
 */
- (id<ERCancelable>)syncTo:(ERNode<T> *)otherNode;
- (id<ERCancelable>)syncTo:(ERNode *)otherNode transform:(id (^)(T source))transform revert:(T (^)(id target))revert;

- (ERNode *)flattenMap:(ERNode * _Nullable (^)(T _Nullable next))block;
- (ERNode *)flatten;

/**
 Changes value if and only if the value does not change again in `interval` seconds.
 @discusstion If a value does not last for `interval` seconds, its listeners / downstreamNodes will not receive this value.
 An throttled empty value will not notify its listeners or downdstreams no matter how long it remains empty.
 The listener or downstream blocks will always be invoked in the main queue.
 If you want to dispatch those blocks to a specified queue, use `-throttle:queue:` method.
 @note It is NOT a real time mechanism, just like an NSTimer.
 @param timeInterval The time interval in seconds, MUST be greater than 0.
 @return A new ERNode which change its value iff the value lasts for a given interval.
 */
- (ERNode *)throttle:(NSTimeInterval)timeInterval;

/**
 Changes value if and only if the value does not change again in `interval` seconds.
 @discusstion If a value does not last for `interval` seconds, its listeners / downstreamNodes will not receive this value.
 An throttled empty value will not notify its listeners or downdstreams no matter how long it remains empty.
 @note It is NOT a real time mechanism, just like an NSTimer.
 @param timeInterval The time interval in seconds, MUST be greater than 0.
 @param queue The queue which listener block will be invoked in.
 @return A new ERNode which change its value iff the value lasts for a given interval.
 */
- (ERNode *)throttle:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue;

#pragma mark For multipart upstreamNodes
+ (ERNode<__kindof ZTupleBase *> *)combine:(NSArray<ERNode *> *)nodes;
+ (ERNode *)merge:(NSArray<ERNode *> *)nodes;

/**
 Zips several ERNodes into one.
 @discussion The value of the zipped value is an ERNode which contains an array of values.
 The content of the array is the k-th (k >= 1) value of all the sources.
 If any value in the sources is empty, the initial value of the zipped value will be empty as well.
 Any nil value from the sources will be converted to NSNull.null since an array MUST NOT contain a nil.
 The array will change its content iff all the sources have recieved at least one new value.
 You can add / remove upstreamNodes after creating the zipped value.
 The zipped value will be re-calculated after adding / removing an upstream.
 @param nodes An array of source ERNodes. It should NOT be empty.
 @return An ERNode contains an array of zipped values.
 */
+ (ERNode<__kindof ZTupleBase *> *)zip:(NSArray<ERNode *> *)nodes;

@end

#define ERCombine(...)  _ERCombine(__VA_ARGS__)
#define ERZip(...) _ERZip(__VA_ARGS__)

ER_MapEachFakeInterfaceDef(15)

NS_ASSUME_NONNULL_END
