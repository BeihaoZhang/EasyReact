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

#import "BenchmarkResult.h"
#import <EasySequence/EasySequence.h>
#import <EasyReact/EasyReact.h>

@interface BenchmarkResult ()

@property (nonatomic, readonly) NSMutableOrderedSet<NSString *> *targetNameSet;
@property (nonatomic, readonly) NSMutableOrderedSet<NSString *> *testNameSet;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, NSMutableDictionary *> *testInfoDictionary;

@end

@implementation BenchmarkResult

- (instancetype)init {
    if (self = [super init]) {
        _targetNameSet = [NSMutableOrderedSet new];
        _testNameSet = [NSMutableOrderedSet new];
        _testInfoDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)csvResult {
    NSMutableString *csvResult = [NSMutableString string];
    //    table
    //    name,col1,col2
    //    E  R,value,value
    //    RAC,value,value
    [csvResult appendString:@"CSVFormat: \n"];
    void (^makeLine)(NSArray<NSString *> *column) = ^(NSArray<NSString *> *column) {
        [csvResult appendFormat:@"%@\n", [column componentsJoinedByString:@","]];
    };
    makeLine([@[@"name"] arrayByAddingObjectsFromArray:self.testNames]);
    
    for (NSString *targetName in self.targetNames) {
        makeLine([@[targetName] arrayByAddingObjectsFromArray:[[EZS_Sequence(self.testNames) map:^id _Nonnull(NSString * _Nonnull value) {
            return [self.testInfoDictionary[targetName][value] stringValue];
        }] as:NSArray.class]]);
    }
    return csvResult;
}

- (NSString *)markdownResult {
    NSMutableString *markdownResult = [NSMutableString string];
    //    |name|test1|test2|
    //    | --- | --- | --- |
    //    |ER  |value1  |value2 |
    [markdownResult appendString:@"MarkDown format: \n"];
    void (^makeLine)(NSArray<NSString *> *column) = ^(NSArray<NSString *> *column) {
        [markdownResult appendFormat:@"|%@|\n", [column componentsJoinedByString:@"|"]];
    };
    makeLine([@[@"name"] arrayByAddingObjectsFromArray:self.testNames]);
    
    makeLine([[EZS_Sequence([@[@""] arrayByAddingObjectsFromArray:self.testNames]) map:^(NSString *_){ return @" --- "; }] as:NSArray.class]);
    for (NSString *targetName in self.targetNames) {
        makeLine([@[targetName] arrayByAddingObjectsFromArray:[[EZS_Sequence(self.testNames) map:^id _Nonnull(NSString * _Nonnull value) {
            return [self.testInfoDictionary[targetName][value] stringValue];
        }] as:NSArray.class]] );
    }
    return markdownResult;
}

- (NSArray<NSString *> *)targetNames {
    return self.targetNameSet.array;
}

- (NSArray<NSString *> *)testNames {
    return self.testNameSet.array;
}

- (void)targetName:(NSString *)targetName testName:(NSString *)testName value:(uint64_t)value {
    [self.targetNameSet addObject:targetName];
    [self.testNameSet addObject:testName];
    if (!self.testInfoDictionary[targetName]) {
        self.testInfoDictionary[targetName] = [NSMutableDictionary dictionary];
    }
    self.testInfoDictionary[targetName][testName] = @(value);
}

@end
