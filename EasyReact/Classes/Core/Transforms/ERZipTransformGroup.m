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

#import <ZTuple/ZTuple.h>
#import "ERZipTransformGroup.h"
#import "NSArray+ER_Extension.h"
#import "ERZipTransform.h"
#import "EREmpty.h"
#import "ERMetaMacrosPrivate.h"
#import "ERQueue.h"
#import "ERWeakReference.h"
#import "NSArray+ER_Extension.h"
#import "ERMetaMacros.h"

@implementation ERZipTransformGroup {
    NSMutableArray<ERWeakReference<ERZipTransform *> *> *_transforms;
    ER_LOCK_DEF(_transformsLock);
    NSUInteger _transformsCount;
}

- (instancetype)initWithTransforms:(NSArray<ERZipTransform *> *)transforms {
    if (self = [super init]) {
        ER_LOCK_INIT(_transformsLock);
        _transformsCount = transforms.count;
        _transforms = [transforms er_map:^id _Nonnull(ERZipTransform * _Nonnull value) {
            value.group = self;
            return [[ERWeakReference alloc] initWithValue:value];
        }].mutableCopy;
    }
    return self;
}

- (NSArray<ERZipTransform *> *)transforms {
    ER_SCOPELOCK(_transformsLock);
    return [_transforms valueForKey:_ER_KeyPath(ERWeakReference.new, value)];
}

- (id)nextValue {
    NSArray<ERZipTransform *> *transforms = self.transforms;
    
    if (transforms.count != _transformsCount) {
        return EREmpty.empty;
    }
    
    ZTupleBase *tuple = [ZTupleBase tupleWithCount:_transformsCount];
    __block BOOL empty = NO;
    [transforms er_foreachWithIndexAndStop:^(ERZipTransform * _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
        id front = obj.nextQueue.front;
        if (front == EREmpty.empty || obj.nextQueue.empty) {
            *stop = YES;
            empty = YES;
        } else {
            tuple[index] = front;
        }
    }];
    if (!empty) {
        [transforms er_foreach:^(ERZipTransform * _Nonnull obj) {
            [obj.nextQueue dequeue];
        }];
    }
    return empty ? EREmpty.empty : tuple;
}

- (void)removeTransform:(id)transform {
    ER_SCOPELOCK(_transformsLock);
    [[_transforms er_select:^BOOL(ERWeakReference<ERZipTransform *> * _Nonnull value) {
        return value.value == transform;
    }] er_foreach:^(ERWeakReference<ERZipTransform *> * _Nonnull value) {
        [_transforms removeObject:value];
    }];
}

@end
