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

@class EZRNode, EZRSenderList;

/**
 This protocol represents a directed edge in Graph Theory for EasyReact.
 EZREdge owns source and target object, when source and target object could be any kind of class.
 Normally, we use EZRTransformEdge to represent the relationship between nodes themsleves and use EZRListenEdge to represent the relationship between node and listener
 */
@protocol EZREdge <NSObject>

@required;

/**
 Name of the directed edge, used for data visualized debugging function
 */
@property (nonatomic, readwrite, copy, nullable) NSString *name;

/**
 Upstream node where the edge comes from, data transmission will happen when both upstream and downstream node have values
 */
@property (atomic, strong, nullable) id from;

/**
 Downstream node where the edge directs to, data transmission will happen when both upstream and downstream node have values
 */
@property (atomic, weak, nullable) id to;

@end
