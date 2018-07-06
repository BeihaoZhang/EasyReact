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

#import "EZRBlockCancelable.h"

@implementation EZRBlockCancelable {
    EZRCancelBlockType _block;
}

- (instancetype)initWithBlock:(EZRCancelBlockType)block {
    NSParameterAssert(block);
    if (self = [super init]) {
        _block = [block copy];
    }
    return self;
}

- (void)cancel {
    EZRCancelBlockType block = nil;
    @synchronized(self) {
        block = _block;
        _block = nil;
    }
    if (block) {
        block();
    }
}

@end
