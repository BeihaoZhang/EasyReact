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
 If value of current node were EZREmpty, return the passing 'defaultValue', otherwise, return current value.

 @param defaultValue    Default value
 @return                value after calculation
 */
- (nullable T)valueWithDefault:(nullable T)defaultValue;

/**
 Block will be executed if the node has current value. The 'processBlock' is non-escaping block and will not capture variables.
 Like 'if let' in Swift
 
 <pre>@textblock
 
 var o: String?
 
 if let _ = o {
  // do something
 }
 
 @/textblock</pre>
 
 @param processBlock    Block for processing action, and parameter of block is current value of node
 */
- (void)getValue:(void(NS_NOESCAPE ^ _Nullable)(_Nullable T value))processBlock;

@end
