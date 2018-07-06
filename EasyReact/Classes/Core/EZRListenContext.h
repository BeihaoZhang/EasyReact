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

#import <Foundation/Foundation.h>

@protocol EZRCancelable, EZRListenTransformProtocol;

NS_ASSUME_NONNULL_BEGIN

/**
 此类用来管理监听者监听节点的值发生变化时可以附加额外动作的辅助类。
 此类并不需要开发者管理生命周期
 */
@interface EZRListenContext<T> : NSObject

/**
 监听过程中的处理部分，当值变化后block被调用。
 
 @param block 用来接收新值的block
 @return 可以取消监听动作的对象
 */
- (id<EZRCancelable>)withBlock:(void (^)(T _Nullable next))block;


/**
 监听过程中的处理部分，当值变化后block被调用。

 @param block 用来接收新值的block，除新值外还带有一个context
 @return 可以取消监听动作的对象
 */
- (id<EZRCancelable>)withContextBlock:(void (^)(T _Nullable next, id _Nullable context))block;

/**
 监听过程中的处理部分，当值变化后block在指定队列被调用。
 
 @param block 用来接收新值的block
 @param queue 指定的队列
 @return 可以取消监听动作的对象
 */
- (id<EZRCancelable>)withBlock:(void (^)(T _Nullable next))block on:(dispatch_queue_t)queue;

/**
 监听值的变化，当值发生变化的时候会在指定队列调用入参的 block。
 
 @param block 用来接收新值的block, 除新值外还带有一个context
 @param queue 指定的队列
 @return 可以取消监听动作的对象
 */
- (id<EZRCancelable>)withContextBlock:(void (^)(T _Nullable next, id _Nullable context))block on:(dispatch_queue_t)queue;

/**
 监听值的变化，当值发生变化的时候会在主队列调用入参的 block
 
 @param block 用来接收新值的block
 @return 可以取消监听动作的对象
 */
- (id<EZRCancelable>)withBlockOnMainQueue:(void (^)(T _Nullable next))block;

/**
 监听过程中的处理部分，当值变化后block在主队列被调用。

 @param block 用来接收新值的block, 除新值外还带有一个context
 @return 可以取消监听动作的对象
 */
- (id<EZRCancelable>)withContextBlockOnMainQueue:(void (^)(T _Nullable next, id _Nullable context))block;

/**
 监听值的变化，当值发生变化的时候会调用入参的监听处理方法。
 
 @param listenTransform 用来接收新值的监听者，必须要符合 EZRListenTransformProtocol 协议
 */
- (id<EZRCancelable>)withListenTransform:(id<EZRListenTransformProtocol>)listenTransform;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
