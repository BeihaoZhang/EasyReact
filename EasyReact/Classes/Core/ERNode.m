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

@import ObjectiveC.message;
#import "ERNode.h"
#import "ERTransform.h"
#import "ERCancelable.h"
#import "ERBlockCancelable.h"
#import "ERBlockListener.h"
#import "ERBlockDeliveredListener.h"
#import "EREmpty.h"
#import "ERNode+ProjectPrivate.h"
#import "ERMetaMacrosPrivate.h"
#import "NSArray+ER_Extension.h"
#import "ERMetaMacros.h"
#import "ERSenderList.h"

NSString *ERNodeExceptionName = @"ERNodeException";

@implementation ERNode

#pragma mark initializer

- (instancetype)init {
    if (self = [super init]) {
        _value = EREmpty.empty;
        _listeners = [NSMutableSet set];
        _upstreamTransforms = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality];
        _downstreamTransforms = [NSMutableSet set];
        ER_LOCK_INIT(_valueLock);
        ER_LOCK_INIT(_listenersLock);
        ER_LOCK_INIT(_upstreamTransformLock);
        ER_LOCK_INIT(_downsteamTransformLock);
        _hasInsideRetain = NO;
    }
    return self;
}

- (instancetype)initWithValue:(id)value {
    if (self = [self init]) {
        _value = value;
    }
    return self;
}

+ (instancetype)value:(id)value {
    return [[ERNode alloc] initWithValue:value];
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

#pragma mark value's setter and getter

- (void)next:(nullable id)value from:(ERSenderList *)senderList {
    {
        ER_SCOPELOCK(_valueLock);
        _value = value;
    }
    
    if (value == EREmpty.empty) {
        return;
    }
    
    for (id<ERListener> listener in self.listeners) {
        [listener next:value from:self];
    }
    
    ERSenderList *newQueue = senderList.copy;
    [newQueue appendSender:self];
    
    {
        ER_SCOPELOCK(_downsteamTransformLock);
        
        for (ERTransform *transform in _downstreamTransforms) {
            if (![newQueue contains:transform.to]) {
                [transform next:value from:newQueue];
            }
        }
    }
    
}

- (void)setValue:(id)value {
    [self next:value from:[ERSenderList new]];
}

- (id)value {
    ER_SCOPELOCK(_valueLock);
    
    return _value;
}

- (BOOL)isEmpty {
    return self.value == EREmpty.empty;
}

- (void)clean {
    self.value = [EREmpty empty];
}

#pragma mark listener

- (NSArray<id<ERListener>> *)listeners {
    ER_SCOPELOCK(_listenersLock);
    
    return _listeners.allObjects;
}

- (BOOL)hasListener {
    ER_SCOPELOCK(_listenersLock);
    
    return _listeners.count > 0;
}

- (id<ERCancelable>)addListener:(id<ERListener>)listener {
    NSParameterAssert(listener);
    
    {
        ER_SCOPELOCK(_listenersLock);
        [_listeners addObject:listener];
    }
    
    if (self.value != EREmpty.empty) {
        [listener next:self.value from:self];
    }

    [self checkRelease];
    
    @er_weakify(self, listener)
    return [[ERBlockCancelable alloc] initWithBlock:^{
        @er_strongify(self, listener)
        [self removeListener:listener];
    }];
}

- (id<ERCancelable>)listen:(void (^)(id))listenerBlock {
    return [self addListener:[[ERBlockListener alloc] initWithBlock:listenerBlock]];
}

- (id<ERCancelable>)listen:(void (^)(id _Nullable))listenerBlock on:(dispatch_queue_t)queue {
    NSParameterAssert(queue);
    return [self addListener:[[ERBlockDeliveredListener alloc] initWithBlock:listenerBlock on:queue]];
}

- (id<ERCancelable>)listenOnMainQueue:(void (^)(id _Nullable))listenerBlock {
    return [self listen:listenerBlock on:dispatch_get_main_queue()];
}

- (void)removeListener:(id<ERListener>)listener {
    {
        ER_SCOPELOCK(_listenersLock);
        [_listeners removeObject:listener];
    }
    [self checkRelease];
}

#pragma mark downstream

- (NSArray<ERNode *> *)downstreamNodes {
    NSArray<ERTransform *> *transforms = ({
        ER_SCOPELOCK(_downsteamTransformLock);
        _downstreamTransforms.allObjects;
    });
    
    return [transforms er_map:^id _Nonnull(ERTransform * _Nonnull value) {
        return value.to;
    }];
}

- (NSArray<ERTransform *> *)downstreamTransforms {
    ER_SCOPELOCK(_downsteamTransformLock);
    return _downstreamTransforms.allObjects;
}

- (BOOL)hasDownstreamNode {
    ER_SCOPELOCK(_downsteamTransformLock);
    
    return _downstreamTransforms.count > 0;
}

- (id<ERCancelable>)linkTo:(ERNode *)node transform:(ERTransform *)transform {
    NSParameterAssert(node && node != self);
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
    
    [transform linkNode:node to:self];

    if (node.value != EREmpty.empty) {
        ERSenderList *queue = [ERSenderList new];
        [queue appendSender:self];
        [transform next:node.value from:queue];
    }
    
    {
        ER_SCOPELOCK(node->_downsteamTransformLock);
        [node->_downstreamTransforms addObject:transform];
    }
    
    {
        ER_SCOPELOCK(_upstreamTransformLock);
        [_upstreamTransforms addObject:transform];
    }
    
    [node checkRelease];
    [self checkRelease];

    @er_weakify(node,transform)
    return [[ERBlockCancelable alloc] initWithBlock:^{
        @er_strongify(node,transform)
        [node removeTransform:transform];
    }];
}

- (id<ERCancelable>)linkTo:(ERNode *)node {
    return [self linkTo:node transform:ERTransform.new];
}

- (void)removeDownstreamNode:(ERNode *)downstream {
    NSParameterAssert(downstream);
    NSArray<ERTransform *> *downstreamTransforms = ({
        ER_SCOPELOCK(_downsteamTransformLock);
        _downstreamTransforms.allObjects;
    });
    
    [[downstreamTransforms er_select:^BOOL(ERTransform * _Nonnull transform) {
        return transform.from == self && transform.to == downstream;
    }] er_foreach:^(ERTransform * _Nonnull transform) {
        [self removeDownstreamTransform:transform];
    }];
}

- (void)removeDownstreamTransform:(ERTransform *)transform {
    NSParameterAssert(transform);
    [self removeTransform:transform];
}

- (void)removeTransform:(ERTransform *)transform {
    NSParameterAssert(transform);
    
    ERNode *downstream = transform.to;
    
    {
        ER_SCOPELOCK(_downsteamTransformLock);
        NSAssert([_downstreamTransforms containsObject:transform], @"%@ doesn't have downstream transform %@", self, transform);
        [_downstreamTransforms removeObject:transform];
    }
    
    {
        ER_SCOPELOCK(downstream->_upstreamTransformLock);
        NSAssert([downstream->_upstreamTransforms containsObject:transform], @"%@ doesn't have upstream transform %@", downstream, transform);
        [downstream->_upstreamTransforms removeObject:transform];
    }
    
    [transform breakLinking];
    [downstream checkRelease];
    [self checkRelease];
}

- (void)removeDownstreamNodes {
    NSArray<ERTransform *> *downstreamTransforms = ({
        ER_SCOPELOCK(_downsteamTransformLock);
        _downstreamTransforms.allObjects;
    });
    for (ERTransform *transform in downstreamTransforms) {
        [self removeDownstreamTransform:transform];
    }
}

- (void)removeUpstreamNode:(ERNode *)upstream {
    NSParameterAssert(upstream);
    [upstream removeDownstreamNode:self];
}

- (void)removeUpstreamTransform:(ERTransform *)transform {
    NSParameterAssert(transform);
    [transform.from removeDownstreamTransform:transform];
}

- (void)removeUpstreamNodes {
    NSArray<ERTransform *> *upstreamTransforms = ({
        ER_SCOPELOCK(_upstreamTransformLock);
        _upstreamTransforms.allObjects;
    });
    for (ERTransform *transform in upstreamTransforms) {
        [self removeUpstreamTransform:transform];
    }
}

#pragma mark upstream

- (NSArray<ERNode *> *)upstreamNodes {
    NSArray<ERTransform *> *transforms = ({
        ER_SCOPELOCK(_upstreamTransformLock);
        _upstreamTransforms.allObjects;
    });
    
    return [transforms er_map:^id _Nonnull(ERTransform * _Nonnull value) {
        return value.from;
    }];
}

- (NSArray<ERTransform *> *)upstreamTransforms {
    ER_SCOPELOCK(_upstreamTransformLock);
    return _upstreamTransforms.allObjects;
}

- (BOOL)hasUpstreamNode {
    ER_SCOPELOCK(_upstreamTransformLock);
    
    return _upstreamTransforms.count > 0;
}

#pragma mark others

- (NSString *)description {
    return [NSString stringWithFormat:@"ERNode(named:%@ value:%@)", self.name ?: @"undefined", self.value];
}

- (void)dealloc {
    NSSet<ERTransform *> *upstreamTransform = ({
        ER_SCOPELOCK(_upstreamTransformLock);
        _upstreamTransforms.setRepresentation;
    });
    NSSet<ERTransform *> *downstreamTransforms = ({
        ER_SCOPELOCK(_downsteamTransformLock);
        [_downstreamTransforms copy];
    });
    
    for (ERTransform *transform in upstreamTransform) {
        [transform.from removeTransform:transform];
    }
    
    for (ERTransform *transform in downstreamTransforms) {
        [self removeTransform:transform];
    }
}

@end
