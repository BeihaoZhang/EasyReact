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

#import "ERNode+ProjectPrivate.h"
#import "ERMetaMacrosPrivate.h"
#import "NSArray+ER_Extension.h"
#import "ERTransform.h"

@implementation ERNode (NoARC)

- (void)checkRelease {
    NSArray<ERTransform *> *upstreamTransforms = ({
        ER_SCOPELOCK(_upstreamTransformLock);
        _upstreamTransforms.allObjects;
    });
    NSArray<ERTransform *> *downstreamTransforms = ({
        ER_SCOPELOCK(_downsteamTransformLock);
        _downstreamTransforms.allObjects;
    });
    BOOL hasUpstreamTransformExcludeSync = [upstreamTransforms er_reject:^BOOL(ERTransform * _Nonnull upstream) {
        return [downstreamTransforms er_any:^BOOL(ERTransform * _Nonnull downstream) {
            return upstream.from == downstream.to && downstream.from == upstream.to;
        }];
    }].count > 0;
    BOOL hasDownstreamOrListener = self.hasListener || self.hasDownstreamNode;

    BOOL needRetain = hasUpstreamTransformExcludeSync && hasDownstreamOrListener;
    if (self.hasInsideRetain) {
        if (!needRetain) {
            [self autorelease];
            self.hasInsideRetain = NO;
        }
    } else {
        if (needRetain) {
            [self retain];
            self.hasInsideRetain = YES;
        }
    }
}

@end
