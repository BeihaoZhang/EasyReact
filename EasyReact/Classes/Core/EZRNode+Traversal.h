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
 节点的访问器协议，用于对图论中的点和边进行遍历
 */
@protocol EZRNodeVisitor <NSObject>

@optional
/**
 访问节点

 @param node 节点
 @param deep 深度，向上为负，向下为正
 @return 是否终止遍历
 */
- (BOOL)visitNode:(EZRNode *)node deep:(NSInteger)deep;

/**
 访问变换

 @param transform 变换
 @return 是否终止遍历
 */
- (BOOL)visitTransform:(id<EZRTransformEdge>)transform;

@end

@interface EZRNode (Traversal)

/**
 开始对一个节点的拓扑进行遍历访问

 @param visitor 访问者对象。
 */
- (void)traversal:(id<EZRNodeVisitor>)visitor;

@end
