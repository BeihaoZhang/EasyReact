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

#import <EasyFoundation/EasyFoundation.h>
#import "EZRCombineTransformGroup.h"
#import "EZRCombineTransform.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZREmpty.h"
#import "EZRMetaMacros.h"

@interface EZRCombineTransformGroup ()

@property (atomic, strong) NSArray<EZSWeakReference<EZRCombineTransform *> *> *transforms;

@end

@implementation EZRCombineTransformGroup {
    NSUInteger _transformsCount;
}

- (instancetype)initWithTransforms:(NSArray<EZRCombineTransform *> *)transforms {
    NSParameterAssert(transforms);
    if (self = [super init]) {
        _transformsCount = transforms.count;
        _transforms = [[EZS_Sequence(transforms) map:^EZSWeakReference<EZRCombineTransform *> * _Nonnull(EZRCombineTransform * _Nonnull item) {
            item.group = self;
            return [EZSWeakReference reference:item];
        }] as:NSMutableArray.class]; // Never changed, so converting to mutable array is faster.
    }
    return self;
}

- (id)nextValue {
    if (self.transforms.count != _transformsCount) {
        return EZREmpty.empty;
    }
    
    EZTupleBase *tuple = [EZTupleBase tupleWithCount:_transformsCount];
    NSUInteger index = 0;
    for (EZSWeakReference<EZRCombineTransform *> * _Nonnull obj in self.transforms) {
        EZRCombineTransform *transform = obj.reference;
        if (transform == nil) {
            self.transforms = nil;
            return EZREmpty.empty;
        }
        id last = transform.lastValue;
        if (last == EZREmpty.empty) {
            return EZREmpty.empty;
        } else {
            tuple[index++] = last;
        }
    }
    return tuple;
}

- (void)removeTransform:(EZRCombineTransform *)transform { 
    self.transforms = nil;
}

@end
