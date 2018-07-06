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

#import <EasyReact/EZRTransformProtocol.h>

@class EZRNode;

/**
 此协议特指节点到节点的协议，通常用来传递上游到下游的数据变化
 */
@protocol EZRNodeTransformProtocol <EZRTransformProtocol>

/**
 变换的下游节点
 */
@property (atomic, weak, nullable) EZRNode *to;

/**
 @param value 最新值
 @param senderList 发送值的节点的链表，可以追溯值的来源
 @param context 用户传递的上下文环境
 */
- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context;

@end
