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

#import "ERQueue.h"
#import "ERMetaMacrosPrivate.h"

@implementation ERQueue {
    @private
    ER_LOCK_DEF(_insideArrayLock);
    NSMutableArray *_insideArray;
}

- (instancetype)init {
    if (self = [super init]) {
        ER_LOCK_INIT(_insideArrayLock);
        _insideArray = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isEmpty {
    ER_SCOPELOCK(_insideArrayLock);
    return _insideArray.count == 0;
}

- (NSUInteger)count {
    ER_SCOPELOCK(_insideArrayLock);
    return _insideArray.count;
}

- (void)enqueue:(id)item {
    ER_SCOPELOCK(_insideArrayLock);
    [_insideArray addObject:item ?: NSNull.null];
}

- (id)dequeue {
    ER_SCOPELOCK(_insideArrayLock);
    id front = [_insideArray[0] isEqual:NSNull.null] ? nil : _insideArray[0];
    [_insideArray removeObjectAtIndex:0];
    return front;
}

- (id)front {
    ER_SCOPELOCK(_insideArrayLock);
    id front = [_insideArray.firstObject isEqual:NSNull.null] ? nil : _insideArray.firstObject;
    return front;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ERQueue *newQueue = [ERQueue allocWithZone:zone];
    ER_LOCK_INIT(newQueue->_insideArrayLock);
    {
        ER_SCOPELOCK(_insideArrayLock);
        newQueue->_insideArray = _insideArray.mutableCopy;
    }
    return newQueue;
}

- (BOOL)contains:(id)item {
    NSArray *array = ({
        ER_SCOPELOCK(_insideArrayLock);
        _insideArray.copy;
    });
    return [array containsObject:item];
}

@end
