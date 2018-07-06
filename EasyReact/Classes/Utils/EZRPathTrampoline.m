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

#import "EZRPathTrampoline.h"
#import "EZRMutableNode.h"
#import "EZRNode+Operation.h"
#import "EZRNode+Listen.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZRMetaMacros.h"
#import "EZRListenContext.h"
#import "EZRCancelableBag.h"
@import ObjectiveC.runtime;
@import ObjectiveC.message;
#import <EasySequence/NSObject+EZSDeallocBell.h>

@implementation EZRPathTrampoline {
    __unsafe_unretained NSObject *_target;
    NSMutableDictionary<NSString *, EZRMutableNode *> *_keyPathNodes;
    NSMutableDictionary<NSString *, NSNumber *> *_syncFlags;
    EZR_LOCK_DEF(_keyPathNodesLock);
    EZR_LOCK_DEF(_syncFlagsLock);
    EZRCancelableBag *_cancelBag;
}

- (instancetype)initWithTarget:(id)target {
    if (self = [super init]) {
        _target = target;
        _keyPathNodes = [NSMutableDictionary dictionary];
        _syncFlags = [NSMutableDictionary dictionary];
        EZR_LOCK_INIT(_keyPathNodesLock);
        EZR_LOCK_INIT(_syncFlagsLock);
        _cancelBag = [EZRCancelableBag bag];
        [_target addDeallocCallback:^{
            NSArray<NSString *> *keyPaths = ({
                EZR_SCOPELOCK(self->_keyPathNodesLock);
                self->_keyPathNodes.allKeys;
            });
            
            for (NSString *keyPath in keyPaths) {
                [self->_target removeObserver:self forKeyPath:keyPath];
            }
        }];

    }
    return self;
}

- (void)setObject:(EZRNode *)node forKeyedSubscript:(NSString *)keyPath {
    NSParameterAssert(node);
    NSParameterAssert(keyPath);
    
    EZRMutableNode *keyPathNode = self[keyPath];
    [_cancelBag addCancelable:[keyPathNode syncWith:node]];
}

- (EZRMutableNode *)nodeWithKeyPath:(NSString *)keyPath {
    EZR_SCOPELOCK(_keyPathNodesLock);
    return _keyPathNodes[keyPath];
}

- (void)setKeyPath:(NSString *)keyPath node:(EZRMutableNode *)node {
    EZR_SCOPELOCK(_keyPathNodesLock);
    EZR_SCOPELOCK(_syncFlagsLock);
    _keyPathNodes[keyPath] = node;
    _syncFlags[keyPath] = @YES;
}

- (BOOL)needSyncWithKeyPath:(NSString *)keyPath {
    EZR_SCOPELOCK(_syncFlagsLock);
    return [_syncFlags[keyPath] boolValue];
}

- (void)setKeyPath:(NSString *)keyPath needSync:(BOOL)state {
    EZR_SCOPELOCK(_syncFlagsLock);
    _syncFlags[keyPath] = @(state);
}

- (EZRMutableNode *)objectForKeyedSubscript:(NSString *)keyPath {
    NSParameterAssert(keyPath);
    EZRMutableNode *keyPathNode = [self nodeWithKeyPath:keyPath];
    
    if (!keyPathNode) {
        keyPathNode = EZRMutableNode.new;
        
        [self setKeyPath:keyPath node:keyPathNode];
        
        @ezr_weakify(self)
        [[keyPathNode listenedBy:self] withBlock:^(id  _Nullable next) {
            @ezr_strongify(self)
            if (!self) { return ; }
            if ([self needSyncWithKeyPath:keyPath]) {
                [self setKeyPath:keyPath needSync:NO];
                [self->_target setValue:next forKeyPath:keyPath];
            } else {
                [self setKeyPath:keyPath needSync:YES];
            }
        }];
        
        [_target addObserver:self
                  forKeyPath:keyPath
                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                     context:NULL];
    }
    
    return keyPathNode;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    EZRMutableNode *keyPathNode = [self nodeWithKeyPath:keyPath];

    id valueForPath = change[NSKeyValueChangeNewKey];
    if ([valueForPath isKindOfClass:NSNull.class]) {
        valueForPath = nil;
    }
    
    if ([self needSyncWithKeyPath:keyPath]) {
        [self setKeyPath:keyPath needSync:NO];
        keyPathNode.value = valueForPath;
    } else {
        [self setKeyPath:keyPath needSync:YES];
    }
}

@end
