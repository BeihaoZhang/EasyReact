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

#import "EZRListen.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRSenderList.h"

@implementation EZRListen {
    EZRNode *_from;
    __weak EZRNode *_to;
    EZR_LOCK_DEF(_fromLock);
    EZR_LOCK_DEF(_toLock);
}

@synthesize name = _name;

- (instancetype)init {
    if (self = [super init]) {
        _name = @"Listen";
        EZR_LOCK_INIT(_fromLock);
        EZR_LOCK_INIT(_toLock);
    }
    return self;
}


- (void)next:(id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    
}

- (EZRNode *)to {
    EZR_SCOPELOCK(_toLock);
    return _to;
}

- (EZRNode *)from {
    EZR_SCOPELOCK(_fromLock);
    return _from;
}

- (void)setTo:(EZRNode *)to {
    {
        EZR_SCOPELOCK(_toLock);
        _to = to;
    }
    [self pushValueIfNeeded];
}

- (void)setFrom:(EZRNode *)from {
    {
        EZR_SCOPELOCK(_fromLock);
        EZRNode *lastFrom = _from;
        if (lastFrom) {
            [lastFrom removeListenEdge:self];
            _from = nil;
        }
        if (!from) {
            return;
        }
        _from = from;
        [_from addListenEdge:self];
    }
    [self pushValueIfNeeded];
}

- (void)pushValueIfNeeded {
    if (self.from && self.to && (!self.from.isEmpty)) {
        [self next:self.from.value from:[EZRSenderList senderListWithSender:self.from] context:nil];
    }
}

- (void)dealloc {
    if (_from) {
        [_from removeListenEdge:self];
    }   
}

@end
