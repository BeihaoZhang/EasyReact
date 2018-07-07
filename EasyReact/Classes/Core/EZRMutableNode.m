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


#import "EZRMutableNode.h"
#import "EZRSenderList.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRMutableNode+ProjectPrivate.h"
#import "EZRListenContext+ProjectPrivate.h"
#import "EZRListenEdge.h"
#import "EZRTransformEdge.h"
#import "EZREmpty.h"
#import "EZRMetaMacros.h"
#import "EZRBlockCancelable.h"
#import "EZRTransform.h"
#import "EZRNextReceiver.h"
#import <objc/runtime.h>

NSString *EZRExceptionReason_CannotModifyEZRNode = @"EZRExceptionReason_CannotModifyEZRNode";

static inline EZSFliterBlock _EZR_PropertyExists(NSString *keyPath) {
    return ^BOOL (id item) {
        id property = [item valueForKeyPath:keyPath];
        return !!property;
    };
}

@interface EZRMutableNode () <EZRNextReceiver>

@end

@implementation EZRMutableNode

@synthesize value = _value, name = _name, mutable = _mutable;

#pragma mark initializer

- (instancetype)initDirectly {
    if (self = [self init]) {
    }
    return self;
}

- (instancetype)init {
    if (self = [self initWithValue:[EZREmpty empty] mutable:YES]) {
    }
    return self;
}

- (instancetype)initWithValue:(id)value {
    if (self = [self initWithValue:value mutable:YES]) {
    }
    return self;
}

- (instancetype)initWithValue:(id)value mutable:(BOOL)isMutable {
    if (self = [super initDirectly]) {
        _value = value;
        _mutable = isMutable;
        _privateListenEdges = @[];
        _privateUpstreamTransforms = @[];
        _privateDownstreamTransforms = @[];
        EZR_LOCK_INIT(_valueLock);
        EZR_LOCK_INIT(_upstreamLock);
        EZR_LOCK_INIT(_downstreamLock);
        EZR_LOCK_INIT(_listenEdgeLock);
    }
    return self;
}

- (instancetype)named:(NSString *)name {
    return [self namedWithFormat:name];
}

- (instancetype)namedWithFormat:(NSString *)format, ... {
    NSCParameterAssert(format != nil);
    
    va_list args;
    va_start(args, format);
    
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    _name = str;
    return self;
}

+ (instancetype)value:(id)value {
    return [[EZRMutableNode alloc] initWithValue:value];
}

- (void)setValue:(id)value {
    [self setValue:value context:nil];
}

- (void)setValue:(id)value context:(nullable id)context {
    if EZR_LikelyNO(!self.isMutable) {
        EZR_THROW(EZRNodeExceptionName, EZRExceptionReason_CannotModifyEZRNode, nil);
    }
    [self next:value from:[EZRSenderList new] context:context];
}

- (void)clean {
    self.value = [EZREmpty empty];
}

#pragma mark value's setter and getter

- (void)next:(nullable id)value from:(EZRSenderList *)senderList context:(nullable id)context {
    {
        EZR_SCOPELOCK(_valueLock);
        _value = value;
    }
    
    if EZR_LikelyNO(value == EZREmpty.empty) {
        return;
    }

    EZRSenderList *newQueue = [senderList appendNewSender:self];
    
    for (EZSWeakReference<id<EZRListenEdge>> *item in self.privateListenEdges) {
        [item.reference next:value from:newQueue context:context];
    }
    
    for (EZSWeakReference<id<EZRTransformEdge>> *reference in self.privateDownstreamTransforms) {
        id<EZRTransformEdge> item = reference.reference;
        if EZR_LikelyYES(![senderList contains:item.to]) {
            [item next:value from:newQueue context:context];
        }
    }
}

- (id)value {
    EZR_SCOPELOCK(_valueLock);
    return _value;
}

- (BOOL)isEmpty {
    return self.value == EZREmpty.empty;
}

#pragma mark listener

- (NSArray<id<EZRListenEdge>> *)listenEdges {
    return [[EZS_Sequence(self.privateListenEdges) map:EZS_valueForKeypath(@"reference")] as:NSArray.class];
}

- (BOOL)hasListener {
    return [EZS_Sequence(self.privateListenEdges) any:_EZR_PropertyExists(@"reference.to")];
}

- (void)addListenEdge:(id<EZRListenEdge>)listenEdge {
    NSParameterAssert(listenEdge);
    if EZR_LikelyNO(!listenEdge) {
        return ;
    }
    for (EZSWeakReference<id<EZRListenEdge>> * _Nonnull item in self.privateListenEdges) {
        if EZR_LikelyNO(item.reference == listenEdge) {
            return;
        }
    }
    EZR_SCOPELOCK(_listenEdgeLock);
    self.privateListenEdges = [self.privateListenEdges arrayByAddingObject:[EZSWeakReference reference:listenEdge]];
}

- (void)removeListenEdge:(id<EZRListenEdge>)listenEdge {
    NSParameterAssert(listenEdge);
    EZR_SCOPELOCK(_listenEdgeLock);
    NSUInteger removeIndex = 0;
    for (EZSWeakReference<id<EZRListenEdge>> *reference in self.privateListenEdges) {
        if (reference.reference == listenEdge) {
            NSMutableArray *listenEdges = [self.privateListenEdges mutableCopy];
            [listenEdges removeObjectAtIndex:removeIndex];
            self.privateListenEdges = listenEdges;
            return;
        }
        removeIndex++;
    }
}

#pragma mark downstream

- (NSArray<EZRNode *> *)downstreamNodes {
    return [[[EZS_Sequence(self.privateDownstreamTransforms) select:_EZR_PropertyExists(@"reference.to")]
             map:EZS_valueForKeypath(@"reference.to")]
            as:NSArray.class];
}

- (NSArray<id<EZRTransformEdge>> *)downstreamTransforms {
    return [[EZS_Sequence(self.privateDownstreamTransforms) map:EZS_valueForKeypath(@"reference")] as:NSArray.class];
}

- (BOOL)hasDownstreamNode {
    return [EZS_Sequence(self.privateDownstreamTransforms) any:_EZR_PropertyExists(@"reference.to")];
}

- (id<EZRCancelable>)linkTo:(EZRMutableNode *)node transform:(id<EZRTransformEdge>)transform {
    if (!node || node == self) {
        return nil;
    }
    NSParameterAssert(transform);
    if (!transform) {
        return nil;
    }
    NSAssert(transform.from == nil && transform.to == nil , @"this transform already used ");
    if (transform.from != nil && transform.to != nil) {
        return nil;
    }
    transform.from = node;
    transform.to = self;
    @ezr_weakify(transform);
    return [[EZRBlockCancelable alloc] initWithBlock:^{
        @ezr_strongify(transform);
        transform.from = nil;
        transform.to = nil;
    }];
}

- (id<EZRCancelable>)linkTo:(EZRNode *)node {
    return [self linkTo:node transform:EZRTransform.new];
}

- (void)removeDownstreamNode:(EZRNode *)downstream {
    NSParameterAssert(downstream);
    [EZS_Sequence([self downstreamTransformsToNode:downstream]) forEach:^(id<EZRTransformEdge>  _Nonnull value) {
        value.from = nil;
        value.to = nil;
    }];
}

- (NSArray<id<EZRTransformEdge>> *)upstreamTransformsFromNode:(EZRNode *)from {
    return [[EZS_Sequence(self.privateUpstreamTransforms) select:^BOOL(id<EZRTransformEdge>  _Nonnull value) {
        return value.from == from;
    }] as:NSArray.class];
}

- (NSArray<id<EZRTransformEdge>> *)downstreamTransformsToNode:(EZRNode *)to {
    return [[[EZS_Sequence(self.privateDownstreamTransforms) select:^BOOL(EZSWeakReference<id<EZRTransformEdge>> * _Nonnull value) {
        return value.reference.to == to;
    }] map:EZS_valueForKeypath(@"reference")]
            as:NSArray.class];
}

- (void)removeTransform:(id<EZRTransformEdge>)transform {
    NSParameterAssert(transform);
    transform.from = nil;
    transform.to = nil;
}

- (void)removeDownstreamNodes {
    [EZS_Sequence(self.privateDownstreamTransforms) forEach:^(EZSWeakReference<id<EZRTransformEdge>> * _Nonnull value) {
        [self removeTransform:value.reference];
    }];
}

- (void)removeUpstreamNode:(EZRNode *)upstream {
    NSParameterAssert(upstream);
    [upstream removeDownstreamNode:self];
}

- (void)removeUpstreamNodes {
    [EZS_Sequence(self.privateUpstreamTransforms) forEach:^(id<EZRTransformEdge>  _Nonnull value) {
        [self removeTransform:value];
    }];
}

#pragma mark upstream

- (NSArray<EZRNode *> *)upstreamNodes {
    return [[[EZS_Sequence(self.privateUpstreamTransforms) select:_EZR_PropertyExists(EZS_KeyPath(EZRTransform, from))]
             map:EZS_valueForKeypath(EZS_KeyPath(EZRTransform, from))]
            as:NSArray.class];
}

- (NSArray<id<EZRTransformEdge>> *)upstreamTransforms {
    return self.privateUpstreamTransforms;
}

- (BOOL)hasUpstreamNode {
    return [EZS_Sequence(self.privateUpstreamTransforms) any:_EZR_PropertyExists(EZS_KeyPath(EZRTransform, from))];
}

#pragma mark - operator data structure

- (id<EZRNextReceiver>)addUpstreamTransformData:(id<EZRTransformEdge>)transform {
    NSParameterAssert(transform);
    if (!transform) {
        return nil;
    }
    BOOL exists = [EZS_Sequence(self.privateUpstreamTransforms) any:^BOOL(id<EZRTransformEdge> _Nonnull item) {
        return item == transform;
    }];
    if (!exists) {
        EZR_SCOPELOCK(_upstreamLock);
        self.privateUpstreamTransforms = [self.privateUpstreamTransforms arrayByAddingObject:transform];
    }

    return self;
}

- (void)addDownstreamTransformData:(id<EZRTransformEdge>)transform {
    NSParameterAssert(transform);
    if (!transform) {
        return ;
    }
    BOOL exists = [EZS_Sequence(self.privateDownstreamTransforms) any:^BOOL(EZSWeakReference<id<EZRTransformEdge>> * _Nonnull item) {
        return item.reference == transform;
    }];
    if (!exists) {
        EZR_SCOPELOCK(_downstreamLock);
        self.privateDownstreamTransforms = [self.privateDownstreamTransforms arrayByAddingObject:[EZSWeakReference reference:transform]];
    }
}

- (void)removeUpstreamTransformData:(id<EZRTransformEdge>)transform {
    NSParameterAssert(transform);
    EZR_SCOPELOCK(_upstreamLock);
    NSMutableArray *upstreamTransforms = [self.privateUpstreamTransforms mutableCopy];
    [upstreamTransforms removeObject:transform];
    self.privateUpstreamTransforms = upstreamTransforms;
}

- (void)removeDownstreamTransformData:(id<EZRTransformEdge>)transform {
    NSParameterAssert(transform);
    EZR_SCOPELOCK(_downstreamLock);
    NSUInteger removeIndex = 0;
    for (EZSWeakReference<id<EZRTransformEdge>> *reference in self.privateDownstreamTransforms) {
        if (reference.reference == transform) {
            NSMutableArray *downstreamTransforms = [self.privateDownstreamTransforms mutableCopy];
            [downstreamTransforms removeObjectAtIndex:removeIndex];
            self.privateDownstreamTransforms = downstreamTransforms;
            return;
        }
        removeIndex++;
    }
}

#pragma mark others

- (NSString *)description {
    return [NSString stringWithFormat:@"EZRNode(named:%@ value:%@)", self.name ?: @"undefined", self.value];
}

@end
