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

#import "EZRNode+Operation.h"
#import "EZRDeliverTransform.h"
#import "EZRMapTransform.h"
#import "EZRFilteredTransform.h"
#import "EZRDistinctTransform.h"
#import "EZRFlattenTransform.h"
#import "EZRThrottleTransform.h"
#import "EZRBlockCancelable.h"
#import "EZRZipTransform.h"
#import "EZRZipTransformGroup.h"
#import "EZRDelayTransform.h"
#import "EZRCombineTransform.h"
#import "EZRCombineTransformGroup.h"
#import "EZREmpty.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRSenderList.h"
#import <EasySequence/EasySequence.h>

@import ObjectiveC.runtime;

NSString *EZRExceptionReason_SyncTransformBlockAndRevertNotInverseOperations = @"The transform block and the revert block are not inverse operations";
NSString *EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode = @"The flatten block next value isnot EZRNode";
NSString *EZRExceptionReason_MapEachNextValueNotTuple = @"the mapEack Block next value isnot tuple";

@implementation EZRNode (Operation)

- (EZRNode *)fork {
    EZRNode *returnedNode = EZRNode.new;
    [returnedNode linkTo:self];
    return returnedNode;
}

- (EZRNode *)map:(EZRMapBlock)block {
    EZRNode *returnedNode = EZRNode.new;
    [returnedNode linkTo:self transform:[[EZRMapTransform alloc] initWithMapBlock:block]];
    return returnedNode;
}

- (EZRNode *)filter:(EZRFilterBlock)block {
    EZRNode *returnedNode = EZRNode.new;
    [returnedNode linkTo:self transform:[[EZRFilteredTransform alloc] initWithFilterBlock:block]];
    return returnedNode;
}

- (EZRNode *)skip:(NSUInteger)number {
    __block NSUInteger skipTimes = 0;
    return [self filter:^BOOL(id next) {
        return ++skipTimes > number;
    }];
}

- (EZRNode *)take:(NSUInteger)number {
    __block NSUInteger takeTimes = 0;
    return [self filter:^BOOL(id next) {
        return takeTimes++ < number;
    }];
}

- (EZRNode *)ignore:(id)ignoreValue {
    return [self filter:^BOOL(id  _Nullable next) {
        return !(ignoreValue == next || [ignoreValue isEqual:next]);
    }];
}

- (EZRNode *)select:(id)selectedValue {
    return [self filter:^BOOL(id  _Nullable next) {
        return selectedValue == next || [selectedValue isEqual:next];
    }];
}

- (EZRNode *)then:(void(^)(EZRNode<id> *node))thenBlock {
    NSParameterAssert(thenBlock);
    if (thenBlock) {
        thenBlock(self);
    }
    return self;
}

- (EZRNode *)mapReplace:(id)mappedValue {
    return [self map:^id _Nullable(id  _Nullable next) {
        return  mappedValue;
    }];
}

- (EZRNode*)deliverOn:(dispatch_queue_t)queue {
    NSParameterAssert(queue);
    EZRNode *returnedNode = EZRNode.new;
    [returnedNode linkTo:self transform:[[EZRDeliverTransform alloc] initWithQueue:queue]];
    return returnedNode;
}

- (EZRNode *)deliverOnMainQueue {
    EZRNode *returnedNode = EZRNode.new;
    [returnedNode linkTo:self transform:[[EZRDeliverTransform alloc] initWithQueue:dispatch_get_main_queue()]];
    return returnedNode;
}

- (EZRNode *)distinctUntilChanged {
    EZRNode *returnedNode = EZRNode.new;
    [returnedNode linkTo:self transform:EZRDistinctTransform.new];
    return returnedNode;
}

- (EZRNode *)flattenMap:(EZRFlattenMapBlock)block {
    EZRNode *returnedNode = EZRNode.new;
    EZRFlattenTransform *transform = [[EZRFlattenTransform alloc] initWithBlock:block];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (EZRNode *)flatten {
    EZRNode *returnedNode = EZRNode.new;
    EZRFlattenTransform *transform = [[EZRFlattenTransform alloc] initWithBlock:^EZRNode * _Nullable(id  _Nullable value) {
        return value;
    }];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (EZRNode *)throttleOnMainQueue:(NSTimeInterval)timeInterval {
    NSParameterAssert(timeInterval > 0);
    return [self throttle:timeInterval queue:dispatch_get_main_queue()];
}

- (EZRNode *)throttle:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue {
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(queue);
    EZRNode *returnedNode = EZRNode.new;
    EZRThrottleTransform *transform = [[EZRThrottleTransform alloc] initWithThrottle:timeInterval on:queue];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (EZRNode *)delay:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue {
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(queue);
    EZRNode *returnedNode = EZRNode.new;
    EZRDelayTransform *transform = [[EZRDelayTransform alloc] initWithDelay:timeInterval queue:queue];
    [returnedNode linkTo:self transform:transform];
    return returnedNode;
}

- (EZRNode *)delayOnMainQueue:(NSTimeInterval)timeInterval {
    NSParameterAssert(timeInterval > 0);
    return [self delay:timeInterval queue:dispatch_get_main_queue()];
}

- (id<EZRCancelable>)syncWith:(EZRNode *)othEZRNode transform:(id  _Nonnull (^)(id _Nonnull))transform revert:(id  _Nonnull (^)(id _Nonnull))revert {
    NSParameterAssert(transform);
    NSParameterAssert(revert);
    EZRMapTransform *mapTransform = [[EZRMapTransform alloc] initWithMapBlock:transform];
    EZRMapTransform *mapRevert = [[EZRMapTransform alloc] initWithMapBlock:revert];
    
    id<EZRCancelable> transformCancelable = [self linkTo:othEZRNode transform:mapTransform];
    id<EZRCancelable> revertCancelable = [othEZRNode linkTo:self transform:mapRevert];
    return [[EZRBlockCancelable alloc] initWithBlock:^{
        [transformCancelable cancel];
        [revertCancelable cancel];
    }];
}

- (id<EZRCancelable>)syncWith:(EZRNode *)othEZRNode {
    id (^idFunction)(id) = ^(id source) { return source; };
    return [self syncWith:othEZRNode transform:idFunction revert:idFunction];
}

- (EZRNode *)scanWithStart:(id)startingValue reduce:(id  _Nonnull (^)(id _Nullable, id _Nullable))reduceBlock {
    NSParameterAssert(reduceBlock);

    return [self scanWithStart:startingValue reduceWithIndex:^id _Nonnull(id  _Nullable running, id  _Nullable next, NSUInteger index) {
        if (reduceBlock) {
            return reduceBlock(running, next);
        }
        return nil;
    }];
}

- (EZRNode *)scanWithStart:(id)startingValue reduceWithIndex:(id  _Nonnull (^)(id _Nullable, id _Nullable, NSUInteger))reduceBlock {
    NSParameterAssert(reduceBlock);
    __block NSUInteger index = 0;
    __block id running = startingValue;
    return [self map:^id _Nullable(id  _Nullable next) {
        if (reduceBlock) {
            running = reduceBlock(running, next, index++);
            return running;
        }
        return nil;
    }];
}

+ (EZRNode *)merge:(NSArray<EZRNode *> *)nodes {
    NSParameterAssert(nodes);
    EZRNode *returnedNode = EZRNode.new;
    [EZS_Sequence(nodes) forEach:^(EZRNode * _Nonnull value) {
        [returnedNode linkTo:value];
    }];
    return returnedNode;
}

+ (EZRNode<__kindof EZTupleBase *> *)zip:(NSArray<EZRNode *> *)nodes {
    NSParameterAssert(nodes);
    EZRNode *returnedNode = EZRNode.new;
    
    NSArray<EZRZipTransform *> *zipTransforms = [[EZS_Sequence(nodes) map:^id _Nonnull(EZRNode * _Nonnull value) {
        EZRZipTransform *transform = [EZRZipTransform new];
        [returnedNode linkTo:value transform:transform];
        return transform;
    }] as:NSArray.class] ;
    EZRZipTransformGroup *group = [[EZRZipTransformGroup alloc] initWithTransforms:zipTransforms];
    
    id nextValue = [group nextValue];
    if (nextValue != EZREmpty.empty) {
        EZRSenderList *senderList = [EZRSenderList new];
        [EZS_Sequence(nodes) forEach:^(id  _Nonnull item) {
            [senderList appendSender:item];
        }];
        [returnedNode next:nextValue from:senderList context:NULL];
    }
    
    return returnedNode;
}

+ (EZRNode<__kindof EZTupleBase *> *)combine:(NSArray<EZRNode *> *)nodes {
    NSParameterAssert(nodes);
    EZRNode *returnedNode = EZRNode.new;
    
    NSArray<EZRCombineTransform *> *combineTransforms = [[EZS_Sequence(nodes) map:^id _Nonnull(EZRNode * _Nonnull node) {
        EZRCombineTransform *transform = [EZRCombineTransform new];
        [returnedNode linkTo:node transform:transform];
        return transform;
    }] as:NSArray.class];
    EZRCombineTransformGroup *group = [[EZRCombineTransformGroup alloc] initWithTransforms:combineTransforms];
    
    id nextValue = [group nextValue];
    if (nextValue != EZREmpty.empty) {
        EZRSenderList *senderList = [EZRSenderList new];
        [EZS_Sequence(nodes) forEach:^(id  _Nonnull item) {
            [senderList appendSender:item];
        }];
        [returnedNode next:nextValue from:senderList context:NULL];
    }
    
    return returnedNode;
}

@end
