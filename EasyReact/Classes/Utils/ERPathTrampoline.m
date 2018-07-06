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


#import "ERPathTrampoline.h"
#import "ERNode.h"
#import "ERNode+Operation.h"
#import "ERMetaMacrosPrivate.h"
#import "ERMetaMacros.h"
#import "NSObject+ER_DeallocSwizzle.h"
@import ObjectiveC.runtime;
@import ObjectiveC.message;

@implementation ERPathTrampoline {
    __unsafe_unretained NSObject *_target;
    NSMutableDictionary<NSString *, ERNode *> *_keyPathNodes;
    NSMutableDictionary<NSString *, NSNumber *> *_syncFlags;
    ER_LOCK_DEF(_keyPathNodesLock);
    ER_LOCK_DEF(_syncFlagsLock);
}

- (instancetype)initWithTarget:(id)target {
    if (self = [super init]) {
        _target = target;
        _keyPathNodes = [NSMutableDictionary dictionary];
        _syncFlags = [NSMutableDictionary dictionary];
        ER_LOCK_INIT(_keyPathNodesLock);
        ER_LOCK_INIT(_syncFlagsLock);
        [_target er_listenDealloc:^{
            NSArray<NSString *> *keyPaths = ({
                ER_SCOPELOCK(self->_keyPathNodesLock);
                self->_keyPathNodes.allKeys;
            });
            
            for (NSString *keyPath in keyPaths) {
                [_target removeObserver:self forKeyPath:keyPath];
            }
        }];
    }
    return self;
}

- (void)setObject:(ERNode *)node forKeyedSubscript:(NSString *)keyPath {
    NSParameterAssert(node);
    NSParameterAssert(keyPath);
    
    ERNode *keyPathNode = self[keyPath];
    [keyPathNode syncWith:node];
}

- (ERNode *)nodeWithKeyPath:(NSString *)keyPath {
    ER_SCOPELOCK(_keyPathNodesLock);
    return _keyPathNodes[keyPath];
}

- (void)setKeyPath:(NSString *)keyPath node:(ERNode *)node {
    ER_SCOPELOCK(_keyPathNodesLock);
    ER_SCOPELOCK(_syncFlagsLock);
    _keyPathNodes[keyPath] = node;
    _syncFlags[keyPath] = @YES;
}

- (BOOL)needSyncWithKeyPath:(NSString *)keyPath {
    ER_SCOPELOCK(_syncFlagsLock);
    return [_syncFlags[keyPath] boolValue];
}

- (void)setKeyPath:(NSString *)keyPath needSync:(BOOL)state {
    ER_SCOPELOCK(_syncFlagsLock);
    _syncFlags[keyPath] = @(state);
}

- (ERNode *)objectForKeyedSubscript:(NSString *)keyPath {
    NSParameterAssert(keyPath);
    ERNode *keyPathNode = [self nodeWithKeyPath:keyPath];
    
    if (!keyPathNode) {
        keyPathNode = ERNode.new;
        
        [self setKeyPath:keyPath node:keyPathNode];
        
        @er_weakify(self)
        [keyPathNode listen:^(id  _Nullable next) {
            @er_strongify(self)
            if (!self) {
                return ;
            }
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
    ERNode *keyPathNode = [self nodeWithKeyPath:keyPath];

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
