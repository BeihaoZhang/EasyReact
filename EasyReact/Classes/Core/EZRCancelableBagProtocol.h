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

#import <EasyReact/EZRCancelable.h>

@protocol EZRCancelableBagProtocol <EZRCancelable>

/**
 将可以被cancel的对象放进袋子里，后续可以批量操作。

 @param cancelable 可以取消的对象
 */
- (void)addCancelable:(id<EZRCancelable>)cancelable;

/**
 将可以被cancel对象从袋子里取出

 @param cancelable 可以被取消的对象
 */
- (void)removeCancelable:(id<EZRCancelable>)cancelable;

@end
