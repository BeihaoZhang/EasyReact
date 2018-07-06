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

#import "EZRDelayTransform.h"

@implementation EZRDelayTransform {
    NSTimeInterval _delayTimeInterval;
    dispatch_queue_t _queue;
}

- (instancetype)initWithDelay:(NSTimeInterval)timeInterval queue:(nonnull dispatch_queue_t)queue{
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(queue);
    if (self = [super init]) {
        _delayTimeInterval = timeInterval;
        _queue = queue;
        [super setName:@"Delay"];
    }
    return self;
}


- (void)next:(id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delayTimeInterval * NSEC_PER_SEC)), _queue, ^{
        [super next:value from:senderList context:context];
    });
}

@end
