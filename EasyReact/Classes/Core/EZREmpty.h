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

/**
 此类为EasyReact框架中的哨兵对象
 EZRNode 是支持 nil 也就是空对象的。所以需要EZREmpty来代表语义上的空。
 如果将当前对象赋值给节点，则会阻断节点向下游节点的传播
 */
@interface EZREmpty : NSObject

/**
 获取哨兵对象的实例，此类是单例。

 @return 哨兵对象的单实例。
 */
+ (instancetype)empty;

@end
