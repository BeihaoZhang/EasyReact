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

#import "ERCombineTransform.h"
#import "EREmpty.h"
#import "ERCombineTransformGroup.h"
#import "ERNode+ProjectPrivate.h"
#import "NSArray+ER_Extension.h"
#import <ZTuple/ZTuple.h>

@interface ERCombineTransform ()

@property (atomic, readwrite, strong) id lastValue;

@end

@implementation ERCombineTransform

- (instancetype)init {
    if (self = [super init]) {
        _lastValue = EREmpty.empty;
        [super setName:@"Combine"];
    }
    return self;
}

- (void)next:(id)value from:(ERSenderList *)senderList {
    self.lastValue = value;
    
    if (!self.group) {
        return;
    }
    
    id nextValue = [self.group nextValue];
    if (nextValue != EREmpty.empty) {
        [self.to next:nextValue from:senderList];
    }
}

- (void)breakLinking {
    [self.group removeTransform:self];
    [super breakLinking];
}

@end

