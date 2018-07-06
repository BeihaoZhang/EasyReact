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

被监听者监听, 通过返回的EZRListenContex对象的方法可以添加额外的动作
如果有额外的动作被添加 则当前节点被监听者对象所持有。在当前监听者对象销毁的时候会自动释放当前节点的的持有关系

@param listener 监听者
@return 可以附加动作的EZRListenContext实例
*/
- (EZRListenContext<T> *)listenedBy:(id)listener;

@end
