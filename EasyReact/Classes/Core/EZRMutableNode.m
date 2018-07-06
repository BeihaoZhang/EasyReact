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
#import "EZRListenTransformProtocol.h"
#import "EZRNodeTransformProtocol.h"
#import "EZREmpty.h"
#import "EZRMetaMacros.h"
#import "EZRBlockCancelable.h"
#import "EZRNodeTransform.h"
#import <objc/runtime.h>

NSString *EZRExceptionReason_CannotModifyEZRNode = @"EZRExceptionReason_CannotModifyEZRNode";

static inline EZSFliterBlock _EZR_PropertyExists(NSString *keyPath) {
    return ^BOOL (id item) {
        id property = [item valueForKey:keyPath];
        return !!property;
    };
}

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
        _listenTransforms = [EZSWeakOrderedSet new];
        _upstreamTransforms = [EZSOrderedSet new];
        _downstreamTransforms = [EZSWeakOrderedSet new];
        EZR_LOCK_INIT(_valueLock);
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
    if (!self.isMutable) {
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
    
    if (value == EZREmpty.empty) {
        return;
    }

    EZRSenderList *newQueue = senderList.copy;
    [newQueue appendSender:self];

    EZSequence *canPushValueDownstreams = [EZS_Sequence(_downstreamTransforms) reject:^BOOL(id<EZRNodeTransformProtocol> item) {
        return [newQueue contains:item.to];
    }];
    [[EZS_Sequence(_listenTransforms) concat:canPushValueDownstreams] forEach:^(id<EZRNodeTransformProtocol> item) {
        [item next:value from:newQueue context:context];
    }];
}

- (id)value {
    EZR_SCOPELOCK(_valueLock);
    return _value;
}

- (BOOL)isEmpty {
    return self.value == EZREmpty.empty;
}

#pragma mark listener

- (NSArray<id<EZRListenTransformProtocol>> *)listenTransforms {
    return _listenTransforms.allObjects;
}

- (BOOL)hasListener {
    return [EZS_Sequence(_listenTransforms) any:_EZR_PropertyExists(EZS_KeyPath(EZRNodeTransform, to))];
}

- (void)addListenTransform:(id<EZRListenTransformProtocol>)listenTransform {
    NSParameterAssert(listenTransform);
    if (!listenTransform) {
        return ;
    }
    [_listenTransforms addObject:listenTransform];
}

- (void)removeListenTransform:(id<EZRListenTransformProtocol>)listenTransform {
    [_listenTransforms removeObject:listenTransform];
}

#pragma mark downstream

- (NSArray<EZRNode *> *)downstreamNodes {
    return [[[EZS_Sequence(_downstreamTransforms) select:_EZR_PropertyExists(EZS_KeyPath(EZRNodeTransform, to))]
             map:EZS_propertyWith(EZS_KeyPath(EZRNodeTransform, to))]
            as:NSArray.class];
}

- (NSArray<id<EZRNodeTransformProtocol>> *)downstreamTransforms {
    return _downstreamTransforms.allObjects;
}

- (BOOL)hasDownstreamNode {
    return [EZS_Sequence(_downstreamTransforms) any:_EZR_PropertyExists(EZS_KeyPath(EZRNodeTransform, to))];
}

- (id<EZRCancelable>)linkTo:(EZRMutableNode *)node transform:(id<EZRNodeTransformProtocol>)transform {
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
    return [self linkTo:node transform:EZRNodeTransform.new];
}

- (void)removeDownstreamNode:(EZRNode *)downstream {
    NSParameterAssert(downstream);
    [EZS_Sequence([self downstreamTransformsToNode:downstream]) forEach:^(id<EZRNodeTransformProtocol>  _Nonnull value) {
        value.from = nil;
        value.to = nil;
    }];
}

- (NSArray<id<EZRNodeTransformProtocol>> *)upstreamTransformsFromNode:(EZRNode *)from {
    return [[EZS_Sequence(self.upstreamTransforms) select:^BOOL(id<EZRNodeTransformProtocol>  _Nonnull value) {
        return value.from == from;
    }] as:NSArray.class];
}

- (NSArray<id<EZRNodeTransformProtocol>> *)downstreamTransformsToNode:(EZRNode *)to {
    return [[EZS_Sequence(self.downstreamTransforms) select:^BOOL(id<EZRNodeTransformProtocol>  _Nonnull value) {
        return value.to == to;
    }] as:NSArray.class];
}

- (void)removeTransform:(id<EZRNodeTransformProtocol>)transform {
    NSParameterAssert(transform);
    transform.from = nil;
    transform.to = nil;
}

- (void)removeDownstreamNodes {
    [EZS_Sequence(self.downstreamTransforms) forEach:^(id<EZRNodeTransformProtocol>  _Nonnull value) {
        [self removeTransform:value];
    }];
}

- (void)removeUpstreamNode:(EZRNode *)upstream {
    NSParameterAssert(upstream);
    [upstream removeDownstreamNode:self];
}

- (void)removeUpstreamNodes {
    [EZS_Sequence(self.upstreamTransforms) forEach:^(id<EZRNodeTransformProtocol>  _Nonnull value) {
        [self removeTransform:value];
    }];
}

#pragma mark upstream

- (NSArray<EZRNode *> *)upstreamNodes {
    return [[[EZS_Sequence(_upstreamTransforms) select:_EZR_PropertyExists(EZS_KeyPath(EZRNodeTransform, from))]
             map:EZS_propertyWith(EZS_KeyPath(EZRNodeTransform, from))]
            as:NSArray.class];
}

- (NSArray<id<EZRNodeTransformProtocol>> *)upstreamTransforms {
    return _upstreamTransforms.allObjects;
}

- (BOOL)hasUpstreamNode {
    return [EZS_Sequence(_upstreamTransforms) any:_EZR_PropertyExists(EZS_KeyPath(EZRNodeTransform, from))];
}

#pragma mark - operator data structure

- (void)addUpstreamTransformData:(id<EZRNodeTransformProtocol>)transform {
    [_upstreamTransforms addObject:transform];
}

- (void)addDownstreamTransformData:(id<EZRNodeTransformProtocol>)transform {
    [_downstreamTransforms addObject:transform];
}

- (void)removeUpstreamTransformData:(id<EZRNodeTransformProtocol>)transform {
    [_upstreamTransforms removeObject:transform];
}

- (void)removeDownstreamTransformData:(id<EZRNodeTransformProtocol>)transform {
    [_downstreamTransforms removeObject:transform];
}

#pragma mark others

- (NSString *)description {
    return [NSString stringWithFormat:@"EZRNode(named:%@ value:%@)", self.name ?: @"undefined", self.value];
}

@end
