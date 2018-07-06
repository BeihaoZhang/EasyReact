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

@interface EZRNode<T> (Value)

/**
 如果节点的当前值为 EZREmpty 则返回传递的默认值，如果不为 EZREmpty 则取得当前值

 @param defaultValue 默认值
 @return 计算后的值
 */
- (nullable T)valueWithDefault:(nullable T)defaultValue;

/**
 如果当前的值有值则会执行当前 block, 此 Block 为非逃逸闭包，不会捕获变量。
 类似 Swift语法中的 if let 语法
 
 <pre>@textblock
 
 var o: String?
 
 if let _ = o {
  // do something
 }
 
 @/textblock</pre>
 
 @param processBlock 处理动作的block， block的参数为当前节点的值
 */
- (void)getValue:(void(NS_NOESCAPE ^ _Nullable)(_Nullable T value))processBlock;

@end
