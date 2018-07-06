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

#import "EZRBenchmarkTarget.h"
#import <EasyReact/EasyReact.h>
#import "TestObject.h"

@implementation EZRBenchmarkTarget

- (NSString *)name {
    return @"EZRNode";
}

- (void)listenerBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[node listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
            ++nodeSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        node.value = @(i);
    }
}

- (void)mapBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[[node map:^id _Nullable(NSNumber * _Nullable next) {
            return [NSString stringWithFormat:@"%@",next];
        }] listenedBy:listener] withBlock:^(id  _Nullable next) {
            ++nodeSum;
        }] ;
    }
    for (int i = 0; i < times; ++i) {
        node.value = @(i);
    }
}

- (void)filterBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[[node filter:^BOOL(NSNumber * _Nullable next) {
            return next.integerValue % 2 == 0;
        }] listenedBy:listener] withBlock:^(id  _Nullable next) {
            ++nodeSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        node.value = @(i);
    }
}

- (void)syncWithBenchmarkChangeTimes:(NSUInteger)times; {
    TestObject *obj1 = [TestObject new];
    TestObject *obj2 = [TestObject new];
    EZR_PATH(obj1, prop) = EZR_PATH(obj2, prop);
    for (int i = 0; i < times; ++i) {
        obj1.prop = @(i);
        obj2.prop = @(times-i);
    }
}

- (void)flattenMapBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[[node flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
            return  [EZRNode value:next];
        }] listenedBy:listener] withBlock:^(id  _Nullable next) {
            ++nodeSum;
        }] ;
    }
    for (int i = 0; i < times; ++i) {
        node.value = @(i);
    }
}

- (void)combineBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node1 = EZRMutableNode.new;
    EZRMutableNode<NSNumber *> *node2 = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[[EZRNode combine:@[node1, node2]] listenedBy:listener] withBlock:^(id  _Nullable next) {
            ++nodeSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        node1.value = @(i);
        node2.value = @(times - i);
    }
}

- (void)zipBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node1 = EZRMutableNode.new;
    EZRMutableNode<NSNumber *> *node2 = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[[EZRNode zip:@[node1, node2]] listenedBy:listener] withBlock:^(id  _Nullable next) {
            ++nodeSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        node1.value = @(i);
        node2.value = @(times - i);
    }
}

- (void)mergeBenchmarkListenerCount:(NSUInteger)listenerCount changeTimes:(NSUInteger)times {
    __block long long nodeSum = 0;
    EZRMutableNode<NSNumber *> *node1 = EZRMutableNode.new;
    EZRMutableNode<NSNumber *> *node2 = EZRMutableNode.new;
    NSObject *listener = [NSObject new];
    for (int i = 0; i < listenerCount; ++i) {
        [[[EZRNode merge:@[node1, node2]] listenedBy:listener] withBlock:^(id  _Nullable next) {
            ++nodeSum;
        }];
    }
    for (int i = 0; i < times; ++i) {
        node1.value = @(i);
        node2.value = @(times - i);
    }
}

@end
