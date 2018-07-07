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

#import "EZRNode+Traversal.h"
#import "EZRTransformEdge.h"
#import <EasyFoundation/EasyFoundation.h>

@interface EZRNodeVisitElement : NSObject

@property (nonatomic, strong) EZRNode *node;
@property (nonatomic, assign) NSInteger deep;

- (BOOL)accept:(id<EZRNodeVisitor>)visitor;

@end

@implementation EZRNodeVisitElement

- (BOOL)isEqual:(EZRNodeVisitElement *)object {
    if ([object isKindOfClass:[EZRNodeVisitElement class]]) {
        return [self.node isEqual:object.node];
    }
    return NO;
}

- (NSUInteger)hash {
    return self.node.hash;
}

- (BOOL)accept:(id<EZRNodeVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitNode:deep:)]) {
        return [visitor visitNode:self.node deep:self.deep];
    }
    return NO;
}

@end

@interface EZRNode (VisitElement)

- (EZRNodeVisitElement *)er_visitElementWithDeep:(NSInteger)deep;

@end

@implementation EZRNode (VisitElement)

- (EZRNodeVisitElement *)er_visitElementWithDeep:(NSInteger)deep {
    EZRNodeVisitElement *element = [EZRNodeVisitElement new];
    element.node = self;
    element.deep = deep;
    return element;
}

@end

@implementation EZRNode (Traversal)

- (void)traversal:(id<EZRNodeVisitor>)visitor {
    NSMutableSet<EZRNodeVisitElement *> *uniqueElementSet = [NSMutableSet new];
    NSMutableSet<id<EZRTransformEdge>> *uniqueTransformSet = [NSMutableSet new];
    EZSQueue<EZRNodeVisitElement *> *traversalQueue = [EZSQueue new];
    
    EZRNodeVisitElement *root = [self er_visitElementWithDeep:0];
    [uniqueElementSet addObject:root];
    [traversalQueue enqueue:root];
    
    typedef void (^ForEachType)(EZRNode *value);
    ForEachType (^enqueNewElement)(NSInteger deep) = ^ForEachType(NSInteger deep) {
        return ^void(EZRNode *node) {
            EZRNodeVisitElement *subElement = [node er_visitElementWithDeep:deep];
            if (![uniqueElementSet containsObject:subElement]) {
                [uniqueElementSet addObject:subElement];
                [traversalQueue enqueue:subElement];
            }
        };
    };
    
    while (![traversalQueue isEmpty]) {
        EZRNodeVisitElement *element = [traversalQueue dequeue];
        if ([element accept:visitor]) {
            return ;
        }
        
        [EZS_Sequence(element.node.upstreamNodes) forEach:enqueNewElement(element.deep - 1)];
        [EZS_Sequence(element.node.downstreamNodes) forEach:enqueNewElement(element.deep + 1)];
        if ([visitor respondsToSelector:@selector(visitTransform:)]) {
            [EZS_Sequence([element.node.upstreamTransforms arrayByAddingObjectsFromArray:element.node.downstreamTransforms]) forEach:^(id<EZRTransformEdge> _Nonnull value) {
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
