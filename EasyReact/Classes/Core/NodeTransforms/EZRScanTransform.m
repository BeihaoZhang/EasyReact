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

#import "EZRScanTransform.h"
#import "EZRMetaMacrosPrivate.h"

@interface EZRScanTransform() {
    id _startValue;
    EZRReduceWithIndexBlock _reduceBlock;
    EZR_LOCK_DEF(_reduceLock);
}

@property (atomic, strong) id runningValue;
@property (atomic, assign) NSUInteger index;

@end

@implementation EZRScanTransform

- (instancetype)initWithStartValue:(id)startValue reduceBlock:(EZRReduceWithIndexBlock)block {
    NSParameterAssert(block);
    if (self = [super init]) {
        _startValue = startValue;
        _reduceBlock = [block copy];
        _index = 0;
        _runningValue = _startValue;
        EZR_LOCK_INIT(_reduceLock);
        [super setName:@"Scan"];
    }
    return self;
}

- (void)next:(id)value from:(EZRSenderList *)senderList context:(id)context {
    id from = self.from;
    BOOL canSend = ({
        EZR_SCOPELOCK(_reduceLock);
        !!_reduceBlock;
    });
    if (canSend && from == self.from) {
        self.runningValue = _reduceBlock(self.runningValue, value, self.index++);
        [super next:_runningValue from:senderList context:context];
    }
}

- (void)setFrom:(EZRNode *)from {
    if (self.from != from) {
        EZR_SCOPELOCK(_reduceLock);
        self.runningValue = _startValue;
        self.index = 0;
    }
    [super setFrom:from];
}

@end
