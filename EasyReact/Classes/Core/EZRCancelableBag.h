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

/**
 Class that is able to implement cancel action for EZRCancelable object in batch.
 When current object calls cancel method or is being released, all added EZRCancelable objects will call cancel methed and clean the holding relationship
 */
@interface EZRCancelableBag : NSObject <EZRCancelableBagProtocol>

/**
 Gets the instance which is able to implement cancel action for EZRCancelable object in batch.
 @return    EZRCancelableBag instance
 */
+ (instancetype)bag;

@end

NS_ASSUME_NONNULL_END
