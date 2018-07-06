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

@class EZRNode, EZRSenderList;

/**
 此协议是 EasyReact用来代表图论中一条有向边的协议。
 此边拥有来源和目的对象，其中来源是 EZRNode 的实例
 目的对象可能是任意类型对象。
 通常使用 EZRNodeTransformProtocol 来代表节点和节点之间的关系
 或者是 EZRListenTransformProtocol 来代表节点和监听者之间的关系
 */
@protocol EZRTransformProtocol <NSObject>

@required;

/**
 变换的名字，用于调试的数据可视化
 */
@property (nonatomic, readwrite, copy, nullable) NSString *name;

/**
 变换的上游节点，当同时有值时会发生数据传递
 */
@property (atomic, strong, nullable) EZRNode *from;

/**
 变换的下游节点， 当同时有值时会发生数据传递
 */
@property (atomic, weak, nullable) id to;

/**
 上游传递到下游的数据流动方法

 @param value 最新值
 @param senderList 发送值的节点的链表，可以追溯值的来源
 @param context 用户传递的上下文环境
 */
- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context;

@end
