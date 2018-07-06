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
#import "EZREmpty.h"
#import "EZRNode+ProjectPrivate.h"

NSString *EZRNodeExceptionName = @"EZRNodeException";

#pragma clang diagnostic push

#pragma clang diagnostic ignored"-Wincomplete-implementation"

@implementation EZRNode

@dynamic value, name, mutable;

// private for subClass
- (instancetype)initDirectly  {
    if (self = [super init]) {
        
    }
    return self;
}

- (instancetype)init {
    return [self initWithValue:[EZREmpty empty]];
}

- (instancetype)initWithValue:(id)value {
    return [[EZRMutableNode alloc] initWithValue:value mutable:NO];
}

+ (instancetype)value:(id)value {
    return [[EZRMutableNode alloc] initWithValue:value mutable:NO];
}

@end

#pragma clang diagnostic pop
