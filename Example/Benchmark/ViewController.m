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

#import "ViewController.h"
#import "Benchmark.h"
#import "EZRBenchmarkTarget.h"
#import "RACBenchmarkTarget.h"
#import "BenchmarkTest.h"
#import "BenchmarkResult.h"
#import "BenchmarkCPUTestMethod.h"
#import "Benchmark-Swift.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    Benchmark *benchmark = [Benchmark new];
    benchmark.benchmarkTargets = @[[EZRBenchmarkTarget new], [RACBenchmarkTarget new]];
    NSUInteger listenerCount = 10;
    NSUInteger changeTimes = 1000;
    NSArray<BenchmarkTest *> *tests = @[
                                        [BenchmarkTest testWithName:@"listener" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target listenerBenchmarkListenerCount:listenerCount changeTimes:changeTimes];
                                        }],
                                        [BenchmarkTest testWithName:@"map" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target mapBenchmarkListenerCount:listenerCount changeTimes:changeTimes];
                                        }],
                                        [BenchmarkTest testWithName:@"filter" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target filterBenchmarkListenerCount:listenerCount changeTimes:changeTimes];
                                        }],
                                        [BenchmarkTest testWithName:@"flattenMap" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target filterBenchmarkListenerCount:listenerCount changeTimes:changeTimes];
                                        }],
                                        [BenchmarkTest testWithName:@"combine" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target combineBenchmarkListenerCount:listenerCount changeTimes:100];
                                        }],
                                        [BenchmarkTest testWithName:@"zip" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target zipBenchmarkListenerCount:listenerCount changeTimes:changeTimes];
                                        }],
                                        [BenchmarkTest testWithName:@"merge" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target mergeBenchmarkListenerCount:listenerCount changeTimes:changeTimes];
                                        }],
                                        [BenchmarkTest testWithName:@"syncWith" block:^(id<BenchmarkTargetProtocol> target) {
                                            [target syncWithBenchmarkChangeTimes:changeTimes];
                                        }]
                                        ];
    benchmark.benchmarkTests = tests;
    BenchmarkResult *result = [BenchmarkResult new];
    [benchmark benchmark:[[BenchmarkCPUTestMethod alloc] initWithTestCount:10] result:result];
    
    NSLog(@"%@\n", result.csvResult);
    NSLog(@"%@\n", result.markdownResult);
}

@end
