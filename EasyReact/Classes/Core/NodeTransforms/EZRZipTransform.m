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

#import "EZRZipTransform.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZRZipTransformGroup.h"
#import "EZRSenderList.h"
#import "EZREmpty.h"

@implementation EZRZipTransform

- (instancetype)init {
    if (self = [super init]) {
        _nextQueue = [EZSQueue new];
        [super setName:@"Zip"];
    }
    return self;
}

- (void)next:(id)value from:(EZRSenderList *)senderList context:(nullable id)context{
    [_nextQueue enqueue:value];
    
    if (!self.group) {
        return;
    }
    
    id nextValue = [self.group nextValue];
    if (nextValue != EZREmpty.empty) {
        [super next:nextValue from:senderList context:context];
    }
}

- (void)setFrom:(EZRNode *)from {
    [super setFrom:from];
    [self breakLinkingIfNeeded];
}

- (void)setTo:(EZRNode *)to {
    [super setTo:to];
    [self breakLinkingIfNeeded];
}

- (void)breakLinkingIfNeeded {
    if (self.from == nil && self.to == nil) {
        [self.group removeTransform:self];
    }
}

@end
