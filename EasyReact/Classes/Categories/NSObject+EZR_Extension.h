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
 实现了下标方法的对象，用于扩展Fondation类型下对属性的KVO，将其转换为ERZNode。
 */
@property (nonatomic, readonly, strong) EZRPathTrampoline *ezr_path;

/**
 用当前对象生成一个不可变节点对象

 @return 初始值是当前对象的不可变节点
 */
- (EZRNode *)ezr_toNode;

/**
 用当前对象生成一个可变节点对象

 @return 初始值是当前对象的可变节点
 */
- (EZRMutableNode *)ezr_toMutableNode;

@end

#define EZR_PATH(TARGET, KEYPATH)            _EZR_PATH(TARGET, KEYPATH)

NS_ASSUME_NONNULL_END
