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
#import <EasyReact/EZRMetaMacros.h>

NS_ASSUME_NONNULL_BEGIN

@class EZRPathTrampoline, EZRMutableNode, EZRNode;

@interface NSObject (EZR_Extension)

/**
 Object which implements subscript method, used for extending the KVO and KVC of the Foundation object's property and transforming into ERZNode
 */
@property (nonatomic, readonly, strong) EZRPathTrampoline *ezr_path;

/**
 Generates an immutable node object using current object

 @return    Immutable object whose initial value is current object
 */
- (EZRNode *)ezr_toNode;

/**
 Generates a mutable node object using current object

 @return    Mutable object whose initial value is current object
 */
- (EZRMutableNode *)ezr_toMutableNode;

@end

#define EZR_PATH(TARGET, KEYPATH)            _EZR_PATH(TARGET, KEYPATH)

NS_ASSUME_NONNULL_END
