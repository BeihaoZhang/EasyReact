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

#import "NSArray+ER_Extension.h"
#import "ERUsefulBlocks.h"

@implementation NSArray (ER_Extension)

- (NSArray *)er_map:(id (^)(id value))mapBlock {
    NSParameterAssert(mapBlock);
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:self.count];
    for (id value in self) {
        [returnArray addObject:mapBlock(value)];
    }
    return [returnArray copy];
}

- (NSArray *)er_mapWithIndex:(id (^)(id value, NSUInteger index))mapBlock {
    NSParameterAssert(mapBlock);
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:self.count];
    for (NSUInteger i = 0; i < self.count; ++i) {
        [returnArray addObject:mapBlock(self[i], i)];
    }
    return [returnArray copy];
}

- (void)er_foreach:(void (^)(id value))eachBlock {
    NSParameterAssert(eachBlock);
    for (id value in self) {
        eachBlock(value);
    }
}

- (void)er_foreachWithIndex:(void (^)(id value, NSUInteger index))eachBlock {
    NSParameterAssert(eachBlock);
    for (NSUInteger i = 0; i < self.count; ++i) {
        eachBlock(self[i], i);
    }
}

- (void)er_foreachWithIndexAndStop:(void (^)(id value, NSUInteger index, BOOL *stop))eachBlock {
    NSParameterAssert(eachBlock);
    [self enumerateObjectsUsingBlock:(id)eachBlock];
}

- (BOOL)er_any:(BOOL (^)(id value))checkBlock {
    if (checkBlock == nil) return NO;
    __block BOOL returnValue = NO;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (checkBlock(obj)) {
            *stop = YES;
            returnValue = YES;
        }
    }];
    
    return returnValue;
}

- (NSArray *)er_select:(BOOL (^)(id value))checkBlock {
    NSParameterAssert(checkBlock);
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:self.count];
    for (id value in self) {
        if (checkBlock(value)) {
            [returnArray addObject:value];
        }
    }
    return [returnArray copy];
}

- (NSArray *)er_reject:(BOOL (^)(id value))checkBlock {
    NSParameterAssert(checkBlock);
    return [self er_select:er_not(checkBlock)];
}

- (id)er_reduce:(id _Nullable (^)(id _Nullable, id _Nonnull))reduceBlock {
    NSParameterAssert(reduceBlock);
    NSEnumerator *enumerator = self.objectEnumerator;
    id result = enumerator.nextObject;
    for (id value in enumerator) {
        result = reduceBlock(result, value);
    }
    return result;
}

- (id)er_reduceWithStartValue:(id)startValue operation:(id _Nonnull (^)(id _Nullable, id _Nonnull))reduceBlock {
    NSParameterAssert(reduceBlock);
    id result = startValue;
    for (id value in self) {
        result = reduceBlock(result, value);
    }
    return result;
}

- (NSDictionary *)er_groupBy:(id (^)(id value))groupBlock {
    NSParameterAssert(groupBlock);
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
    for (id value in self) {
        id key = groupBlock(value);
        if (!mutableDic[key]) {
            mutableDic[key] = [NSMutableArray array];
        }
        [mutableDic[key] addObject:value];
    }
    for (id key in mutableDic.allKeys) {
        NSMutableArray *items = mutableDic[key];
        mutableDic[key] = [items copy];
    }
    return [mutableDic copy];
}

+ (NSArray<NSArray *> *)er_zip:(NSArray<NSArray *> *)zippedArrays {
    NSMutableArray *result = [NSMutableArray array];
    NSArray<NSEnumerator *> *enumerators = [zippedArrays er_map:^id _Nonnull(NSArray * _Nonnull value) {
        return value.objectEnumerator;
    }];
    NSObject *endMarker = NSObject.new;
    for (;;) {
        NSArray *values = [enumerators er_map:^id _Nonnull(NSEnumerator * _Nonnull value) {
            id next = value.nextObject;
            return next ?: endMarker;
        }];
        if ([values er_any:^BOOL(id  _Nonnull value) { return value == endMarker; }]) {
            break;
        }
        [result addObject:values];
    }
    return [result copy];
}

@end
