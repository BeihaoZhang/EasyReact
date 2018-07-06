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

#import "ERFlattenTransform.h"
#import "ERCancelable.h"
#import "ERMetaMacros.h"
#import "ERNode+Operation.h"
#import "ERNode+ProjectPrivate.h"

@interface ERFlattenTransform()

@property (atomic, strong, readwrite) id<ERCancelable> cancelable;

@end

@implementation ERFlattenTransform {
    @private
    ERFlattenMapBlock _block;
}

- (instancetype)initWithBlock:(ERFlattenMapBlock)block {
    NSParameterAssert(block);
    if (self = [super init]) {
        _block = block;
        [super setName:@"Flatten"];
    }
    return self;
}

- (void)next:(id)value from:(ERSenderList *)senderList {
    if (!_block) {
        return;
    }
    ERNode *node = _block(value);
    if (![node isKindOfClass:ERNode.class]) {
        ER_THROW(ERNodeExceptionName, ERExceptionReason_FlattenOrFlattenMapNextValueNotERNode, nil);
    }
    [self.cancelable cancel];
    
    @er_weakify(self)
    self.cancelable = [node listen:^(id  _Nullable next) {
        @er_strongify(self)
        [self.to next:next from:senderList];
    }];
}

- (void)dealloc {
    [self.cancelable cancel];
}

@end
