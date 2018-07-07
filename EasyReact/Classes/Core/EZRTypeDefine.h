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

#import <EasyFoundation/EasyFoundation.h>
@import Foundation;

@class EZRNode;
@class EZTuple2;

typedef id _Nullable(^EZRMapBlock)(id _Nullable value);
typedef BOOL (^EZRConditionBlock)(id _Nullable value);
typedef EZRNode *_Nullable (^EZRFlattenMapBlock)(id _Nullable value);
typedef BOOL (^EZRFilterBlock)(id _Nullable value);
typedef EZTuple2<id<NSCopying>, id> * _Nonnull(^EZRSwitchMapBlock)(id _Nullable next);
typedef id _Nonnull(^EZRReduceBlock)(id _Nullable runningValue, id  _Nullable next);
typedef id _Nonnull(^EZRReduceWithIndexBlock)(id _Nullable runningValue, id  _Nullable next, NSUInteger index);
