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

#import "EZRSwitchMapTransform.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZRMutableNode.h"

@implementation EZRSwitchMapTransform {
    @private
    EZR_LOCK_DEF(_switchDictionaryLock);
    NSMutableDictionary *_switchDictionary;
    EZRSwitchMapBlock _switchMapBlock;
}

- (instancetype)initWithSwitchMapBlock:(EZRSwitchMapBlock)block {
    NSParameterAssert(block);
    if (self = [super init]) {
        EZR_LOCK_INIT(_switchDictionaryLock);
        _switchDictionary = [NSMutableDictionary dictionary];
        _switchMapBlock = block;
        [super setName:@"SwitchMap"];
    }
    return self;
}

- (void)setFrom:(EZRNode *)from {
    if (self.from != from) {
        EZR_SCOPELOCK(_switchDictionaryLock);
        [_switchDictionary removeAllObjects];
    }
    [super setFrom:from];
}

- (void)next:(id)value from:(EZRSenderList *)senderList context:(id)context {
    if (_switchMapBlock) {
        EZTuple2<id<NSCopying>, id> *mappedResult = _switchMapBlock(value);
        EZTupleUnpack(id<NSCopying> key, id mappedValue, EZT_FromVar(mappedResult));
        if (key == nil) {
            key = [NSNull null];
        }
        EZRMutableNode *valueNode = nil;
        {
            EZR_SCOPELOCK(_switchDictionaryLock);
            valueNode = _switchDictionary[key];
            if (valueNode == nil) {
                valueNode = [EZRMutableNode new];
                _switchDictionary[key] = valueNode;
            }
        }
        [valueNode setValue:mappedValue context:context];
        [super next:EZTuple(key, valueNode) from:senderList context:context];
    }
}

@end
