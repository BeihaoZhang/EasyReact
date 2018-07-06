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
 EZRNode 的可变版本。提供了对节点赋值的能力。
 并且可以将设置的新值向下游传递
 */
@interface EZRMutableNode<T> : EZRNode<T>

/**
 节点的值，目前只支持强引用。
 节点值的设置是线程安全的。
 */
@property (atomic, readwrite, strong, nullable) T value;

/**
 通过指定值初始化一个节点，并且标记当前的节点是否可变。
 如果为不可变，则再赋值的时候会抛出 `EZRExceptionReason_CannotModifyEZRNode` 异常。

 @param value 节点的值，可以为nil值
 @param isMutable 当前节点是否可修改
 @return 新的节点实例
 */
- (instancetype)initWithValue:(nullable T)value mutable:(BOOL)isMutable NS_DESIGNATED_INITIALIZER;

/**
 对节点赋值并且可以附加一个标记， 此标记会传递到下游节点和监听者。

 @param value 节点的值
 @param context 上下文标记
 */
- (void)setValue:(T)value context:(nullable id)context;

/**
 清除节点当前的值，使其恢复为empty
 */
- (void)clean;

@end

NS_ASSUME_NONNULL_END
