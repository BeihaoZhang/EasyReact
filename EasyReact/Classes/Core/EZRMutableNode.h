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

NS_ASSUME_NONNULL_BEGIN

/**
 Mutable version of EZRNode, provide the ability of assigning value to node.
 Provides the ability to transmit the assigned new value to downstream nodes also.
 */
@interface EZRMutableNode<T> : EZRNode<T>

/**
 A thread-safe object that defines the value of the receiver.
 */
@property (atomic, readwrite, strong, nullable) T value;

/**
 Returns a new node created by a given boolean value to indicate whether the node is mutable.
 If being immutable, node will throw `EZRExceptionReason_CannotModifyEZRNode` exception when it is assigned value.

 @param value       Value of the node, could be nil
 @param isMutable   Whether current node is mutable or not
 @return            New node instance
 */
- (instancetype)initWithValue:(nullable T)value mutable:(BOOL)isMutable NS_DESIGNATED_INITIALIZER;

/**
 Sets value to node and attach a context if needed, the context will be transfer to downstream nodes and listeners.

 @param value       Value of the node
 @param context     Context
 */
- (void)setValue:(nullable T)value context:(nullable id)context;

/**
 Cleans the receiver's value to EZREmpty.empty.
 */
- (void)clean;

@end

NS_ASSUME_NONNULL_END
