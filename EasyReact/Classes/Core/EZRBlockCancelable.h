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

NS_ASSUME_NONNULL_BEGIN

typedef void(^EZRCancelBlockType)(void);

/**
 使用Block来实现 cancel 动作的类
 */
@interface EZRBlockCancelable : NSObject <EZRCancelable>

/**
 用block来执行取消动作的对象 在cancel方法被调用的时候 会自动执行此block

 @param block 代表取消动作的block
 @return 实例
 */
- (instancetype)initWithBlock:(EZRCancelBlockType)block NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
