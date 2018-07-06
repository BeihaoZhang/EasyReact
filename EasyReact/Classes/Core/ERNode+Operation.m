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

#import "ERNode+Operation.h"
#import "ERMapTransform.h"
#import "ERFilteredTransform.h"
#import "ERDistinctTransform.h"
#import "ERFlattenTransform.h"
#import "ERThrottleTransform.h"
#import "ERBlockCancelable.h"
#import "NSArray+ER_Extension.h"
#import "ERZipTransform.h"
#import "ERZipTransformGroup.h"
#import "ERCombineTransform.h"
#import "ERCombineTransformGroup.h"
#import "EREmpty.h"
#import "ERNode+ProjectPrivate.h"
#import "ERSenderList.h"
#import "NSObject+ER_DeallocSwizzle.h"

@import ObjectiveC.runtime;

NSString *ERExceptionReason_SyncTransformBlockAndRevertNotInverseOperations = @"The transform block and the revert block are not inverse operations";
NSString *ERExceptionReason_FlattenOrFlattenMapNextValueNotERNode = @"The flatten block next value isnot ERNode";
NSString *ERExceptionReason_MapEachNextValueNotTuple = @"the mapEack Block next value isnot tuple";

@implementation ERNode (Operation)

- (ERNode *)map:(ERMapBlock)block {
    ERNode *returnedNode = ERNode.new;
    [returnedNode linkTo:self transform:[[ERMapTransform alloc] initWithMapBlock:block]];
    return returnedNode;
}

- (ERNode *)filter:(ERFilterBlock)block {
    ERNode *returnedNode = ERNode.new;
    [returnedNode linkTo:self transform:[[ERFilteredTransform alloc] initWithFilterBlock:block]];
    return returnedNode;
}

- (ERNode *)skip:(NSUInteger)number {
    __block NSUInteger skipTimes = 0;
    return [self filter:^BOOL(id next) {
        return ++skipTimes > number;
    }];
}

- (ERNode *)take:(NSUInteger)number {
    __block NSUInteger takeTimes = 0;
    return [self filter:^BOOL(id next) {
        return takeTimes++ < number;
    }];;
}

- (ERNode *)ignore:(id)ignoreValue {
    return [self filter:^BOOL(id  _Nullable next) {
        return !(ignoreValue == next || [ignoreValue isEqual: next]);
    }];
}

- (ERNode *)mapReplace:(id)mappedValue {
    return [self map:^id _Nullable(id  _Nullable next) {
        return  mappedValue;
    }];
}

- (ERNode *)distinctUntilChanged {
    ERNode *returnedNode = ERNode.new;
    [returnedNode linkTo:self transform:ERDistinctTransform.new];
    return returnedNode;
}

- (ERNode *)flattenMap:(ERFlattenMapBlock)block {
    ERNode *returnedNode = ERNode.new;
    ERFlattenTransform *transform = [[ERFlattenTransform alloc] initWithBlock:block];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (ERNode *)flatten {
    ERNode *returnedNode = ERNode.new;
    ERFlattenTransform *transform = [[ERFlattenTransform alloc] initWithBlock:^ERNode * _Nullable(id  _Nullable value) {
        return value;
    }];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (ERNode *)throttle:(NSTimeInterval)timeInterval {
    NSParameterAssert(timeInterval > 0);
    return [self throttle:timeInterval queue:dispatch_get_main_queue()];
}

- (ERNode *)throttle:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue {
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(queue);
    ERNode *returnedNode = ERNode.new;
    ERThrottleTransform *transform = [[ERThrottleTransform alloc] initWithThrottle:timeInterval on:queue];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (id<ERCancelable>)syncTo:(ERNode *)otherNode transform:(id  _Nonnull (^)(id _Nonnull))transform revert:(id  _Nonnull (^)(id _Nonnull))revert {
    NSParameterAssert(transform);
    NSParameterAssert(revert);
    ERMapTransform *mapTransform = [[ERMapTransform alloc] initWithMapBlock:transform];
    ERMapTransform *mapRevert = [[ERMapTransform alloc] initWithMapBlock:revert];
    
    id<ERCancelable> transformCancelable = [self linkTo:otherNode transform:mapTransform];
    id<ERCancelable> revertCancelable = [otherNode linkTo:self transform:mapRevert];
    return [[ERBlockCancelable alloc] initWithBlock:^{
        [transformCancelable cancel];
        [revertCancelable cancel];
    }];
}

- (id<ERCancelable>)syncTo:(ERNode *)otherNode {
    id (^idFunction)(id) = ^(id source) { return source; };
    return [self syncTo:otherNode transform:idFunction revert:idFunction];
}

+ (ERNode *)merge:(NSArray<ERNode *> *)nodes {
    NSParameterAssert(nodes);
    ERNode *returnedNode = ERNode.new;
    [nodes er_foreach:^(ERNode * _Nonnull value) {
        [returnedNode linkTo:value];
    }];
    return returnedNode;
}

+ (ERNode<__kindof ZTupleBase *> *)zip:(NSArray<ERNode *> *)nodes {
    NSParameterAssert(nodes);
    ERNode *returnedNode = ERNode.new;
    
    NSArray<ERZipTransform *> *zipTransforms = [nodes er_map:^id _Nonnull(ERNode * _Nonnull value) {
        ERZipTransform *transform = [ERZipTransform new];
        [returnedNode linkTo:value transform:transform];
        return transform;
    }];
    ERZipTransformGroup *group = [[ERZipTransformGroup alloc] initWithTransforms:zipTransforms];
    
    id nextValue = [group nextValue];
    if (nextValue != EREmpty.empty) {
        ERSenderList *senderList = [ERSenderList new];
        [senderList appendSender:nodes.lastObject];
        [returnedNode next:nextValue from:senderList];
    }
    
    return returnedNode;
}

+ (ERNode<__kindof ZTupleBase *> *)combine:(NSArray<ERNode *> *)nodes {
    NSParameterAssert(nodes);
    ERNode *returnedNode = ERNode.new;
    
    NSArray<ERCombineTransform *> *combineTransforms = [nodes er_map:^id _Nonnull(ERNode * _Nonnull node) {
        ERCombineTransform *transform = [ERCombineTransform new];
        [returnedNode linkTo:node transform:transform];
        return transform;
    }];
    ERCombineTransformGroup *group = [[ERCombineTransformGroup alloc] initWithTransforms:combineTransforms];
    
    id nextValue = [group nextValue];
    if (nextValue != EREmpty.empty) {
        ERSenderList *senderList = [ERSenderList new];
        [senderList appendSender:nodes.lastObject];
        [returnedNode next:nextValue from:senderList];
    }
    
    return returnedNode;
}

@end
