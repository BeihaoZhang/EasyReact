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

#import "ERNode+Graph.h"
#import "NSArray+ER_Extension.h"
#import <EasyReact/ERTransform.h>
#import "ERNode+Traversal.h"

@interface ERNode (DotLanguage)

- (NSString *)er_dotString;

@end

@implementation ERNode (DotLanguage)

- (NSString *)er_dotString {
    return [NSString stringWithFormat:@"  er_%p[label=\"%@\"]", self, self.name];
}

@end

@interface ERTransform (DotLanguage)

- (NSString *)er_dotString;

@end

@implementation ERTransform (DotLanguage)

- (NSString *)er_dotString {
    return [NSString stringWithFormat:@"  er_%p -> er_%p[label=\"%@\"]", self.from, self.to, self.name];
}

@end

@interface ERNodeGraphVisitor : NSObject <ERNodeVisitor>

@property (nonatomic, readonly) NSMutableSet<ERNode *> *nodes;
@property (nonatomic, readonly) NSMutableSet<ERTransform *> *transforms;

- (NSString *)dotFile;

@end

@implementation ERNodeGraphVisitor

- (instancetype)init {
    if (self = [super init]) {
        _nodes = [NSMutableSet set];
        _transforms = [NSMutableSet set];
    }
    return self;
}

- (BOOL)visitNode:(ERNode *)node deep:(NSInteger)deep {
    [self.nodes addObject:node];
    return NO;
}

- (BOOL)visitTransform:(ERTransform *)transform {
    [self.transforms addObject:transform];
    return NO;
}

- (NSString *)dotFile {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"digraph G {\n  node [peripheries=2 style=filled color=\"#eecc80\"]\n  edge [color=\"sienna\" fontcolor=\"black\"] \n"];
    
    [result appendString:[[self.transforms.allObjects er_map:^id _Nonnull(ERTransform * _Nonnull value) {
        return value.er_dotString;
    }] componentsJoinedByString:@"\n"]];
    [result appendString:@"\n"];
    
    [result appendString:[[self.nodes.allObjects er_map:^id _Nonnull(ERNode * _Nonnull value) {
        return value.er_dotString;
    }] componentsJoinedByString:@"\n"]];
    
    [result appendString:@"\n}"];
    
    return result.copy;
}

@end

@implementation ERNode (Graph)

- (NSString *)graph {
    ERNodeGraphVisitor *visitor = [ERNodeGraphVisitor new];
    [self traversal:visitor];
    return [visitor dotFile];
}

@end
