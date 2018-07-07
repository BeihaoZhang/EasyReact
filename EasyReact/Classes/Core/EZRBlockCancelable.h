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
 Class which implements cancel action using Block
 */
@interface EZRBlockCancelable : NSObject <EZRCancelable>

/**
 Object which executes cancel action using Block, when a cancel method is invoked, the block will be called

 @param block   Block representing the cancel action
 @return        EZRBlockCancelable instance
 */
- (instancetype)initWithBlock:(EZRCancelBlockType)block NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
