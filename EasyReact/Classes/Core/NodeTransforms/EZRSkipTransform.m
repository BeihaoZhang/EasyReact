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

#import "EZRSkipTransform.h"
#import "EZRMetaMacrosPrivate.h"

@implementation EZRSkipTransform {
    NSUInteger _skippedTimes;
    NSUInteger _needSkipTimes;
    EZR_LOCK_DEF(_skipedTimesLock);
}

- (instancetype)initWithNumber:(NSUInteger)needSkipTimes {
    if (self = [super init]) {
        _needSkipTimes = needSkipTimes;
        _skippedTimes = 0;
        EZR_LOCK_INIT(_skipedTimesLock);
        [super setName:@"Skip"];
    }
    return self;
}

- (void)next:(id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    id from = self.from;
    BOOL canSend = ({
        EZR_SCOPELOCK(_skipedTimesLock);
        ++_skippedTimes > _needSkipTimes;
    });
    
    if (canSend && from == self.from) {
        [super next:value from:senderList context:context];
    }
}

- (void)setFrom:(EZRNode *)from {
    if (self.from != from) {
        EZR_SCOPELOCK(_skipedTimesLock);
        _skippedTimes = 0;
    }
    [super setFrom:from];
}

@end
