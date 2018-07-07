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

@class EZRNode, EZRListenContext;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (EZR_Listen)

/**
 Observes a EZRNode, and uses the return EZRListenContex object to add additional action.
 If additional actions were added, the EZRNode is holded by current object. The holding relationship will be released when the current object is being destroyed.
 Since Objective-C do not support method genericity, so this method is not able to transmit genericity to EZRListenContext instance.
 We suggest using 'ListenedBy:' method defined in EZRNode+Listen, which is able to transmit genericity, for the convenience of type inferences for later API.
 
 @see - [EZRNode+Listen ListenedBy:]
 @param node        Node being listened
 @return            EZRListenContext instance that can be attached additional actions
 */
- (EZRListenContext *)listen:(EZRNode *)node;

/**
 Stops observing node

 @param node        Node being listened
 */
- (void)stopListen:(EZRNode *)node;

@end

NS_ASSUME_NONNULL_END
