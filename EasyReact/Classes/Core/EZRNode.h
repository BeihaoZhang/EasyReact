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

NS_ASSUME_NONNULL_BEGIN

// Exception name
extern NSString *EZRNodeExceptionName; 
extern NSString *EZRExceptionReason_CannotModifyEZRNode;

@protocol EZRCancelable, EZRTransformEdge;
@class EZRListenContext<T>;

/**
 EZRNode is the most important class in the whole EasyReact, it represents a node which has a value, and can change this value afterwards. When the value is being changed, listeners which listen to this node can receive the new value. Nodes can connect to others with EZRTransformEdge. When a node's value changes, other connected nodes will change their values due to the transformation.
 */
@interface EZRNode<__covariant T: id> : NSObject

/**
 The name associated with the receiver, if any. Used for debugging or producing topological graph in convenience.
 */
@property (nonatomic, readwrite, strong, nullable) NSString *name;

/**
 A thread-safe object that defines the value of the receiver.
 */
@property (atomic, readonly, strong, nullable) T value;

/**
 A Boolean value that indicates whether the receiver is mutable.
 */
@property (atomic, readonly, assign, getter=isMutable) BOOL mutable;

/**
 An array of the receiver's upstream nodes.
 */
@property (atomic, readonly, copy) NSArray<EZRNode *> *upstreamNodes;

/**
 An array of the receiver's downstream nodes.
 */
@property (atomic, readonly, copy) NSArray<EZRNode *> *downstreamNodes;

/**
 An array of the receiver's upstream transformations.
 */
@property (atomic, readonly, copy) NSArray<id<EZRTransformEdge>> *upstreamTransforms;

/**
 An array of the receiver's downstream transformations.
 */
@property (atomic, readonly, copy) NSArray<id<EZRTransformEdge>> *downstreamTransforms;

/**
 A boolean value that indicates whether the receiver has upstream node.
 */
@property (atomic, readonly, assign) BOOL hasUpstreamNode;

/**
 A boolean value that indicates whether the receiver has downstream node.
 */
@property (atomic, readonly, assign) BOOL hasDownstreamNode;

/**
 A Boolean value that indicates whether the receiver has a listener.
 */
@property (atomic, readonly, assign) BOOL hasListener;

/**
 A Boolean value that indicates whether the node is equal to EZREmpty.empty
 The feature of empty is that EZREmpty.empty will not trigger listeners, nor change the downstream nodes.
 */
@property (atomic, readonly, assign, getter=isEmpty) BOOL empty;

/**
 Initializes a new node with EZREmpty.empty

 @return        New node instance
 */
- (instancetype)init;

/**
 Initializes a node with the given value

 @param value   Initial value
 @return        New node instance
 */
- (instancetype)initWithValue:(nullable T)value NS_DESIGNATED_INITIALIZER;

/**
 Returns a node with a given value

 @param value   Initial value
 @return        New node instance
 */
+ (instancetype)value:(nullable T)value;

/**
 Returns the receiver instance named by using a given name.

 @param name    Name
 @return        Node instance
 */
- (instancetype)named:(NSString *)name;

/**
 Returns the receiver instance named by using a given format string.

 @param format  Formatted string
 @param ...     Variadic parameter lists
 @return        Node instance
 */
- (instancetype)namedWithFormat:(NSString *)format, ...;

/**
 Links to a given upstream node using a specific transformation. The receiver will be the downstream node.

 @param node        Upstream node which wants to link to
 @param transform   Transforming action between upstream node
 @return            EZRCancelable object whose link can be cancelable
 */
- (id<EZRCancelable>)linkTo:(EZRNode *)node transform:(id<EZRTransformEdge>)transform;

/**
 Links to a given upstream node. The receiver will be the downstream node and will keep the same value with the given upstream node

 @param node    Upstream node which wants to link to
 @return        EZRCancelable object whose link can be cancelable
 */
- (id<EZRCancelable>)linkTo:(EZRNode *)node;

/**
 Finds the receiver's downstream transformations those linked to a given node. If not found, an empty array will be returned.

 @param to      Downstream node
 @return        Array of downstream edges
 */
- (NSArray<id<EZRTransformEdge>> *)downstreamTransformsToNode:(EZRNode *)to;

/**
 Finds the receiver's upstream transformations those linked to a given node. If not found, an empty array will be returned.

 @param from    Upstream node
 @return        Array of upstream edges
 */
- (NSArray<id<EZRTransformEdge>> *)upstreamTransformsFromNode:(EZRNode *)from;

/**
 Removes a specific downstream node, if any. The transformation connected to the specific downstream node will be removed also.

 @param downstream  The downstream node that will be removed
 */
- (void)removeDownstreamNode:(EZRNode *)downstream;

/**
 Removes all downstream nodes of the receiver
 */
- (void)removeDownstreamNodes;

/**
 Removes a specific upstream node, if any. The transformation connected to the specific upstream node will be removed also.
 
 @param upstream    The upstream node that will be removed
 */
- (void)removeUpstreamNode:(EZRNode *)upstream;

/**
 Removes all upstream nodes of the receiver
 */
- (void)removeUpstreamNodes;

@end

NS_ASSUME_NONNULL_END
