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

#import <EasyReact/EZRCancelableBagProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZRCancelableBag : NSObject <EZRCancelableBagProtocol>

/**
 获取批量操作的袋子对象
 此袋子被取消或者被释放的时候会执行袋子里面所有的可取消对象的 cancel 方法， 并且清空这个袋子

 @return 袋子实例
 */
+ (instancetype)bag;

@end

NS_ASSUME_NONNULL_END
