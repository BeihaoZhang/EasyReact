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

#import "EZRNode+Graph.h"
#import "EZRTransformEdge.h"
#import "EZRNode+Traversal.h"
#import <EasyFoundation/EasyFoundation.h>

@interface EZRNode (DotLanguage)

- (NSString *)er_dotString;

@end

@implementation EZRNode (DotLanguage)

- (NSString *)er_dotString {
    return [NSString stringWithFormat:@"  er_%p[label=\"%@\"]", self, self.name];
}

@end

// For Swift Protocol Extension
static inline NSString *transformDotString(id<EZREdge> self) {
    return [NSString stringWithFormat:@"  er_%p -> er_%p[label=\"%@\"]", self.from, self.to, self.name];
}

@interface EZRNodeGraphVisitor : NSObject <EZRNodeVisitor>

@property (nonatomic, readonly) NSMutableSet<EZRNode *> *nodes;
@property (nonatomic, readonly) NSMutableSet<id<EZRTransformEdge>> *transforms;

- (NSString *)dotFile;

@end

@implementation EZRNodeGraphVisitor

- (instancetype)init {
    if (self = [super init]) {
        _nodes = [NSMutableSet set];
        _transforms = [NSMutableSet set];
    }
    return self;
}

- (BOOL)visitNode:(EZRNode *)node deep:(NSInteger)deep {
    [self.nodes addObject:node];
    return NO;
}

- (BOOL)visitTransform:(id<EZRTransformEdge>)transform {
    [self.transforms addObject:transform];
    return NO;
}

- (NSString *)dotFile {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"digraph G {\n  node [peripheries=2 style=filled color=\"#eecc80\"]\n  edge [color=\"sienna\" fontcolor=\"black\"] \n"];
    
    [result appendString:[[[EZS_Sequence(self.transforms) map:^id _Nonnull(id<EZRTransformEdge> _Nonnull value) {
        return transformDotString(value);
    }] as:NSArray.class] componentsJoinedByString:@"\n"]];
    [result appendString:@"\n"];
    
    [result appendString:[[[EZS_Sequence(self.nodes) map:^id _Nonnull(EZRNode * _Nonnull value) {
        return value.er_dotString;
    }] as:NSArray.class] componentsJoinedByString:@"\n"]];
    
    [result appendString:@"\n}"];
    
    return result.copy;
}

@end

@implementation EZRNode (Graph)

- (NSString *)graph {
    EZRNodeGraphVisitor *visitor = [EZRNodeGraphVisitor new];
    [self traversal:visitor];
    return [visitor dotFile];
}

@end
