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
#import "ERCombineTransformGroup.h"
#import "NSArray+ER_Extension.h"
#import "ERCombineTransform.h"
#import "ERMetaMacrosPrivate.h"
#import "EREmpty.h"
#import "ERWeakReference.h"
#import "NSArray+ER_Extension.h"
#import "ERMetaMacros.h"

@implementation ERCombineTransformGroup {
    NSMutableArray<ERWeakReference<ERCombineTransform *> *> *_transforms;
    ER_LOCK_DEF(_transformsLock);
    NSUInteger _transformsCount;
}

- (instancetype)initWithTransforms:(NSArray<ERCombineTransform *> *)transforms {
    if (self = [super init]) {
        ER_LOCK_INIT(_transformsLock);
        _transformsCount = transforms.count;
        _transforms = [transforms er_map:^id _Nonnull(ERCombineTransform * _Nonnull value) {
            value.group = self;
            return [[ERWeakReference alloc] initWithValue:value];
        }].mutableCopy;
    }
    return self;
}

- (NSArray<ERCombineTransform *> *)transforms {
    ER_SCOPELOCK(_transformsLock);
    return [_transforms valueForKey:_ER_KeyPath(ERWeakReference.new, value)];
}

- (id)nextValue {
    NSArray<ERCombineTransform *> *transforms = self.transforms;
    
    if (transforms.count != _transformsCount) {
        return EREmpty.empty;
    }
    
    ZTupleBase *tuple = [ZTupleBase tupleWithCount:_transformsCount];
    __block BOOL empty = NO;
    [transforms enumerateObjectsUsingBlock:^(ERCombineTransform * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.lastValue == EREmpty.empty) {
            *stop = YES;
            empty = YES;
        }
        tuple[idx] = obj.lastValue;
    }];
    
    return empty ? EREmpty.empty : tuple;
}

- (void)removeTransform:(id)transform { 
    ER_SCOPELOCK(_transformsLock);
    [[_transforms er_select:^BOOL(ERWeakReference<ERCombineTransform *> * _Nonnull value) {
        return value.value == transform;
    }] er_foreach:^(ERWeakReference<ERCombineTransform *> * _Nonnull value) {
        [_transforms removeObject:value];
    }];
}

@end
