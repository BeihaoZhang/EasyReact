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

@class EZRNode, EZRListenContext;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (EZR_Listen)

/**
 
 监听 一个EZRNode, 通过返回的EZRListenContex对象的方法可以添加额外的动作
 如果有额外的动作被添加 则此 EZRNode 被当前对象所持有。在当前对象销毁的时候会自动释放 EZRNode 的持有关系
 由于 Objective-C 不支持方法泛型， 所以此方法无法传递泛型给 EZRListenContext的实例,
 建议使用 ERNode+Listen 中定义的 `ListenedBy:`方法，可以传递泛型。方便后续API 泛型推断。
 
 @param node 被监听的Node
 @return 可以附加动作的EZRListenContext实例
 */
- (EZRListenContext *)listen:(EZRNode *)node;

/**
 可以对Node停止观察

 @param node 被观察的节点
 */
- (void)stopListen:(EZRNode *)node;

@end

NS_ASSUME_NONNULL_END
