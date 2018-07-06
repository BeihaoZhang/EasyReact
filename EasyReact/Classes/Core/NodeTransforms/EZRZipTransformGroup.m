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
#import "EZRZipTransformGroup.h"
#import "EZRZipTransform.h"
#import "EZREmpty.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZRMetaMacros.h"

@implementation EZRZipTransformGroup {
    EZSWeakArray<EZRZipTransform *> *_transforms;
    NSUInteger _transformsCount;
}

- (instancetype)initWithTransforms:(NSArray<EZRZipTransform *> *)transforms {
    NSParameterAssert(transforms);
    if (self = [super init]) {
        _transformsCount = transforms.count;
        _transforms = [[EZSWeakArray alloc] initWithNSArray:transforms];
        [EZS_SequenceWithType(EZRZipTransform *, transforms) forEach:^(EZRZipTransform * _Nonnull item) {
            item.group = self;
        }];
    }
    return self;
}

- (id)nextValue {
    if (_transforms.count != _transformsCount) {
        return EZREmpty.empty;
    }
    
    BOOL (^queueHasNotValue)(EZSQueue * _Nonnull item) = ^BOOL (EZSQueue * _Nonnull item) {
        return item.isEmpty || item.front == EZREmpty.empty ;
    };
    EZSequence<EZSQueue *> *seq = [EZS_Sequence(_transforms) map:EZS_propertyWith(EZS_KeyPath(EZRZipTransform, nextQueue))];
    if (![seq any:queueHasNotValue]) {
        return [[seq map:^id (EZSQueue * item) {
            id front = [item dequeue];
            return front ?: NSNull.null;
        }] as:EZTupleBase.class];
    }
    return EZREmpty.empty;
}

- (void)removeTransform:(EZRZipTransform *)transform {
    [_transforms removeObject:transform];
}

@end
