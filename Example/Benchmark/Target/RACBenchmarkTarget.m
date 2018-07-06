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

#import "RACBenchmarkTarget.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "TestObject.h"

@implementation RACBenchmarkTarget

- (NSString *)name {
    return @"ReactiveCocoa";
}

- (void)listenerBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
    for (int i = 0; i < listenerCount; ++i) {
        [subject subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject sendNext:@(i)];
    }
}

- (void)mapBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject = [RACSubject subject];
    for (int i = 0; i < listenerCount; ++i) {
        [[subject map:^id(id value) {
            return [NSString stringWithFormat:@"%@",value];
        }] subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject sendNext:@(i)];
    }
}

- (void)filterBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject = [RACSubject subject];
    for (int i = 0; i < listenerCount; ++i) {
        [[subject filter:^BOOL(NSNumber *value) {
            return value.integerValue % 2 == 0;
        }] subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject sendNext:@(i)];
    }
}

- (void)syncWithBenchmarkChangeTimes:(NSUInteger)times {
    TestObject *obj1 = [TestObject new];
    TestObject *obj2 = [TestObject new];
    
    RACChannelTo(obj1, prop) = RACChannelTo(obj2, prop);
    for (int i = 0; i < times; ++i) {
        obj1.prop = @(i);
        obj2.prop = @(times-i);
    }
}

- (void)flattenMapBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject = [RACSubject subject];
    for (int i = 0; i < listenerCount; ++i) {
        [[subject flattenMap:^RACStream *(id value) {
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [subscriber sendNext:value];
                return nil;
            }];
        }] subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject sendNext:@(i)];
    }
}

- (void)combineBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject1 = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    
    for (int i = 0; i < times; ++i) {
        [[RACSignal combineLatest:@[subject1, subject2]] subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject1 sendNext:@(i)];
        [subject2 sendNext:@(times - i)];
    }
}

- (void)zipBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject1 = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    for (int i = 0; i < listenerCount; ++i) {
        [[RACSignal zip:@[subject1, subject2]] subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject1 sendNext:@(i)];
        [subject2 sendNext:@(times - i)];
    }
}

- (void)mergeBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long subjectSum = 0;
    RACSubject *subject1 = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    for (int i = 0; i < listenerCount; ++i) {
        [[RACSignal merge:@[subject1, subject2]] subscribeNext:^(id x) {
            ++subjectSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        [subject1 sendNext:@(i)];
        [subject2 sendNext:@(times - i)];
    }
}

@end
