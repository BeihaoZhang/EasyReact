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
#import <EasyReact/EZRSenderList.h>

@protocol EZRCancelable, EZRListenEdge, EZRSenderList;

NS_ASSUME_NONNULL_BEGIN

/**
 This class is an assistant class used for managing additional attached action when the values of notes were listened by listeners change.
 This class doesn't need users to manage the life cycle
 */
@interface EZRListenContext<T> : NSObject

/**
 Process in listening progress. Block will be called after the change of value.
 
 @param block   Block used to receive new value
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withBlock:(void (^)(T _Nullable next))block;


/**
 Process in listening progress. Block will be called after the change of value.

 @param block   Block used to receive new value, contains context besides new value
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withContextBlock:(void (^)(T _Nullable next, id _Nullable context))block;

/**
 Process in listening progress. Block will be called in the specific queue after the change of value.
 
 @param block   Block used to receive new value
 @param queue   The specific queue
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withBlock:(void (^)(T _Nullable next))block on:(dispatch_queue_t)queue;

/**
 Listens the change of value. The parameter block will be called in the specific queue when the value changes.
 
 @param block   Block used to receive new value, contains context besides new value
 @param queue   The specific queue
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withContextBlock:(void (^)(T _Nullable next, id _Nullable context))block on:(dispatch_queue_t)queue;

/**
 Listens the change of value. The parameter block will be called in the specific queue when the value changes.
 
 @param block   Block used to receive new value, contains context and senderlist besides new value
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withSenderListAndContextBlock:(void (^)(T _Nullable next, EZRSenderList *senderList,  id _Nullable context))block;

/**
 Listens the change of value. The parameter block will be called in the specific queue when the value changes.
 
 @param block   Block used to receive new value, contains context and senderlist besides new value
 @param queue   The specific queue
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withSenderListAndContextBlock:(void (^)(T _Nullable next, EZRSenderList *senderList,  id _Nullable context))block on:(dispatch_queue_t)queue;
/**
 Listens the change of value. The parameter block will be called in the main queue when the value changes.
 
 @param block   Block used to receive new value
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withBlockOnMainQueue:(void (^)(T _Nullable next))block;

/**
 Process in listening progress. Block will be called in the main queue after the change of value.

 @param block   Block used to receive new value, contains context besides new value
 @return        Object whose listen action can be cancelled
 */
- (id<EZRCancelable>)withContextBlockOnMainQueue:(void (^)(T _Nullable next, id _Nullable context))block;

/**
 Listens the change of value. The parameter's processing method will be called after the change of value.
 
 @param listenEdge  Listener used to receive new values, corresponding to EZRListenEdge protocol
 */
- (id<EZRCancelable>)withListenEdge:(id<EZRListenEdge>)listenEdge;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
