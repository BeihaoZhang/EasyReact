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

#import "BenchmarkCPUTestMethod.h"
#import "BenchmarkTest.h"

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@implementation BenchmarkCPUTestMethod {
    NSUInteger _count;
}

- (instancetype)initWithTestCount:(NSUInteger)count {
    if (self = [super init]) {
        _count = count;
    }
    return self;
}

- (uint64_t)test:(BenchmarkTest *)test forTarget:(id<BenchmarkTargetProtocol>)target { 
    return dispatch_benchmark(_count, ^{ [test runTest:target]; });
}

@end
