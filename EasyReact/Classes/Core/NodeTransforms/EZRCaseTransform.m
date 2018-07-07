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

#import "EZRCaseTransform.h"

@interface EZRCaseTransform ()

@property (atomic, strong) EZRNode *lastNode;
@property (atomic, strong) id<EZRCancelable> cancelable;

@end

@implementation EZRCaseTransform {
    id<NSCopying> _key;
}

- (instancetype)initWithCaseKey:(id<NSCopying>)key {
    if (self = [super init]) {
        _key = key;
        [super setName:@"Case"];
    }
    return self;
}

static BOOL EZR_instanceEqual(id left, id right) {
    if (left == right) { return YES; }
    if ([left respondsToSelector:@selector(isEqual:)]) {
        return [left isEqual:right];
    }
    if ([right respondsToSelector:@selector(isEqual:)]) {
        return [right isEqual:left];
    }
    return NO;
}

- (void)next:(EZTuple2<id<NSCopying>, EZRNode *> *)next from:(EZRSenderList *)senderList context:(id)context {
    BOOL canCase = EZS_isKindOf(EZTuple2)(next) && [[(id)next.first class] conformsToProtocol:@protocol(NSCopying)] && EZS_isKindOf(EZRNode)(next.second);
    if (!canCase) {
        EZR_THROW(EZRNodeExceptionName, EZRExceptionReason_CasedNodeMustGenerateBySwitchOrSwitchMapOperation, nil);
    }
    id nextKey = next.first;
    nextKey = EZR_instanceEqual(nextKey, NSNull.null) ? nil : nextKey;
    
    if (EZR_instanceEqual(nextKey, _key)) {
        if (next.second == self.lastNode) {
            return ;
        }
        [self.cancelable cancel];
        self.cancelable = nil;
        self.lastNode = next.second;
        @ezr_weakify(self)
        self.cancelable = [[next.second listenedBy:self] withSenderListAndContextBlock:^(id  _Nullable value, EZRSenderList * _Nonnull insideSenderList, id  _Nullable insideContext) {
           @ezr_strongify(self)
            if (self.cancelable) {
                [self _superNext:value from:insideSenderList context:insideContext];
            }
        }];
        if (!next.second.isEmpty) {
            [super next:next.second.value from:[senderList appendNewSender:next.second] context:context];
        }
    }
}

- (void)_superNext:(id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    [super next:value from:senderList context:context];
}

@end
