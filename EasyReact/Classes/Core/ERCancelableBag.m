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

#import "ERCancelableBag.h"
#import "ERMetaMacrosPrivate.h"
#import "NSArray+ER_Extension.h"
#import "ERBlockCancelable.h"

@implementation ERCancelableBag {
    NSMutableArray<id<ERCancelable>> *_cancelBag;
    ER_LOCK_DEF(_baglock);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cancelBag = [NSMutableArray array];
        ER_LOCK_INIT(_baglock);
    }
    return self;
}

+ (instancetype)bag {
    return [[self alloc] init];
}

- (void)cancel {
    ER_SCOPELOCK(_baglock);
    [_cancelBag er_foreach:^(id<ERCancelable>  _Nonnull value) {
        [value cancel];
    }];
    [_cancelBag removeAllObjects];
}

- (void)addCancelable:(id<ERCancelable>)cancelable {
    NSParameterAssert(cancelable);
    if (!cancelable) { return; }
    ER_SCOPELOCK(_baglock);
    [_cancelBag addObject:cancelable];
}

- (void)addCancelBlock:(void (^)(void))cancelBlock {
    NSCParameterAssert(cancelBlock);
    if (!cancelBlock) { return; }
    ERBlockCancelable *cancelable = [[ERBlockCancelable alloc] initWithBlock:cancelBlock];
    [self addCancelable:cancelable];
}

- (void)removeCancelable:(id<ERCancelable>)cancelable {
    NSParameterAssert(cancelable);
    if (!cancelable) { return; }
    ER_SCOPELOCK(_baglock);
    [_cancelBag removeObject:cancelable];
}

- (void)dealloc {
    [_cancelBag er_foreach:^(id<ERCancelable>  _Nonnull value) {
        [value cancel];
    }];
}

@end
