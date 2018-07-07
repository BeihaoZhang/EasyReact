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

#import <EasyReact/EZREdge.h>
#import <EasyReact/EZRNextReceiver.h>

@class EZRNode;

/**
 This protocol specifies node to node transformation. It is usually used to passing the changes of data from upstream to downstream.
 */
@protocol EZRTransformEdge <EZREdge, EZRNextReceiver>

/**
 The upstream value of the EZRTransformEdge
 */
@property (atomic, strong, nullable) EZRNode *from;

/**
 The downstream value of the EZRTransformEdge
 */
@property (atomic, weak, nullable) EZRNode *to;

/**
 Represent the next instance which can receive the value senderlist and context
 */
@property (atomic, weak, nullable) id<EZRNextReceiver> nextReceiver;

@end
