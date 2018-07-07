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

#import "EZRCancelableBag.h"
#import "EZRMetaMacrosPrivate.h"
#import "EZRBlockCancelable.h"
#import "EZRCancelableBagProtocol.h"
#import <EasyFoundation/EasyFoundation.h>

@implementation EZRCancelableBag {
    EZSArray<id<EZRCancelable>> *_cancelBag;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cancelBag = [EZSArray new];
        
    }
    return self;
}

+ (instancetype)bag {
    return [[self alloc] init];
}

- (void)cancel {
    @synchronized (self) {
        [EZS_Sequence(_cancelBag) forEach:^(id<EZRCancelable>  _Nonnull value) {
            [value cancel];
        }];
        [_cancelBag removeAllObjects];
    }
}

- (void)addCancelable:(id<EZRCancelable>)cancelable {
    NSParameterAssert(cancelable);
    if (!cancelable) { return; }
    [_cancelBag addObject:cancelable];
}

- (void)removeCancelable:(id<EZRCancelable>)cancelable {
    NSParameterAssert(cancelable);
    if (!cancelable) { return; }
    [_cancelBag removeObject:cancelable];
}

- (void)dealloc {
    [EZS_Sequence(_cancelBag) forEach:^(id<EZRCancelable>  _Nonnull value) {
        [value cancel];
    }];
}

@end
