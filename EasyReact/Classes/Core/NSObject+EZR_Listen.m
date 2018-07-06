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

#import "NSObject+EZR_Listen.h"
#import "EZRListenContext+ProjectPrivate.h"
#import <objc/runtime.h>
#import "EZRNode.h"

static void *EZR_NodeContextKey = &EZR_NodeContextKey;

@interface NSObject (EZR_ListenPrivate)

@property (atomic, strong) NSMutableDictionary<NSString *, EZRListenContext *> *nodeContext;

@end

@implementation NSObject (EZR_Listen)

- (EZRListenContext *)listen:(EZRNode *)node {
    NSParameterAssert(node);
    if (!node) {
        return nil;
    }
    NSMutableDictionary<NSString *, EZRListenContext *> *nodeContext = self.nodeContext;
    @synchronized(self) {
        NSString *uniqueKey = [NSString stringWithFormat:@"%p", node];
        EZRListenContext *context = nodeContext[uniqueKey];
        if (!context) {
            context = [[EZRListenContext alloc] initWithNode:node listener:self] ;
            nodeContext[uniqueKey] = context;
        }

        return context;
    }
}

- (void)stopListen:(EZRNode *)node {
    NSMutableDictionary<NSString *, EZRListenContext *> *nodeContext = self.nodeContext;
    @synchronized(self) {
        NSString *uniqueKey = [NSString stringWithFormat:@"%p", node];
        nodeContext[uniqueKey] = nil;
    }
}

- (NSMutableDictionary<NSNumber *,EZRListenContext *> *)nodeContext {
    NSMutableDictionary<NSNumber *, EZRListenContext *> *nodeContext = objc_getAssociatedObject(self, EZR_NodeContextKey);
    
    if (!nodeContext) {
        @synchronized(self) {
            nodeContext = objc_getAssociatedObject(self, EZR_NodeContextKey);
            if (!nodeContext) {
                nodeContext = [NSMutableDictionary dictionary];
                objc_setAssociatedObject(self, EZR_NodeContextKey, nodeContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return nodeContext;
}


@end
