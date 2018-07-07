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

#import <EasyReact/EZRTransformEdge.h>

NS_ASSUME_NONNULL_BEGIN

@class EZRNode, EZRSenderList;

/**
 EZRTransform represents a kind of transformation from node to node. The Default implementation is passing value to downstrean node directly. Category can be extended on demand afterwards
 */
@interface EZRTransform : NSObject <EZRTransformEdge>

/**
 The transform method how the upstream value change affects downstream node.
 Sub class needs to call super implementation when customizing data processing method.
 
 If the block didn't need to capture super in your sub class implementation, simply call super, just like EZRMapTransform. for example:
 
 <pre>@textblock
 
 - (void)next:(id)value from:(ERSenderList *)senderList {
        if (_block) {
        [super next:_block(value) from:senderList];
    }
 }
 
 @/textblock</pre>
 
 If the block needed to capture super in your sub class implementation, call self indirectly due to the implicit capture, just like EZRFlattenTransform. for example:
 
 <pre>@textblock
 
 
 - (void)next:(id)value from:(ERSenderList *)senderList {
    EZRNode *node = _block(value);
    [self.cancelable cancel];
 
    @ezr_weakify(self)
    self.cancelable = [node listen:^(id  _Nullable next) {
        @ezr_strongify(self)
        [self _superNext:next from:senderList];
    }];
 }
 
 - (void)_superNext:(id)value from:(ERSenderList *)senderList {
    [super next:value from:senderList];
 }
 
 @/textblock</pre>
 
 @param value           The latest value
 @param senderList      A list of sender node, used in judging whether a circle occurs
 @param context         Context that comes from upstream node
 */
- (void)next:(nullable id)value from:(EZRSenderList *)senderList context:(nullable id)context;

@end

NS_ASSUME_NONNULL_END
