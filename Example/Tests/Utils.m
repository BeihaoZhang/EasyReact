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

QuickSpecBegin(Utils)

describe(@"Utils test", ^{
    context(@"NSArray Extension", ^{
        it(@"can map an array to a new array by invoking a block on each item", ^{
            NSArray<NSString *> *array = @[@"111", @"222", @"333"];
            NSArray *mappedArray = [array er_map:^id _Nonnull(NSString * _Nonnull value) {
                return @(value.integerValue);
            }];
            expect(mappedArray).to(haveCount(array.count));
            expect(mappedArray).to(equal(@[@111, @222, @333]));
        });

        it(@"can map an array to a new array with index", ^{
            NSArray<NSString *> *array = @[@"a", @"b", @"c"];
            NSArray *result = [array er_mapWithIndex:^id _Nonnull(NSString * _Nonnull value, NSUInteger index) {
                return [NSString stringWithFormat:@"%@: %@", @(index), value];
            }];
            expect(result).to(equal(@[@"0: a", @"1: b", @"2: c"]));
        });

        it(@"can invoke a block on each item of an array", ^{
            NSArray<NSNumber *> *array = @[@1, @2, @3];
            __block NSInteger sum = 0;
            [array er_foreach:^(NSNumber * _Nonnull value) {
                sum += value.integerValue;
            }];
            expect(sum).to(equal(6));
        });

        it(@"can invoke a block on each item of an array with index", ^{
            NSArray<NSString *> *array = @[@"a", @"bb", @"ccc"];
            NSMutableArray *result = [NSMutableArray array];
            [array er_foreachWithIndex:^(NSString * _Nonnull value, NSUInteger index) {
                [result addObject:[NSString stringWithFormat:@"index: %@, value: %@", @(index), value]];
            }];
            expect(result).to(equal(@[@"index: 0, value: a", @"index: 1, value: bb", @"index: 2, value: ccc"]));
        });

        it(@"can invoke a block on items and stop at some point", ^{
            NSArray<NSString *> *array = @[@"a", @"bb", @"ccc", @"dddd"];
            NSMutableArray *result = [NSMutableArray array];
            [array er_foreachWithIndexAndStop:^(NSString * _Nonnull value, NSUInteger index, BOOL * _Nonnull stop) {
                if (value.length > 2) {
                    *stop = YES;
                }
                [result addObject:[NSString stringWithFormat:@"%@ %@", @(index), value]];
            }];
            expect(result).to(equal(@[@"0 a", @"1 bb", @"2 ccc"]));
        });

        it(@"can find that whether at least one item in the array meets the given condition", ^{
            NSArray<NSNumber *> *array = @[@2, @4, @300];
            BOOL containsBigNumber = [array er_any:^BOOL(NSNumber * _Nonnull value) {
                return value.integerValue > 100;
            }];
            expect(containsBigNumber).to(beTrue());

            BOOL containsOddNumber = [array er_any:^BOOL(NSNumber * _Nonnull value) {
                return value.integerValue % 2 == 1;
            }];
            expect(containsOddNumber).to(beFalse());
        });

        it(@"can return a new array from the origin array which contains the items that meets the given condition", ^{
            NSArray<NSNumber *> *array = @[@1, @2, @3, @4, @5, @6];
            NSArray *oddNumbers = [array er_select:^BOOL(NSNumber * _Nonnull value) {
                return value.integerValue % 2 == 1;
            }];
            expect(oddNumbers).to(equal(@[@1, @3, @5]));
        });

        it(@"can return a new array from the origin array which does not contain the items that meets the given condition", ^{
            NSArray<NSNumber *> *array = @[@1, @2, @3, @4, @5, @6];
            NSArray *evenNumbers = [array er_reject:^BOOL(NSNumber * _Nonnull value) {
                return value.integerValue % 2 == 1;
            }];
            expect(evenNumbers).to(equal(@[@2, @4, @6]));
        });

        context(@"reduce", ^{
            it(@"can reduce an array to a single value using a given block", ^{
                NSArray<NSNumber *> *array1 = @[@1, @2, @3, @4];
                NSString *result1 = [array1 er_reduce:^id _Nullable(id _Nullable operand1, NSNumber * _Nonnull operand2) {
                    return [NSString stringWithFormat:@"%@+%@", operand1, operand2];
                }];
                expect(result1).to(equal(@"1+2+3+4"));

                NSArray *array2 = @[];
                id result2 = [array2 er_reduce:^id _Nullable(id _Nullable operand1, id _Nonnull operand2) {
                    return [NSString stringWithFormat:@"%@ %@", operand1, operand2];
                }];
                expect(result2).to(beNil());

                NSArray *array3 = @[@"aaa"];
                id result3 = [array3 er_reduce:^id _Nullable(id _Nullable operand1, id _Nonnull operand2) {
                    return [NSString stringWithFormat:@"%@ and %@", operand1, operand2];
                }];
                expect(result3).to(equal(@"aaa"));
            });

            it(@"can reduce an array to a single value using a given block and a start value", ^{
                NSArray<NSNumber *> *array1 = @[@1, @2, @3, @4];
                NSNumber *result1 = [array1 er_reduceWithStartValue:nil operation:^id _Nullable(id _Nullable accumulator, NSNumber * _Nonnull operand) {
                    return @([accumulator integerValue] + operand.integerValue);
                }];
                expect(result1).to(equal(@10));

                NSArray<NSNumber *> *array2 = @[@1, @2, @3];
                NSString *result2 = [array2 er_reduceWithStartValue:@"start" operation:^id _Nullable(id _Nullable accumulator, NSNumber * _Nonnull operand) {
                    return [NSString stringWithFormat:@"%@, %@", accumulator, operand];
                }];
                expect(result2).to(equal(@"start, 1, 2, 3"));

                NSArray *array3 = @[];
                id result3 = [array3 er_reduceWithStartValue:nil operation:^id _Nullable(id _Nullable accumulator, id _Nonnull operand) {
                    return [NSString stringWithFormat:@"%@ %@", accumulator, operand];
                }];
                expect(result3).to(beNil());

                NSArray *array4 = @[];
                id result4 = [array4 er_reduceWithStartValue:@"result" operation:^id _Nullable(id _Nullable accumulator, id _Nonnull operand) {
                    return [NSString stringWithFormat:@"%@ %@", accumulator, operand];
                }];
                expect(result4).to(equal(@"result"));

                NSArray *array5 = @[@"aaa"];
                id result5 = [array5 er_reduceWithStartValue:nil operation:^id _Nullable(id _Nullable accumulator, id _Nonnull operand) {
                    return [NSString stringWithFormat:@"%@ and %@", accumulator, operand];
                }];
                expect(result5).to(equal(@"(null) and aaa"));

                NSArray *array6 = @[@"aaa"];
                id result6 = [array6 er_reduceWithStartValue:@"begin" operation:^id _Nullable(id _Nullable accumulator, id _Nonnull operand) {
                    return [NSString stringWithFormat:@"%@ and %@", accumulator, operand];
                }];
                expect(result6).to(equal(@"begin and aaa"));
            });
        });

        context(@"groupBy", ^{
            it(@"can group an array by a given rule", ^{
                NSArray<NSNumber *> *array1 = @[@2, @3, @4, @5, @6, @8];
                NSDictionary *result1 = [array1 er_groupBy:^id _Nonnull(NSNumber * _Nonnull value) {
                    return @(value.integerValue % 3);
                }];
                expect(result1).to(equal(@{@0: @[@3, @6], @1: @[@4], @2:@[@2, @5, @8]}));

                NSArray<NSString *> *array2 = @[@"This", @"is", @"a", @"statement", @"."];
                NSDictionary *result2 = [array2 er_groupBy:^id _Nonnull(NSString * _Nonnull value) {
                    return [NSString stringWithFormat:@"length: %@", @(value.length)];
                }];
                expect(result2).to(equal(@{@"length: 1": @[@"a", @"."], @"length: 2": @[@"is"], @"length: 4":@[@"This"], @"length: 9":@[@"statement"]}));
            });

            it(@"will return an empty dictionary if the original array is empty", ^{
                NSArray<NSNumber *> *array = @[];
                NSDictionary *grouped = [array er_groupBy:^id _Nonnull(NSNumber * _Nonnull value) {
                    return @(value.integerValue);
                }];
                expect(grouped).to(equal(@{}));
            });
        });
        
        it(@"can use zip to zip some arrays", ^{
            NSArray *a = @[@1, @2, @3];
            NSArray *b = @[@"a", @"b", @"c"];
            expect([NSArray er_zip:@[a, b]]).to(equal(@[@[@1, @"a"], @[@2, @"b"], @[@3, @"c"]]));
        });
        
        it(@"can use zip to zip some arrays, and support NSNull", ^{
            NSArray *a = @[@1, @2, @3];
            NSArray *b = @[@"a", NSNull.null, @"c"];
            expect([NSArray er_zip:@[a, b]]).to(equal(@[@[@1, @"a"], @[@2, NSNull.null], @[@3, @"c"]]));
        });
        
        it(@"can use zip to zip some arrays, and support different count", ^{
            NSArray *a = @[@1, @2, @3];
            NSArray *b = @[@"a", @"b"];
            expect([NSArray er_zip:@[a, b]]).to(equal(@[@[@1, @"a"], @[@2, @"b"]]));
        });
    });

    context(@"ERUsefulBlocks", ^{
        it(@"can generate a block to detemine that whether an object is kind of a specific class", ^{
            ERCheckBlock isString = er_isKindOf([NSString class]);
            BOOL result1 = isString(@"abc");
            BOOL result2 = isString(@111);
            expect(result1).to(beTrue());
            expect(result2).to(beFalse());

            ERCheckBlock isNumber = er_isKindOf([NSNumber class]);
            NSArray *array = @[@"aa", @123, @"bb", @"cc", @100];
            NSArray *numbers = [array er_select:isNumber];
            expect(numbers).to(equal(@[@123,@100]));
        });

        it(@"can generate a block to detemine that whether an object is equal to something", ^{
            ERCheckBlock isBad = er_isEqual(@"bad");
            NSArray *array = @[@"great", @"bad", @"good", @"bad", @"average", @"unknown"];
            NSArray *result1 = [array er_reject:isBad];
            expect(result1).to(equal(@[@"great", @"good", @"average", @"unknown"]));
            
            ERCheckBlock isExpectedDic = er_isEqual(@{@"status": @1, @"result": @"great"});
            BOOL result2 = isExpectedDic(@{@"status": @1, @"result": @"great"});
            BOOL result3 = isExpectedDic(@{@"status": @0, @"result": @"failed"});
            expect(result2).to(beTrue());
            expect(result3).to(beFalse());
        });

        it(@"can make a negative version of a given ERCheckBlock", ^{
            ERCheckBlock isGood = er_isEqual(@"good");
            ERCheckBlock notGood = er_not(isGood);
            BOOL result1 = notGood(@"good");
            BOOL result2 = notGood(@"bad");
            expect(result1).to(beFalse());
            expect(result2).to(beTrue());

            NSArray *array = @[@"good", @"bad", @"unknown"];
            NSArray *result3 = [array er_reject:notGood];
            expect(result3).to(equal(@[@"good"]));
        });
    });
    
    context(@"NSObject ER_DeallocSwizzle test", ^{
        it(@"can sent will dealloc when an object dealloc which class don't have dealloc method", ^{
            __block BOOL receiveCallback = NO;
           
            @autoreleasepool {
                TestKVOClass *obj = [TestKVOClass new];
                [obj er_listenDealloc:^{
                    receiveCallback = YES;
                }];
            }
            expect(receiveCallback).to(beTrue());
        });
        
        it(@"can sent will dealloc when an object dealloc which class have dealloc method", ^{
            __block BOOL receiveCallback = NO;
            
            @autoreleasepool {
                TestKVOClass *obj = [TestKVOClass new];
                [obj er_listenDealloc:^{
                    receiveCallback = YES;
                }];
            }
            expect(receiveCallback).to(beTrue());
        });
        
        it(@"cat't receive dealloc callback when cancel the listen dealloc", ^{
            __block BOOL receiveCallback = NO;
            
            @autoreleasepool {
                TestKVOClass *obj = [TestKVOClass new];
                id<ERCancelable> cancelable = [obj er_listenDealloc:^{
                    receiveCallback = YES;
                }];
                [cancelable cancel];
            }
            expect(receiveCallback).to(beFalse());
        });
    });
});

QuickSpecEnd
