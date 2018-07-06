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

#import <EasyTuple/EasyTuple.h>
#import <EasySequence/EasySequence.h>
#import "EZRCombineTransformGroup.h"
#import "EZRCombineTransform.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZREmpty.h"
#import "EZRMetaMacros.h"

@implementation EZRCombineTransformGroup {
    NSUInteger _transformsCount;
    EZSWeakArray<EZRCombineTransform *> *_transforms;
}

- (instancetype)initWithTransforms:(NSArray<EZRCombineTransform *> *)transforms {
    NSParameterAssert(transforms);
    if (self = [super init]) {
        _transformsCount = transforms.count;
        _transforms = [[EZSWeakArray alloc] initWithNSArray:transforms];
        [EZS_SequenceWithType(EZRCombineTransform *, transforms) forEach:^(EZRCombineTransform * _Nonnull item) {
            item.group = self;
        }];
    }
    return self;
}

- (id)nextValue {
    if (_transforms.count != _transformsCount) {
        return EZREmpty.empty;
    }
    EZSequence *seq = [EZS_Sequence(_transforms) map:^id _Nonnull(EZRCombineTransform *item) {
        return item.lastValue ? item.lastValue : NSNull.null;
    }];
    if ([seq any:EZS_isEqual(EZREmpty.empty)]) {
        return EZREmpty.empty;
    }
    return [seq as:EZTupleBase.class];
}

- (void)removeTransform:(EZRCombineTransform *)transform { 
    [_transforms removeObject:transform];
}

@end
