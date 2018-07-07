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

#import "EZRSenderList.h"

@implementation EZRSenderList

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initWithSender:(id)value {
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

+ (instancetype)senderListWithSender:(id)value {
    return [[self alloc] initWithSender:value];
}

+ (instancetype)senderListWithArray:(NSArray *)array {
    EZRSenderList *list = [EZRSenderList new];
    for (id value in array) {
        list = [list appendNewSender:value];
    }
    return list;
}

- (instancetype)appendNewSender:(id)value {
    EZRSenderList *newSenderList = [EZRSenderList senderListWithSender:value];
    newSenderList->_prev = self;
    return newSenderList;
}

- (BOOL)contains:(id)obj {
    EZRSenderList *list = self;
    while (list) {
        if (list.value == obj) {
            return YES;
        }
        list = list.prev;
    }
    return NO;
}

@end
