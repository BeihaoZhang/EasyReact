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

QuickSpecBegin(ERNodeOperation)

describe(@"ERNode operation test", ^{
    context(@"deliver on queue", ^{
        it(@"can deliver on a custome queue", ^{
            dispatch_queue_t queue = dispatch_queue_create("com.er.deliverQueue", DISPATCH_QUEUE_SERIAL);
            ERNode<NSNumber *> *oriNode = ERNode.new;
            ERNode<NSNumber *> *testNode = [oriNode deliverOn:queue];
            [testNode listen:^(NSNumber * _Nullable next) {
                expect([NSThread currentThread].isMainThread).to(beFalse());
            }];
            oriNode.value = @1;
        });
        
        it(@"can deliver on mainQueue", ^{
            dispatch_queue_t queue = dispatch_queue_create("com.er.deliverQueue", DISPATCH_QUEUE_SERIAL);
            ERNode<NSNumber *> *oriNode = ERNode.new;
            ERNode<NSNumber *> *testNode = [oriNode deliverOnMainQueue];
            [testNode listen:^(NSNumber * _Nullable next) {
                expect([NSThread currentThread].isMainThread).to(beTrue());
            }];
            dispatch_async(queue, ^{
                oriNode.value = @1;
            });
        });
        
        it(@"can listen on a special queue use listenOn:queue whatever you deliver on any queue", ^{
            dispatch_queue_t sendQueue = dispatch_queue_create("com.er.deliverQueue1", DISPATCH_QUEUE_SERIAL);
            dispatch_queue_t listenerQueue = dispatch_queue_create("com.er.listenerQueue", DISPATCH_QUEUE_SERIAL);
            
            ERNode<NSNumber *> *oriNode = ERNode.new;
            ERNode<NSNumber *> *testNode = [oriNode deliverOn:sendQueue];
            [testNode listen:^(NSNumber * _Nullable next) {
                expect([NSThread currentThread].isMainThread).to(beFalse());
            }];
            [testNode listen:^(NSNumber * _Nullable next) {
                expect([NSThread currentThread].isMainThread).to(beFalse());
            }
                          on:listenerQueue];
            [testNode listenOnMainQueue:^(NSNumber * _Nullable next) {
                 expect([NSThread currentThread].isMainThread).to(beTrue());
            }];
            oriNode.value  = @1;
            dispatch_async(sendQueue, ^{
                oriNode.value  = @2;
            });
        });
        
        it(@"should raise an asset if deliver on a NULL queue ",^{
            assertExpect(^{
                dispatch_queue_t queue = NULL;
                ERNode<NSNumber *> *oriNode = ERNode.new;
                [oriNode deliverOn:queue];
            }).to(hasParameterAssert());
        });
    });
    
    context(@"map", ^{
        it(@"can map to get a new value", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            ERNode *mappedValue = [testValue map:^id(NSNumber *next) {
                return @(next.integerValue * 2);
            }];
            
            [mappedValue startListenForTest];
            
            testValue.value = @6;
            testValue.value = @8;
            
            expect(mappedValue.value).to(equal(@16));
            expect(mappedValue).to(receive(@[@2, @12, @16]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testValue = [ERNode value:@1];
                ERNode *mappedValue = [testValue map:^id(NSNumber *next) {
                    return @(next.integerValue * 2);
                }];
                [checkTool checkObj:testValue];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
        
        it(@"keeps the listeners valid even if there is no strong reference pointing to it", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            
            TestListener *listener = [TestListener new];
            @autoreleasepool {
                ERNode *mappedValue = [testValue map:^id(NSNumber *next) {
                    return @(next.integerValue * 2);
                }];
                [mappedValue addListener:listener];
                testValue.value = @2;
                testValue.value = @3;
            }
            
            testValue.value = @4;

            expect(listener.receiveValues).to(equal(@[@2, @4, @6, @8]));
        });
    });
    
    context(@"filter", ^{
        it(@"can filter to get a new value", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            ERNode *filteredValue = [testValue filter:^BOOL(NSNumber *next) {
                return next.integerValue > 2;
            }];
            
            expect(filteredValue).to(beEmptyValue());
            
            [filteredValue startListenForTest];
            
            testValue.value = @8;
            testValue.value = @0;
            testValue.value = @5;
            testValue.value = @2;
            
            expect(filteredValue.value).to(equal(@5));
            expect(filteredValue).to(receive(@[@8, @5]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testValue = [ERNode value:@1];
                ERNode *filteredValue = [testValue filter:^BOOL(NSNumber *next) {
                    return next.integerValue > 2;
                }];
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:filteredValue];
            }).to(beReleasedCorrectly());
        });
        
        it(@"can still listen value when there isn't strong reference outside", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@3];
            
            TestListener *listener = [TestListener new];
            @autoreleasepool {
                ERNode *filteredValue = [testValue filter:^BOOL(NSNumber *next) {
                    return next.integerValue > 2;
                }];
                [filteredValue addListener:listener];
                testValue.value = @2;
                testValue.value = @8;
            }
            
            testValue.value = @4;
            
            expect(listener.receiveValues).to(equal(@[@3, @8, @4]));
        });
    });
    
    context(@"take", ^{
        it(@"should not receive new Change after N values Changed  ", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            ERNode<NSNumber *> *takenValue = [testValue take:5];
            
            [takenValue startListenForTest];
            
            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            expect(takenValue.value).to(equal(@5));
            testValue.value = @10;
            expect(takenValue.value).notTo(equal(10));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testValue = [ERNode value:@1];
                ERNode<NSNumber *> *takenValue = [testValue take:5];;
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:takenValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"skip", ^{
        it(@"can skip first N values to make a new ERNode", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            ERNode<NSNumber *> *skippedValue = [testValue skip:2];
            
            [skippedValue startListenForTest];
            
            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            testValue.value = @6;
            testValue.value = @7;
            
            expect(skippedValue.value).to(equal(@7));
            expect(skippedValue).to(receive(@[@3, @4, @5, @6, @7]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testValue = [ERNode value:@1];
                ERNode<NSNumber *> *skippedValue = [testValue skip:2];
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:skippedValue];
            }).to(beReleasedCorrectly());
        });
    });

    context(@"ignore", ^{
        it(@"can ignore the given value", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            ERNode<NSNumber *> *ignoredValue = [testValue ignore:@5];

            [ignoredValue startListenForTest];

            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            testValue.value = @6;
            testValue.value = @7;
            testValue.value = @5;

            expect(ignoredValue.value).to(equal(@7));
            expect(ignoredValue).to(receive(@[@1, @2, @3, @4, @6, @7]));
        });

        it(@"can ignore nil", ^{
            ERNode<NSNumber *> *testValue = [ERNode new];
            ERNode<NSNumber *> *ignoredValue = [testValue ignore:nil];

            [ignoredValue startListenForTest];

            testValue.value = @100;
            testValue.value = nil;
            testValue.value = @200;
            testValue.value = nil;
            testValue.value = nil;
            testValue.value = @300;
            testValue.value = @400;

            expect(ignoredValue.value).to(equal(@400));
            expect(ignoredValue).to(receive(@[@100, @200, @300, @400]));
        });

        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testValue = [ERNode value:@1];
                ERNode<NSNumber *> *ignoredValue = [testValue ignore:@2];

                [checkTool checkObj:testValue];
                [checkTool checkObj:ignoredValue];
            }).to(beReleasedCorrectly());
        });
    });

    context(@"mapReplace", ^{
        it(@"can map every value to a unique value", ^{
            ERNode *value = [ERNode value:@3];
            ERNode *mappedValue = [value mapReplace:@YES];
            expect(mappedValue.value).to(equal(@YES));
            [mappedValue startListenForTest];
            value.value = @100;
            value.value = @42;
            value.value = @1;
            expect(mappedValue).to(receive(@[@YES, @YES, @YES, @YES]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *value = [ERNode value:@1000];
                ERNode<NSNumber *> *mappedValue = [value mapReplace:@1];
                
                [checkTool checkObj:value];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
    });

    context(@"distinctUntilChanged", ^{
        it(@"can filter the same value", ^{
            ERNode<NSNumber *> *value = [ERNode value:@1000];
            ERNode<NSNumber *> *mappedValue = [value distinctUntilChanged];
            
            [mappedValue startListenForTest];
            value.value = @1000;
            value.value = @2;
            value.value = @2;
            value.value = nil;
            value.value = nil;
            value.value = nil;
            value.value = @2;
            expect(mappedValue).to(receive(@[@1000, @2, NSNull.null, @2]));
        });
        
        it(@"can filter the same value and value can be empty", ^{
            ERNode<NSNumber *> *value = ERNode.new;
            ERNode<NSNumber *> *mappedValue = [value distinctUntilChanged];
            
            [mappedValue startListenForTest];
            value.value = @1000;
            value.value = @1000;
            value.value = @2;
            value.value = (id)EREmpty.empty;
            value.value = @2;
            
            expect(mappedValue).to(receive(@[@1000, @2]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *value = [ERNode value:@1000];
                ERNode<NSNumber *> *mappedValue = [value distinctUntilChanged];
                value.value = @1000;
                value.value = @2;
                value.value = @2;
                
                [checkTool checkObj:value];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
    });

    context(@"sync", ^{
        it(@"can sync two ERNode", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = [ERNode value:@2];

            [value1 syncWith:value2];
            expect(value1.hasUpstreamNode).to(beTrue());
            expect(value2.hasUpstreamNode).to(beTrue());
            expect(value1.hasDownstreamNode).to(beTrue());
            expect(value2.hasDownstreamNode).to(beTrue());
            expect(value1.value).to(equal(@2));

            value1.value = @3;
            expect(value2.value).to(equal(@3));

            value2.value = @"test";
            expect(value1.value).to(equal(@"test"));
        });

        it(@"can stop syncing", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = [ERNode value:@2];

            id<ERCancelable> cancelable = [value1 syncWith:value2];
            expect(value1.value).to(equal(@2));

            [cancelable cancel];
            
            value1.value = @3;
            expect(value2.value).notTo(equal(@3));

            value2.value = @"test";
            expect(value1.value).notTo(equal(@"test"));
        });

        it(@"can sync with transform block, and revert block", ^{
            ERNode<NSNumber *> *value1 = ERNode.new;
            ERNode<NSNumber *> *value2 = ERNode.new;

            [value1 syncWith:value2 transform:^NSNumber *(NSNumber *source) {
                return @(source.unsignedIntegerValue  * 2);
            } revert:^NSNumber *(NSNumber *target) {
                return @(target.unsignedIntegerValue  / 2);
            }];

            value2.value = @15;
            expect(value1.value).to(equal(@30));

            value1.value = @20;
            expect(value2.value).to(equal(@10));
        });
        
        //  a  <---> b  <--> C
        it(@"supports multiple sync targets on a single node", ^{
            ERNode<NSNumber *> *nodea = ERNode.new;
            ERNode<NSNumber *> *nodeb = ERNode.new;
            ERNode<NSNumber *> *nodec = ERNode.new;
            [nodea syncWith:nodeb];
            [nodec syncWith:nodeb];
            nodea.value = @10;
            expect(nodeb.value).to(equal(@10));
            expect(nodec.value).to(equal(@10));

        });
        
        //   a  <---> b  <--> C
        it(@"can be released correctly ", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *nodea = ERNode.new;
                ERNode<NSNumber *> *nodeb = ERNode.new;
                ERNode<NSNumber *> *nodec = ERNode.new;
                [nodea syncWith:nodeb];
                [nodec syncWith:nodeb];
                
                [checkTool checkObj:nodea];
                [checkTool checkObj:nodeb];
                [checkTool checkObj:nodec];
            }).to(beReleasedCorrectly());
        });
        
        // a---------b
        //   \     /
        //    \  /
        //      c
        it(@"it supports cyclic sync", ^{
            ERNode<NSNumber *> *nodea = ERNode.new;
            ERNode<NSNumber *> *nodeb = ERNode.new;
            ERNode<NSNumber *> *nodec = ERNode.new;
            [nodea syncWith:nodeb];
            [nodeb syncWith:nodec];
            [nodec syncWith:nodea];
            nodea.value = @10;
            expect(nodeb.value).to(equal(@10));
            expect(nodec.value).to(equal(@10));
            
        });
        
        // a---------b
        //   \     /
        //    \  /
        //      c
        it(@"it can release cyclic synced nodes correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *nodea = ERNode.new;
                ERNode<NSNumber *> *nodeb = ERNode.new;
                ERNode<NSNumber *> *nodec = ERNode.new;
                [nodea syncWith:nodeb];
                [nodeb syncWith:nodec];
                [nodec syncWith:nodea];
                [checkTool checkObj:nodea];
                [checkTool checkObj:nodeb];
                [checkTool checkObj:nodec];
            }).to(beReleasedCorrectly());
        });
        
        it(@"it will automatically release the nodes in a sync cycle which is not referenced outside the cycle.", ^{
            ERNode<NSNumber *> *nodea = ERNode.new;
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *nodeb = ERNode.new;
                ERNode<NSNumber *> *nodec = ERNode.new;
                
                [nodea syncWith:nodeb];
                [nodeb syncWith:nodec];
                [nodec syncWith:nodea];
                [checkTool checkObj:nodeb];
                [checkTool checkObj:nodec];
            }).to(beReleasedCorrectly());
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode *value1 = [ERNode value:@1];
                ERNode *value2 = [ERNode value:@2];

                [value1 syncWith:value2];
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
            }).to(beReleasedCorrectly());
        });
    });

    context(@"flattenMap", ^{
        it(@"can flatten map ERNode", ^{
            ERNode<NSNumber *> *numbERNode = ERNode.new;
            __block ERNode<NSNumber *> *mappedValue = nil;
            
            waitUntilTimeout(8, ^(void (^done)(void)) {
                mappedValue = [numbERNode flattenMap:^ERNode * _Nullable(NSNumber * _Nullable next) {
                    ERNode *value = ERNode.new;
                    for (int i = 0; i < next.integerValue; ++i) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            value.value = @(i);
                        });
                    }
                    
                    return value;
                }];

                [mappedValue startListenForTest];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    numbERNode.value = @1;
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    numbERNode.value = @2;
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    numbERNode.value = @3;
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    done();
                });
            });

            expect(mappedValue).to(receive(@[@0, @0, @1,  @0, @1, @2]));
        });

        it(@"should raise an exception when block return value isn't an ERNode", ^{
            ERNode<NSNumber *> *numbERNode = ERNode.new;
            ERNode<NSNumber *> *mappedValue __attribute__((unused)) = [numbERNode flattenMap:^ERNode * _Nullable(NSNumber * _Nullable next) {
                return nil;
            }];

            expectAction(^{
                numbERNode.value = @1;
            }).to(raiseException().named(ERNodeExceptionName).reason(ERExceptionReason_FlattenOrFlattenMapNextValueNotERNode));
        });

        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *numbERNode = ERNode.new;
                ERNode<NSNumber *> *mappedValue = [numbERNode flattenMap:^ERNode * _Nullable(NSNumber * _Nullable next) {
                    ERNode *value = ERNode.new;
                    for (int i = 0; i < next.integerValue; ++i) {
                        value.value = @(i);
                    }

                    return value;
                }];
                [checkTool checkObj:numbERNode];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"flatten", ^{
        it(@"can flatten ERNode", ^{
            ERNode<ERNode<NSNumber *> *> *highOrdERNode = [ERNode value:[ERNode value:@1]];
            ERNode<NSNumber *> *flattenValue = [highOrdERNode flatten];
            [flattenValue startListenForTest];
            ERNode<NSNumber *> *value1 = [ERNode value:@2];
            highOrdERNode.value = value1;
            value1.value = @3;
            ERNode<NSNumber *> *value2 = [ERNode value:@4];
            highOrdERNode.value = value2;
            value2.value = @5;

            expect(flattenValue).to(receive(@[@1, @2, @3, @4, @5]));
        });

        it(@"should raise an exception when ERNode is not a high order ERNode", ^{
            ERNode<ERNode<NSNumber *> *> *highOrdERNode = [ERNode value:@3];

            expectAction(^{
                [highOrdERNode flatten];
            }).to(raiseException().named(ERNodeExceptionName).reason(ERExceptionReason_FlattenOrFlattenMapNextValueNotERNode));
            
            highOrdERNode = [ERNode value:[ERNode value:@3]];
            ERNode<NSNumber *> *mappedValue __attribute__((unused)) = [highOrdERNode flatten];
            
            expectAction(^{
                highOrdERNode.value = (id)@3;
            }).to(raiseException().named(ERNodeExceptionName).reason(ERExceptionReason_FlattenOrFlattenMapNextValueNotERNode));
        });

        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                ERNode<ERNode<NSNumber *> *> *highOrdERNode = [ERNode value:[ERNode value:@1]];
                ERNode<NSNumber *> *flattenValue = [highOrdERNode flatten];
                [checkTool checkObj:highOrdERNode];
                [checkTool checkObj:flattenValue];
            }).to(beReleasedCorrectly());
        });
    });

    context(@"combine", ^{
        it(@"can combine each value to an array", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSString *> *value2 = [ERNode value:@"1"];
            
            ERNode<ZTuple2<NSNumber *, NSString *> *> *value3 = [ERNode combine:@[value1, value2]];
            
            [value3 startListenForTest];

            expect(value3.value).to(equal(ZTuple(@1, @"1")));

            value1.value = @2;
            value2.value = @"2";
            value1.value = @3;
            
            expect(value3).to(receive(@[ZTuple(@1, @"1"), ZTuple(@2, @"1"), ZTuple(@2, @"2"), ZTuple(@3, @"2")]));
        });

        it(@"can support nil value", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = [ERNode value:@"1"];

            ERNode<ZTuple2<NSNumber *, NSString *> *> *value3 = [ERNode combine:@[value1, value2]];

            [value3 startListenForTest];

            value1.value = nil;
            value2.value = @"2";
            value1.value = @3;
    
            expect(value3).to(receive(@[ZTuple(@1, @"1"), ZTuple(nil, @"1"), ZTuple(nil, @"2"), ZTuple(@3, @"2")]));
        });

        it(@"can add an upstream after combining", ^{
            ERNode *valueA = [ERNode value:@1];
            ERNode *valueB = [ERNode value:@"1"];
            ERNode *valueC = [ERNode value:@NO];

            ERNode<ZTuple2<NSNumber *, NSString *> *> *value = [ERNode combine:@[valueA, valueB]];
            expect(value.value).to(equal(ZTuple(@1, @"1")));
            [value startListenForTest];

            [value linkTo:valueC];
            expect(value.value).to(equal(@NO));

            valueA.value = @2;
            valueC.value = @YES;
            valueB.value = @"2";

            expect(value).to(receive(@[ZTuple(@1, @"1"), @NO, ZTuple(@2, @"1"), @YES, ZTuple(@2, @"2"),]));
        });

        it(@"should not receive new value when remove an upstream after combining", ^{
            ERNode<NSNumber *> *valueA = [ERNode value:@1];
            ERNode<NSString *> *valueB = [ERNode value:@"1"];
            ERNode<NSNumber *> *valueC = [ERNode value:@NO];

            ERNode<ZTuple3<NSNumber *, NSString *, NSNumber *> *> *value = [ERNode combine:@[valueA, valueB, valueC]];
            [value startListenForTest];
            [valueB removeDownstreamNode:value];

            valueB.value = @"2";
            expect(value.value).notTo(equal(ZTuple(@1, @"2", @NO)));

            valueC.value = @YES;
            expect(value).to(receive(@[ZTuple(@1, @"1", @NO)]));
        });

        it(@"can auto remove a deallocated upstream after combining", ^{
            ERNode *valueA = [ERNode value:@1];
            __weak ERNode *valueB = nil;
            ERNode *valueC = [ERNode value:@NO];
            ERNode *value = nil;
            
            @autoreleasepool {
                ERNode *newValue = ERNode.new;
                valueB = newValue;
                value = [ERNode combine:@[valueA, valueB, valueC]];
                [value startListenForTest];
                expect(value).to(beEmptyValue());
            }
            expect(value.value).notTo(equal(@[@1, @NO]));
        });

        it(@"can use macro define block easily", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = [ERNode value:@1];

            ERNode *value3 = [ERCombine(value1, value2) mapEach:^id(id arg1, id arg2) {
                return nil;
            }];

            expect(value3.value).to(beNil());
        });

        it(@"can combine value's changes each time", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = [ERNode value:@1];

            ERNode *value3 = [ERCombine(value1, value2) mapEach:^id(id arg1, id arg2) {
                return @([arg1 integerValue] + [arg2 integerValue]);
            }];

            [value3 startListenForTest];

            value1.value = @2;
            value1.value = @5;
            value2.value = @7;
            value2.value = @1;

            expect(value3.value).to(equal(@6));
            expect(value3).to(receive(@[@2, @3, @6, @12, @6]));
        });

        it(@"should auto cancel mapEach if add / remove upstream", ^{
            ERNode *valueA = [ERNode value:@1];
            ERNode *valueB = [ERNode value:@1];

            ERNode *value = [ERCombine(valueA, valueB) mapEach:^id(id arg1, id arg2) {
                return @([arg1 integerValue] + [arg2 integerValue]);
            }];

            [value startListenForTest];

            valueA.value = @2;
            valueA.value = @5;
            valueB.value = @7;

            expectAction(^(){
                value.upstreamNodes.firstObject.value = @"";
            }).to(raiseException().named(ERNodeExceptionName).reason(ERExceptionReason_MapEachNextValueNotTuple));
        });

        it(@"won't get a combined value until each upstream is not empty", ^{
            ERNode<NSNumber *> *value1 = [ERNode new];
            ERNode<NSNumber *> *value2 = [ERNode new];

            ERNode<ZTuple2<NSNumber *, NSNumber *> *> *value3 = [ERNode combine:@[value1, value2]];
            expect(value3).to(beEmptyValue());

            [value3 startListenForTest];

            value1.value = @1;
            expect(value3).to(beEmptyValue());

            value2.value = @2;
            expect(value3).notTo(beEmptyValue());

            expect(value3).to(receive(@[ZTuple(@1, @2)]));
        });

        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                ERNode *value1 = [ERNode value:@1];
                ERNode *value2 = [ERNode value:@1];
                ERNode *value3 = [ERNode combine:@[value1, value2]];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
                [checkTool checkObj:value3];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });

    context(@"merge", ^{
        it(@"can merge values", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = [ERNode value:@2];

            ERNode *value3 = [ERNode merge:@[value1, value2]];
            
            [value3 startListenForTest];

            expect(value3.value).to(equal(@2));

            value1.value = @3;
            value2.value = @9;
            value1.value = @3;

            expect(value3).to(receive(@[@2, @3, @9, @3]));
        });

        it(@"can add an upstream after merging", ^{
            ERNode *valueA = [ERNode value:@1];
            ERNode *valueB = [ERNode value:@"1"];
            ERNode *valueC = [ERNode value:@NO];
            
            ERNode *value = [ERNode merge:@[valueA, valueB]];
            expect(value.value).to(equal(@"1"));
            [value startListenForTest];
            
            [value linkTo:valueC];
            expect(value.value).to(equal(@NO));
            
            valueA.value = @2;
            valueB.value = @"2";
            valueC.value = @YES;
            
            expect(value).to(receive(@[@"1", @NO, @2, @"2", @YES]));
        });
        
        it(@"can remove an upstream after merging", ^{
            ERNode *valueA = [ERNode value:@1];
            ERNode *valueB = ERNode.new;
            ERNode *valueC = [ERNode value:@NO];
            
            ERNode *value = [ERNode merge:@[valueA, valueB, valueC]];
            [value startListenForTest];
            expect(value.value).to(equal(@NO));
            [valueB removeDownstreamNode:value];
            
            valueB.value = @"a";
            
            expect(value.value).notTo(equal(@"a"));
            
            valueC.value = @YES;
            expect(value).to(receive(@[@NO, @YES]));
        });
        
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                ERNode *value1 = [ERNode value:@1];
                ERNode *value2 = [ERNode value:@1];
                ERNode *value3 = [ERNode merge:@[value1, value2]];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
                [checkTool checkObj:value3];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });

    context(@"zip", ^{
        it(@"can zip several ERNodes", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@0];
            ERNode<NSString *> *value2 = [ERNode value:@"a"];
            ERNode<NSString *> *value3 = [ERNode value:@"A"];

            ERNode<ZTuple3<NSNumber *, NSString *, NSString *> *> *zippedValue1 = [ERNode zip:@[value1, value2, value3]];
            [zippedValue1 startListenForTest];
            expect(zippedValue1.value).to(equal(ZTuple(@0, @"a", @"A")));
            value1.value = @1;
            value1.value = @2;
            value1.value = @3;
            value2.value = @"b";
            value1.value = @4;
            value2.value = @"c";
            expect(zippedValue1.value).to(equal(ZTuple(@0, @"a", @"A")));
            value3.value = @"B";
            expect(zippedValue1.value).to(equal(ZTuple(@1, @"b", @"B")));
            value3.value = @"C";
            expect(zippedValue1.value).to(equal(ZTuple(@2, @"c", @"C")));
            expect(zippedValue1).to(receive(@[ZTuple(@0, @"a", @"A"), ZTuple(@1, @"b", @"B"), ZTuple(@2, @"c", @"C")]));
        });

        it(@"keeps empty until every upstream has a non-empty value", ^{
            ERNode<NSNumber *> *value1 = [ERNode new];
            ERNode<NSString *> *value2 = [ERNode new];
            ERNode<NSString *> *value3 = [ERNode value:@"A"];
            ERNode *zippedValue = [ERNode zip:@[value1, value2, value3]];
            [zippedValue startListenForTest];
            expect(zippedValue).to(beEmptyValue());
            value1.value = @100;
            value2.value = @"bbb";
            expect(zippedValue.value).to(equal(ZTuple(@100, @"bbb", @"A")));
            expect(zippedValue).to(receive(@[ZTuple(@100, @"bbb", @"A")]));
        });

        it(@"can support nil value", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:nil];
            ERNode<NSString *> *value2 = [ERNode value:@"a"];
            ERNode<NSString *> *value3 = [ERNode value:@"A"];

            ERNode<ZTuple3<NSNumber *, NSString *, NSString *> *> *zippedValue = [ERNode zip:@[value1, value2, value3]];
            [zippedValue startListenForTest];
            expect(zippedValue).to(receive(@[ZTuple(nil, @"a", @"A")]));
        });

        it(@"can add upstreamNodes after zipping", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:nil];
            ERNode<NSString *> *value2 = [ERNode value:@"a"];
            ERNode<NSString *> *value3 = [ERNode new];

            ERNode<ZTuple2<NSNumber *, NSString *> *> *zippedValue = [ERNode zip:@[value1, value2]];
            [zippedValue startListenForTest];
            expect(zippedValue.value).to(equal(ZTuple(nil, @"a")));

            [zippedValue linkTo:value3];
            value3.value = @"AAA";
            expect(zippedValue.value).to(equal(@"AAA"));
            value1.value = @123;
            value1.value = @333;
            value1.value = @444;
            value2.value = @"aaa";
            expect(zippedValue.value).to(equal(ZTuple(@123, @"aaa")));

            expect(zippedValue).to(receive(@[ZTuple(nil, @"a"), @"AAA", ZTuple(@123, @"aaa")]));
        });

        it(@"should not receive new value when remove upstreamNodes after zipping", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@10];
            ERNode<NSString *> *value2 = [ERNode value:@"a"];
            ERNode<NSString *> *value3 = [ERNode value:@"A"];
           
            ERNode<ZTuple3<NSNumber *, NSString *, NSString *> *> *zippedValue = [ERNode zip:@[value1, value2, value3]];
            [zippedValue startListenForTest];
        
            expect(zippedValue.value).to(equal(ZTuple(@10, @"a", @"A")));
            [zippedValue removeUpstreamNode:value1];
            value2.value = @"b";
            value2.value = @"c";
            value2.value = @"d";
            value3.value = @"B";
            value3.value = @"C";
            value1.value = @100;
            expect(zippedValue).to(receive(@[ZTuple(@10, @"a", @"A")]));
        });

        it(@"can use a macro to zip values", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@100];
            ERNode<NSString *> *value2 = [ERNode value:@"A"];

            ERNode *value3 = [ERZip(value1, value2) mapEach:^id _Nonnull(id _Nonnull arg0, id _Nonnull arg1) {
                return [NSString stringWithFormat:@"%@: %@", arg0, arg1];
            }];

            [value3 startListenForTest];

            value1.value = @200;
            value1.value = @500;
            value2.value = @"BBB";
            value2.value = @"CCCCC";

            expect(value3.value).to(equal(@"500: CCCCC"));
            expect(value3).to(receive(@[@"100: A", @"200: BBB", @"500: CCCCC"]));
        });

        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                ERNode *value1 = [ERNode value:@1];
                ERNode *value2 = [ERNode value:@1];
                ERNode *value3 = [ERNode zip:@[value1, value2]];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
                [checkTool checkObj:value3];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });

    context(@"throttle", ^{
        xit(@"only receives value which lasts long enough", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            ERNode<NSString *> *value = [ERNode value:@""];
            ERNode<NSString *> *throttledValue = [value throttle:0.1];
            [throttledValue startListenForTest];
            
            waitUntil(^(void (^done)(void)) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), q, ^{
                    value.value = @"r";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15 * NSEC_PER_SEC), q, ^{
                    value.value = @"re";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), q, ^{
                    value.value = @"res";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), q, ^{
                    value.value = @"resu";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.36 * NSEC_PER_SEC), q, ^{
                    value.value = @"resul";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.37 * NSEC_PER_SEC), q, ^{
                    value.value = @"result";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.49 * NSEC_PER_SEC), q, ^{
                    done();
                });
            });
            
            expect(throttledValue).to(receive(@[@"", @"res", @"result"]));
        });

        it(@"ignores empty values", ^{
            ERNode<NSString *> *value = [ERNode new];
            ERNode<NSString *> *throttledValue = [value throttle:0.1];
            [throttledValue startListenForTest];
            
            waitUntil(^(void (^done)(void)) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    value.value = @"r";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.13 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    value.value = @"re";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.14 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    value.value = @"res";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.26 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    value.value = @"resu";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.39 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    done();
                });
            });
            
            expect(throttledValue).to(receive(@[@"res", @"resu"]));
        });

        it(@"should invoke the listeners in the main queue if it was created in the main queue", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            __block ERNode *throttledValue = nil;
            
            waitUntil(^(void (^done)(void)) {
                id<ERListener> listener = [[ERBlockListener alloc] initWithBlock:^(id  _Nullable next) {
                    expect([NSThread isMainThread]).to(beTruthy());
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ERNode *value = [ERNode value:@100];
                    throttledValue = [value throttle:0.1];
                    [throttledValue startListenForTest];
                    [throttledValue addListener:listener];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), q, ^{
                        value.value = @200;
                    });
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), q, ^{
                        value.value = @300;
                        done();
                    });
                });
            });
            
            expect(throttledValue).to(receive(@[@100, @200]));
        });

        it(@"should invoke the listeners in a background queue if it was created in a background queue", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            __block ERNode *throttledValue = nil;
            
            waitUntil(^(void (^done)(void)) {
                id<ERListener> listener = [[ERBlockListener alloc] initWithBlock:^(id  _Nullable next) {
                    expect([NSThread isMainThread]).to(beFalsy());
                }];
                dispatch_async(q, ^{
                    ERNode *value = [ERNode value:@100];
                    throttledValue = [value throttle:0.1 queue:q];
                    [throttledValue startListenForTest];
                    [throttledValue addListener:listener];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        value.value = @200;
                    });
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        value.value = @300;
                        done();
                    });
                });
            });
            
            expect(throttledValue).to(receive(@[@100, @200]));
        });

        it(@"can invoke listenes in a specified queue", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            __block ERNode *throttledValue = nil;
            
            waitUntil(^(void (^done)(void)) {
                id<ERListener> listener = [[ERBlockListener alloc] initWithBlock:^(id  _Nullable next) {
                    expect([NSThread isMainThread]).to(beTruthy());
                }];
                dispatch_async(q, ^{
                    ERNode *value = [ERNode value:@100];
                    throttledValue = [value throttle:0.1 queue:dispatch_get_main_queue()];
                    [throttledValue startListenForTest];
                    [throttledValue addListener:listener];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), q, ^{
                        value.value = @200;
                    });
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), q, ^{
                        value.value = @300;
                        done();
                    });
                });
            });
            
            expect(throttledValue).to(receive(@[@100, @200]));

            __block ERNode *throttledValue2 = nil;

            waitUntil(^(void (^done)(void)) {
                id<ERListener> listener = [[ERBlockListener alloc] initWithBlock:^(id  _Nullable next) {
                    expect([NSThread isMainThread]).to(beFalsy());
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ERNode *value = [ERNode value:@1000];
                    throttledValue2 = [value throttle:0.1 queue:q];
                    [throttledValue2 startListenForTest];
                    [throttledValue2 addListener:listener];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        value.value = @2000;
                    });
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        value.value = @3000;
                        done();
                    });
                });
            });
            
            expect(throttledValue2).to(receive(@[@1000, @2000]));
        });
        
        it(@"ERNode throttle with a number lessthan zero should raise an asset", ^(){
            ERNode *value = [ERNode value:@1000];
          
            assertExpect(^{
                [value throttle:-1];
            }).to(hasParameterAssert());
        });

        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                waitUntil(^(void (^done)(void)) {
                    ERNode<NSNumber *> *value = [ERNode value:@10];
                    
                    ERNode<NSNumber *> *throttledValue = [value throttle:0.5];
                    ERNode<NSNumber *> *throttledValue2 = [value throttle:0.2 queue:dispatch_get_main_queue()];
                    [throttledValue listen:^(NSNumber * _Nullable next) {
                        
                    }];
                    [throttledValue2 listen:^(NSNumber * _Nullable next) {
                        
                    }];
                    [checkTool checkObj:value];
                    [checkTool checkObj:throttledValue];
                    [checkTool checkObj:throttledValue2];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        done();
                    });
                });
            };
                      
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });
});

QuickSpecEnd
