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

@interface EZRZipTransformGroup ()

@property (atomic, strong) NSArray<EZSWeakReference<EZRZipTransform *> *> *transforms;

@end

@implementation EZRZipTransformGroup {
    NSUInteger _transformsCount;
}

- (instancetype)initWithTransforms:(NSArray<EZRZipTransform *> *)transforms {
    NSParameterAssert(transforms);
    if (self = [super init]) {
        _transformsCount = transforms.count;
        _transforms = [[EZS_Sequence(transforms) map:^EZSWeakReference<EZRZipTransform *> * _Nonnull(EZRZipTransform * _Nonnull item) {
            item.group = self;
            return [EZSWeakReference reference:item];
        }] as:NSMutableArray.class]; // Never chang, so converting to mutable array is faster.
    }
    return self;
}

- (id)nextValue {
    if (self.transforms.count != _transformsCount) {
        return EZREmpty.empty;
    }
    
    EZTupleBase *tuple = [EZTupleBase tupleWithCount:_transformsCount];
    NSUInteger index = 0;
    for (EZSWeakReference<EZRZipTransform *> * _Nonnull obj in self.transforms) {
        EZRZipTransform *transform = obj.reference;
        if EZR_Unlikely(obj.reference == nil) {
            self.transforms = nil;
            return EZREmpty.empty;
        }
        EZSQueue *queue = transform.nextQueue;
        if (queue.empty) {
            return EZREmpty.empty;
        }
        id front = queue.front;
        if EZR_Unlikely(front == EZREmpty.empty) {
            return EZREmpty.empty;
        } else {
            tuple[index++] = front;
        }
    }
    for (EZSWeakReference<EZRZipTransform *> * _Nonnull obj in self.transforms) {
        [obj.reference.nextQueue dequeue];
    }
    return tuple;
}

- (void)removeTransform:(EZRZipTransform *)transform {
    self.transforms = nil;
}

@end
