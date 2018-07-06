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

#import "ERNode+Traversal.h"
#import "ERNode+ProjectPrivate.h"
#import "NSArray+ER_Extension.h"
#import "ERTransform.h"
#import "ERQueue.h"

@interface ERNodeVisitElement : NSObject

@property (nonatomic, strong) ERNode *node;
@property (nonatomic, assign) NSInteger deep;

- (BOOL)accept:(id<ERNodeVisitor>)visitor;

@end

@implementation ERNodeVisitElement

- (BOOL)isEqual:(ERNodeVisitElement *)object {
    if ([object isKindOfClass:[ERNodeVisitElement class]]) {
        return [self.node isEqual:object.node];
    }
    return NO;
}

- (NSUInteger)hash {
    return self.node.hash;
}

- (BOOL)accept:(id<ERNodeVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitNode:deep:)]) {
        return [visitor visitNode:self.node deep:self.deep];
    }
    return NO;
}

@end

@interface ERNode (VisitElement)

- (ERNodeVisitElement *)er_visitElementWithDeep:(NSInteger)deep;

@end

@implementation ERNode (VisitElement)

- (ERNodeVisitElement *)er_visitElementWithDeep:(NSInteger)deep {
    ERNodeVisitElement *element = [ERNodeVisitElement new];
    element.node = self;
    element.deep = deep;
    return element;
}

@end

@implementation ERNode (Traversal)

- (void)traversal:(id<ERNodeVisitor>)visitor {
    NSMutableSet<ERNodeVisitElement *> *uniqueElementSet = [NSMutableSet new];
    NSMutableSet<ERTransform *> *uniqueTransformSet = [NSMutableSet new];
    ERQueue<ERNodeVisitElement *> *traversalQueue = [ERQueue new];
    
    ERNodeVisitElement *root = [self er_visitElementWithDeep:0];
    [uniqueElementSet addObject:root];
    [traversalQueue enqueue:root];
    
    typedef void (^ForEachType)(ERNode *value);
    ForEachType (^enqueNewElement)(NSInteger deep) = ^ForEachType(NSInteger deep) {
        return ^void(ERNode *node) {
            ERNodeVisitElement *subElement = [node er_visitElementWithDeep:deep];
            if (![uniqueElementSet containsObject:subElement]) {
                [uniqueElementSet addObject:subElement];
                [traversalQueue enqueue:subElement];
            }
        };
    };
    
    while (![traversalQueue isEmpty]) {
        ERNodeVisitElement *element = [traversalQueue dequeue];
        if ([element accept:visitor]) {
            return ;
        }
        [element.node.upstreamNodes er_foreach:enqueNewElement(element.deep - 1)];
        [element.node.downstreamNodes er_foreach:enqueNewElement(element.deep + 1)];
        if ([visitor respondsToSelector:@selector(visitTransform:)]) {
            [[element.node.upstreamTransforms arrayByAddingObjectsFromArray:element.node.downstreamTransforms] er_foreach:^(ERTransform * _Nonnull value) {
                if (![uniqueTransformSet containsObject:value]) {
                    [uniqueTransformSet addObject:value];
                    if ([visitor visitTransform:value]) {
                        return ;
                    }
                }
            }];
        }
    }
}

@end
