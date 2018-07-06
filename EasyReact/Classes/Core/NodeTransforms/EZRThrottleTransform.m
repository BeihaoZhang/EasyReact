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

#import "EZRThrottleTransform.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRMetaMacros.h"
#import "EZRMetaMacrosPrivate.h"

@implementation EZRThrottleTransform {
    @private
    NSTimeInterval _throttleInterval;
    dispatch_source_t _throttleSource;
    dispatch_queue_t _queue;
    EZR_LOCK_DEF(_sourceLock);
}

- (instancetype)initWithThrottle:(NSTimeInterval)timeInterval on:(dispatch_queue_t)queue {
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(queue);
    if (self = [super init]) {
        _throttleInterval = timeInterval;
        _queue = queue;
        EZR_LOCK_INIT(_sourceLock);
        [super setName:@"Throttle"];
    }
    return self;
}

- (void)next:(id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    EZR_SCOPELOCK(_sourceLock);
    
    if (_throttleSource) {
        dispatch_source_cancel(_throttleSource);
        _throttleSource = nil;
    }
    
    _throttleSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_throttleSource, dispatch_time(DISPATCH_TIME_NOW, _throttleInterval * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0.005);
    
    @ezr_weakify(self)
    dispatch_source_set_event_handler(_throttleSource, ^{
        @ezr_strongify(self)
        if (!self) {
            return ;
        }
        EZR_SCOPELOCK(self->_sourceLock);
        [self _superNext:value from:senderList context:context];
        
        dispatch_source_cancel(self->_throttleSource);
        self->_throttleSource = nil;
    });
    
    dispatch_resume(_throttleSource);
}

- (void)_superNext:(id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    [super next:value from:senderList context:context];
}

@end
