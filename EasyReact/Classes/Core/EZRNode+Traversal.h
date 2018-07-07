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

/**
 Visitor protocol of EZRNode, used for traversing nodes and edges to get a topological graph.
 */
@protocol EZRNodeVisitor <NSObject>

@optional
/**
 Visits from a node by a given depth, and returns a boolean value to indicate whether the traversing finished.

 @param node    EZRNode
 @param deep    Depth, negative for upwards and positive for downwards
 @return        A boolean value to indicate whether the traversing finished.
 */
- (BOOL)visitNode:(EZRNode *)node deep:(NSInteger)deep;

/**
 Visits from a transformation by a given depth, and returns a boolean value to indicate whether the traversing finished.

 @param transform   Transforming edge
 @return            A boolean value to indicate whether the traversing finished.
 */
- (BOOL)visitTransform:(id<EZRTransformEdge>)transform;

@end

@interface EZRNode (Traversal)

/**
 Begin traversing by a given visitor object.

 @param visitor     Visitor object
 */
- (void)traversal:(id<EZRNodeVisitor>)visitor;

@end
