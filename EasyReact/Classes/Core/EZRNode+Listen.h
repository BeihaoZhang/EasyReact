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

@class EZRListenContext<T>;

@interface EZRNode<T> (Listen)

/**
 Listened by listener, able to add additional action through the method of returned EZRListenContext object.
 If additional actions were added, the current node is holded by listener, the holding relationship will be released when the listener is being destroyed.

 @param listener    Listener
 @return            EZRListenContext instance which can attach actions
*/
- (EZRListenContext<T> *)listenedBy:(id)listener;

@end
