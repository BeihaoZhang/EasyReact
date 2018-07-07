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

#import "EZRFlattenTransform.h"
#import "EZRCancelable.h"
#import "EZRMetaMacros.h"
#import "EZRNode+Operation.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRListenContext.h"
#import "EZRNode+Listen.h"

@interface EZRFlattenTransform ()

@property (atomic, strong, readwrite) id<EZRCancelable> cancelable;

@end

@implementation EZRFlattenTransform {
    @private
    EZRFlattenMapBlock _block;
}

- (instancetype)initWithBlock:(EZRFlattenMapBlock)block {
    NSParameterAssert(block);
    if (self = [super init]) {
        _block = block;
        [super setName:@"Flatten"];
    }
    return self;
}

- (void)setFrom:(EZRNode *)from {
    if (self.from != from) {
        [self.cancelable cancel];
        self.cancelable = nil;
    }
    [super setFrom:from];
}

- (void)next:(id)value from:(EZRSenderList *)senderList context:(nullable id)context{
    if (!_block) {
        return;
    }
    EZRNode *node = _block(value);
    if (![node isKindOfClass:EZRNode.class]) {
        EZR_THROW(EZRNodeExceptionName, EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode, nil);
    }
    [self.cancelable cancel];
    self.cancelable = nil;

    @ezr_weakify(self)
    self.cancelable = [[node listenedBy:self] withSenderListAndContextBlock:^(id  _Nullable next, EZRSenderList * _Nonnull insideSenderList, id  _Nullable insideContext) {
        @ezr_strongify(self)
        // The first transmit is from high-order node
        // Transmits will be from current node since the second time
        if (self.cancelable) {
            [self _superNext:next from:insideSenderList context:insideContext];
        }
    }];
    if (!node.isEmpty) {
        [super next:node.value from:[senderList appendNewSender:node] context:context];
    }
}

- (void)_superNext:(id)value from:(EZRSenderList *)senderList context:(nullable id)context{
    [super next:value from:senderList context:context];
}

- (void)dealloc {
    [self.cancelable cancel];
}

@end
