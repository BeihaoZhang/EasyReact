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

QuickSpecBegin(EZRNodeOperation)

describe(@"EZRNode", ^{
    it(@"can fork a new node", ^{
        EZRMutableNode<NSNumber *> *oriNode = EZRMutableNode.new;
        EZRNode<NSNumber *> *forkedNode = [oriNode fork];
        expect(forkedNode).notTo(beNil());
        expect(forkedNode.upstreamNodes).to(contain(oriNode));
        NSObject *listener = [NSObject new];
        [forkedNode startListenForTestWithObj:listener];
        oriNode.value = @10;
        expect(forkedNode).to(receive(@[@10]));
        expect(forkedNode.value).to(equal(@10));
    });
    
    it(@"can be released correctly when using fork operation", ^{
        expectCheckTool(^(CheckReleaseTool *checkTool) {
            EZRNode<NSNumber *> *oriNode = EZRNode.new;
            EZRNode<NSNumber *> *forkedNode = [oriNode fork];
            [checkTool checkObj:oriNode];
            [checkTool checkObj:forkedNode];
        }).to(beReleasedCorrectly());
    });
    
    it(@"can be delivered on a specific queue", ^{
        dispatch_queue_t queue = dispatch_queue_create("com.er.deliverQueue", DISPATCH_QUEUE_SERIAL);
        EZRMutableNode<NSNumber *> *oriNode = EZRMutableNode.new;
        EZRNode<NSNumber *> *testNode = [oriNode deliverOn:queue];
        NSObject *listener = [NSObject new];
        [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
            expect([NSThread currentThread].isMainThread).to(beFalse());
        }];
        oriNode.value = @1;
    });
    
    it(@"can be delivered on mainQueue", ^{
        dispatch_queue_t queue = dispatch_queue_create("com.er.deliverQueue", DISPATCH_QUEUE_SERIAL);
        EZRMutableNode<NSNumber *> *oriNode = EZRMutableNode.new;
        EZRNode<NSNumber *> *testNode = [oriNode deliverOnMainQueue];
        NSObject *listener = [NSObject new];
        [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
            expect([NSThread currentThread].isMainThread).to(beTrue());
        }];
        dispatch_async(queue, ^{
            oriNode.value = @1;
        });
    });
    
    it(@"can be listened on a special queue use listenOn:queue no mather what queue the node is delivered on", ^{
        dispatch_queue_t sendQueue = dispatch_queue_create("com.er.deliverQueue1", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t listenerQueue = dispatch_queue_create("com.er.listenerQueue", DISPATCH_QUEUE_SERIAL);
        
        EZRMutableNode<NSNumber *> *oriNode = EZRMutableNode.new;
        EZRNode<NSNumber *> *testNode = [oriNode deliverOn:sendQueue];
        NSObject *listener = [NSObject new];
        
        [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
            expect([NSThread currentThread].isMainThread).to(beFalse());
        }];
        [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
            expect([NSThread currentThread].isMainThread).to(beFalse());
        }
                                               on:listenerQueue];
        [[testNode listenedBy:listener] withBlockOnMainQueue:^(NSNumber * _Nullable next) {
            expect([NSThread currentThread].isMainThread).to(beTrue());
        }];
        oriNode.value  = @1;
        dispatch_async(sendQueue, ^{
            oriNode.value  = @2;
        });
    });
    
    it(@"should raise an asset if it was delivered on a NULL queue ",^{
        assertExpect(^{
            dispatch_queue_t queue = NULL;
            EZRNode<NSNumber *> *oriNode = EZRNode.new;
            [oriNode deliverOn:queue];
        }).to(hasParameterAssert());
    });
    
    it(@"can get a new node through map operation", ^{
        EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
        EZRNode *mappedValue = [testValue map:^id(NSNumber *next) {
            return @(next.integerValue * 2);
        }];
        NSObject *listener = [NSObject new];
        [mappedValue startListenForTestWithObj:listener];
        
        testValue.value = @6;
        testValue.value = @8;
        
        expect(mappedValue.value).to(equal(@16));
        expect(mappedValue).to(receive(@[@2, @12, @16]));
    });
    
    it(@"can be released correctly when using map operation", ^{
        expectCheckTool(^(CheckReleaseTool *checkTool) {
            EZRNode<NSNumber *> *testValue = [EZRNode value:@1];
            EZRNode *mappedValue = [testValue map:^id(NSNumber *next) {
                return @(next.integerValue * 2);
            }];
            [checkTool checkObj:testValue];
            [checkTool checkObj:mappedValue];
        }).to(beReleasedCorrectly());
    });
    
    it(@"can filter to a new node", ^{
        EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
        EZRNode *filteredValue = [testValue filter:^BOOL(NSNumber *next) {
            return next.integerValue > 2;
        }];
        
        expect(filteredValue).to(beEmptyValue());
        NSObject *listener = [NSObject new];
        [filteredValue startListenForTestWithObj:listener];
        
        testValue.value = @8;
        testValue.value = @0;
        testValue.value = @5;
        testValue.value = @2;
        
        expect(filteredValue.value).to(equal(@5));
        expect(filteredValue).to(receive(@[@8, @5]));
    });
    
    it(@"can be released correctly when using filter operation", ^{
        expectCheckTool(^(CheckReleaseTool *checkTool) {
            EZRNode<NSNumber *> *testValue = [EZRNode value:@1];
            EZRNode *filteredValue = [testValue filter:^BOOL(NSNumber *next) {
                return next.integerValue > 2;
            }];
            
            [checkTool checkObj:testValue];
            [checkTool checkObj:filteredValue];
        }).to(beReleasedCorrectly());
    });
    
    context(@"- take: operation,", ^{
        it(@" should not receive new change after N values changed", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *takenValue = [testValue take:5];
            NSObject *listener = [NSObject new];
            [takenValue startListenForTestWithObj:listener];
            
            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            expect(takenValue.value).to(equal(@5));
            testValue.value = @10;
            expect(takenValue.value).notTo(equal(10));
        });
        
        it(@"can change upstream", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *takenValue = [testValue take:5];
            NSObject *listener = [NSObject new];
            [takenValue startListenForTestWithObj:listener];
            
            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            expect(takenValue.value).to(equal(@5));
            testValue.value = @10;
            expect(takenValue.value).notTo(equal(10));
            expect(takenValue).to(receive(@[@1, @2, @3, @4, @5]));
            EZRTransform *transform = takenValue.upstreamTransforms.firstObject;
            EZRMutableNode *anotherNode = [EZRMutableNode value:@21];
            transform.from = anotherNode;
            
            anotherNode.value = @22;
            anotherNode.value = @23;
            anotherNode.value = @24;
            anotherNode.value = @25;
            anotherNode.value = @26;
            expect(takenValue.value).to(equal(@25));
            expect(takenValue).to(receive(@[@1, @2, @3, @4, @5, @21, @22, @23, @24, @25]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *testValue = [EZRNode value:@1];
                EZRNode<NSNumber *> *takenValue = [testValue take:5];;
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:takenValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- skip: operation,", ^{
        it(@"should skip first N values to make a new node", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *skippedValue = [testValue skip:2];
            NSObject *listener = [NSObject new];
            [skippedValue startListenForTestWithObj:listener];
            
            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            testValue.value = @6;
            testValue.value = @7;
            
            expect(skippedValue.value).to(equal(@7));
            expect(skippedValue).to(receive(@[@3, @4, @5, @6, @7]));
        });
        
        it(@"can change upstream", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *skippedValue = [testValue skip:2];
            NSObject *listener = [NSObject new];
            [skippedValue startListenForTestWithObj:listener];
            
            testValue.value = @2;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            testValue.value = @6;
            testValue.value = @7;
            
            expect(skippedValue.value).to(equal(@7));
            expect(skippedValue).to(receive(@[@3, @4, @5, @6, @7]));
            
            EZRTransform *transform = skippedValue.upstreamTransforms.firstObject;
            EZRMutableNode *anotherNode = [EZRMutableNode value:@10];
            transform.from = anotherNode;
            anotherNode.value = @11;
            anotherNode.value = @12;
            anotherNode.value = @13;
            anotherNode.value = @14;
            expect(skippedValue.value).to(equal(@14));
            expect(skippedValue).to(receive(@[@3, @4, @5, @6, @7, @12, @13, @14]));
            
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *testValue = [EZRNode value:@1];
                EZRNode<NSNumber *> *skippedValue = [testValue skip:2];
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:skippedValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- ignore: operation,", ^{
        it(@"can ignore the given value", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *ignoredValue = [testValue ignore:@5];
            NSObject *listener = [NSObject new];
            [ignoredValue startListenForTestWithObj:listener];
            
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
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode new];
            EZRNode<NSNumber *> *ignoredValue = [testValue ignore:nil];
            NSObject *listener = [NSObject new];
            [ignoredValue startListenForTestWithObj:listener];
            
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
                EZRNode<NSNumber *> *testValue = [EZRNode value:@1];
                EZRNode<NSNumber *> *ignoredValue = [testValue ignore:@2];
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:ignoredValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- select: operation", ^{
        it(@"can select the given value", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *selectedValue = [testValue select:@5];
            NSObject *listener = [NSObject new];
            [selectedValue startListenForTestWithObj:listener];
            
            testValue.value = @2;
            testValue.value = @5;
            testValue.value = @3;
            testValue.value = @4;
            testValue.value = @5;
            testValue.value = @5;
            testValue.value = @6;
            testValue.value = @7;
            testValue.value = @5;
            
            expect(selectedValue.value).to(equal(@5));
            expect(selectedValue).to(receive(@[@5, @5, @5, @5]));
        });
        
        it(@"can select nil", ^{
            EZRMutableNode<NSNumber *> *testValue = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *selectedValue = [testValue select:nil];
            NSObject *listener = [NSObject new];
            [selectedValue startListenForTestWithObj:listener];
            
            testValue.value = @2;
            testValue.value = nil;
            testValue.value = @4;
            testValue.value = nil;
            testValue.value = @6;
            testValue.value = @5;
            
            expect(selectedValue.value).to(beNil());
            expect(selectedValue).to(receive(@[NSNull.null, NSNull.null]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *testValue = [EZRNode value:@1];
                EZRNode<NSNumber *> *selectedValue = [testValue select:nil];
                
                [checkTool checkObj:testValue];
                [checkTool checkObj:selectedValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- then: operation,", ^{
        it(@"can be used to split node values when node transform have different way", ^{
            EZRMutableNode <NSNumber *> *node = [EZRMutableNode new];
            __block EZRNode <NSNumber *> *evenNode;
            EZRNode <NSNumber *> *oddNode = [[node then:^(EZRNode<NSNumber *> * _Nonnull node) {
                evenNode = [node filter:^BOOL(NSNumber * _Nullable next) {
                    return [next integerValue] % 2 == 0;
                }];
            }] filter:^BOOL(NSNumber * _Nullable next) {
                return [next integerValue] % 2 != 0;
            }];
            NSObject *listener = [NSObject new];
            [evenNode startListenForTestWithObj:listener];
            [oddNode startListenForTestWithObj:listener];
            node.value = @1;
            node.value = @2;
            node.value = @3;
            node.value = @4;
            expect(evenNode).to(receive(@[@2, @4]));
            expect(oddNode).to(receive(@[@1, @3]));
            
        });
        
        it(@"the thenblock arguements as same as operator object", ^{
            EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode new];
            __block EZRNode<NSNumber *> *node2 = nil;
            EZRNode<NSNumber *> *node3 = [node1 then:^(EZRNode<NSNumber *> * _Nonnull node) {
                node2 = node;
            }];
            node1.value = @1;
            expect(node2).to(beIdenticalTo(node1));
            expect(node3).to(beIdenticalTo(node1));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode new];
                __block EZRNode<NSNumber *> *node2 = nil;
                EZRNode<NSNumber *> *node3 = [node1 then:^(EZRNode<NSNumber *> * _Nonnull node) {
                    node2 = node;
                }];
                node1.value = @1;
                [checkTool checkObj:node1];
                [checkTool checkObj:node2];
                [checkTool checkObj:node3];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- mapReplace: operation,", ^{
        it(@"can map any value to a unique value", ^{
            EZRMutableNode *value = [EZRMutableNode value:@3];
            EZRNode *mappedValue = [value mapReplace:@YES];
            expect(mappedValue.value).to(equal(@YES));
            NSObject *listener = [NSObject new];
            [mappedValue startListenForTestWithObj:listener];
            value.value = @100;
            value.value = @42;
            value.value = @1;
            expect(mappedValue).to(receive(@[@YES, @YES, @YES, @YES]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *value = [EZRNode value:@1000];
                EZRNode<NSNumber *> *mappedValue = [value mapReplace:@1];
                
                [checkTool checkObj:value];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- distinctUntilChanged operation", ^{
        it(@"can filter the same value", ^{
            EZRMutableNode<NSNumber *> *value = [EZRMutableNode value:@1000];
            EZRNode<NSNumber *> *mappedValue = [value distinctUntilChanged];
            NSObject *listener = [NSObject new];
            [mappedValue startListenForTestWithObj:listener];
            value.value = @1000;
            value.value = @2;
            value.value = @2;
            value.value = nil;
            value.value = nil;
            value.value = nil;
            value.value = @2;
            expect(mappedValue).to(receive(@[@1000, @2, NSNull.null, @2]));
        });
        
        it(@"can filter the same value and the value can be empty", ^{
            EZRMutableNode<NSNumber *> *value = EZRMutableNode.new;
            EZRNode<NSNumber *> *mappedValue = [value distinctUntilChanged];
            
            NSObject *listener = [NSObject new];
            [mappedValue startListenForTestWithObj:listener];
            value.value = @1000;
            value.value = @1000;
            value.value = @2;
            value.value = (id)EZREmpty.empty;
            value.value = @2;
            
            expect(mappedValue).to(receive(@[@1000, @2]));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRMutableNode<NSNumber *> *value = [EZRMutableNode value:@1000];
                EZRNode<NSNumber *> *mappedValue = [value distinctUntilChanged];
                value.value = @1000;
                value.value = @2;
                value.value = @2;
                
                [checkTool checkObj:value];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- syncWith: operation,", ^{
        it(@"can sync with another EZRNode", ^{
            EZRMutableNode *value1 = [EZRMutableNode value:@1];
            EZRMutableNode *value2 = [EZRMutableNode value:@2];
            
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
            EZRMutableNode *value1 = [EZRMutableNode value:@1];
            EZRMutableNode *value2 = [EZRMutableNode value:@2];
            
            id<EZRCancelable> cancelable = [value1 syncWith:value2];
            expect(value1.value).to(equal(@2));
            
            [cancelable cancel];
            
            value1.value = @3;
            expect(value2.value).notTo(equal(@3));
            
            value2.value = @"test";
            expect(value1.value).notTo(equal(@"test"));
        });
    
        it(@"can sync with transform block, and revert block", ^{
            EZRMutableNode<NSNumber *> *value1 = EZRMutableNode.new;
            EZRMutableNode<NSNumber *> *value2 = EZRMutableNode.new;
            
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
            EZRMutableNode<NSNumber *> *nodea = EZRMutableNode.new;
            EZRNode<NSNumber *> *nodeb = EZRNode.new;
            EZRNode<NSNumber *> *nodec = EZRNode.new;
            [nodea syncWith:nodeb];
            [nodec syncWith:nodeb];
            nodea.value = @10;
            expect(nodeb.value).to(equal(@10));
            expect(nodec.value).to(equal(@10));
            
        });
    
        //   a  <---> b  <--> C
        it(@"can be released correctly when cancelling the sync link", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *nodea = EZRNode.new;
                EZRNode<NSNumber *> *nodeb = EZRNode.new;
                EZRNode<NSNumber *> *nodec = EZRNode.new;
                id<EZRCancelable> cancel1 = [nodea syncWith:nodeb];
                id<EZRCancelable> cancel2 = [nodec syncWith:nodeb];
                [cancel1 cancel];
                [cancel2 cancel];
                [checkTool checkObj:nodea];
                [checkTool checkObj:nodeb];
                [checkTool checkObj:nodec];
            }).to(beReleasedCorrectly());
        });
        
        // a---------b
        //   \     /
        //    \  /
        //      c
        it(@"supports cycle sync", ^{
            EZRMutableNode<NSNumber *> *nodea = EZRMutableNode.new;
            EZRNode<NSNumber *> *nodeb = EZRNode.new;
            EZRNode<NSNumber *> *nodec = EZRNode.new;
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
        it(@"should not be released automatically when the nodes are in a sync cycle with no other reference outside the cycle.", ^{
            EZRNode<NSNumber *> *nodea = EZRNode.new;
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *nodeb = EZRNode.new;
                EZRNode<NSNumber *> *nodec = EZRNode.new;
                
                [nodea syncWith:nodeb];
                [nodeb syncWith:nodec];
                [nodec syncWith:nodea];
                [checkTool checkObj:nodeb];
                [checkTool checkObj:nodec];
            }).notTo(beReleasedCorrectly());
        });
    
        // a---------b
        //   \     /
        //    \  /
        //      c
        it(@"in sync cycle can be released correctly when cancelling the sync link manually", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *nodea = EZRNode.new;
                EZRNode<NSNumber *> *nodeb = EZRNode.new;
                EZRNode<NSNumber *> *nodec = EZRNode.new;
                id<EZRCancelable> cancel1 = [nodea syncWith:nodeb];
                id<EZRCancelable> cancel2 = [nodeb syncWith:nodec];
                id<EZRCancelable> cancel3 = [nodec syncWith:nodea];
                [cancel1 cancel];
                [cancel2 cancel];
                [cancel3 cancel];
                [checkTool checkObj:nodea];
                [checkTool checkObj:nodeb];
                [checkTool checkObj:nodec];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- flattenMap: operation,", ^{
        it(@"can flatten map EZRNode", ^{
            EZRMutableNode<NSNumber *> *numbEZRNode = EZRMutableNode.new;
            __block EZRNode<NSNumber *> *mappedValue = nil;
            NSObject *listener = [NSObject new];
            
            waitUntilTimeout(8, ^(void (^done)(void)) {
                mappedValue = [numbEZRNode flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
                    EZRMutableNode *value = EZRMutableNode.new;
                    for (int i = 0; i < next.integerValue; ++i) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            value.value = @(i);
                        });
                    }
                    
                    return value;
                }];
                
                [mappedValue startListenForTestWithObj:listener];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    numbEZRNode.value = @1;
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    numbEZRNode.value = @2;
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    numbEZRNode.value = @3;
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    done();
                });
            });
            
            expect(mappedValue).to(receive(@[@0, @0, @1,  @0, @1, @2]));
        });
    
        it(@"should raise an exception when the block return value isn't an EZRNode", ^{
            EZRMutableNode<NSNumber *> *numbEZRNode = EZRMutableNode.new;
            EZRNode<NSNumber *> *mappedValue __attribute__((unused)) = [numbEZRNode flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
                return nil;
            }];
            
            expectAction(^{
                numbEZRNode.value = @1;
            }).to(raiseException().named(EZRNodeExceptionName).reason(EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode));
        });
    
        it(@"should work correctly in a flattened cycle", ^{
            EZRMutableNode<NSNumber *> *node = [EZRMutableNode new];
            EZRMutableNode<NSNumber *> *insideNode = [EZRMutableNode new];
            EZRNode *flattenedNode = [node flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
                insideNode.value = next;
                return insideNode;
            }];
            [insideNode linkTo:flattenedNode];
            //               node    ->
            //                  ^       \
            //                  |        ->   flattenedNode
            //                  |       /
            //            insideNode <-
            node.value = @5;
            expect(flattenedNode.value).to(equal(@5));
            expect(insideNode.value).to(equal(@5));
            insideNode.value = @7;
            expect(flattenedNode.value).to(equal(@7));
            
        });
    
    
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *numbEZRNode = EZRNode.new;
                EZRNode<NSNumber *> *mappedValue = [numbEZRNode flattenMap:^EZRNode * _Nullable(NSNumber * _Nullable next) {
                    EZRMutableNode *value = EZRMutableNode.new;
                    for (int i = 0; i < next.integerValue; ++i) {
                        value.value = @(i);
                    }
                    
                    return value;
                }];
                [checkTool checkObj:numbEZRNode];
                [checkTool checkObj:mappedValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- flatten operation, ", ^{
        it(@"can flatten EZRNode", ^{
            EZRMutableNode<EZRNode<NSNumber *> *> *highOrdEZRNode = [EZRMutableNode value:[EZRNode value:@1]];
            EZRNode<NSNumber *> *flattenValue = [highOrdEZRNode flatten];
            
            NSObject *listener = [NSObject new];
            [flattenValue startListenForTestWithObj:listener];
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@2];
            highOrdEZRNode.value = value1;
            value1.value = @3;
            EZRMutableNode<NSNumber *> *value2 = [EZRMutableNode value:@4];
            highOrdEZRNode.value = value2;
            value2.value = @5;
            expect(flattenValue).to(receive(@[@1, @2, @3, @4, @5]));
        });
    
        it(@"can change upstream", ^{
            EZRMutableNode<EZRMutableNode<NSNumber *> *> *highOrderNode1 = [EZRMutableNode value:[EZRMutableNode value:@1]];
            EZRMutableNode<EZRMutableNode<NSNumber *> *> *highOrderNode2 = [EZRMutableNode new];
            EZRNode<NSNumber *> *flattenedNode = [highOrderNode1 flatten];
            EZRFlattenTransform *transform = flattenedNode.upstreamTransforms.firstObject;
            expect(flattenedNode.value).to(equal(@1));
            transform.from = highOrderNode2;
            
            highOrderNode1.value.value = @2;
            expect(flattenedNode.value).notTo(equal(@2));
            highOrderNode2.value = [EZRMutableNode value:@3];
            expect(flattenedNode.value).to(equal(@3));
            highOrderNode2.value.value = @4;
            expect(flattenedNode.value).to(equal(@4));
        });
        
        it(@"should raise an exception when EZRNode is not a high order EZRNode", ^{
            EZRMutableNode<EZRNode<NSNumber *> *> *highOrdEZRNode = [EZRMutableNode value:@3];
            
            expectAction(^{
                [highOrdEZRNode flatten];
            }).to(raiseException().named(EZRNodeExceptionName).reason(EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode));
            
            highOrdEZRNode = [EZRMutableNode value:[EZRNode value:@3]];
            EZRNode<NSNumber *> *mappedValue __attribute__((unused)) = [highOrdEZRNode flatten];
            
            expectAction(^{
                highOrdEZRNode.value = (id)@3;
            }).to(raiseException().named(EZRNodeExceptionName).reason(EZRExceptionReason_FlattenOrFlattenMapNextValueNotEZRNode));
        });
        
        it(@"can be released correctly", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                EZRNode<EZRNode<NSNumber *> *> *highOrdEZRNode = [EZRNode value:[EZRNode value:@1]];
                EZRNode<NSNumber *> *flattenValue = [highOrdEZRNode flatten];
                [checkTool checkObj:highOrdEZRNode];
                [checkTool checkObj:flattenValue];
            }).to(beReleasedCorrectly());
        });
    });
    
    context(@"- scanWithStart: operation,", ^{
        it(@"can collect each value to an array using reduce: operation", ^{
            EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@0];
            EZRNode<NSArray<NSNumber *> *> *receiveNode = [node scanWithStart:[NSMutableArray array] reduce:^id _Nonnull(NSMutableArray<NSNumber *> *running, NSNumber * _Nonnull next) {
                [running addObject:next];
                return running;
            }];
            node.value = @1;
            node.value = @3;
            NSMutableArray *expectValues = @[@0, @1, @3].mutableCopy;
            expect(receiveNode.value).to(equal(expectValues));
        });
        
        it(@"can collect each value to an array use reduceWithIndex: operation", ^{
            EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
            EZRNode<NSArray<NSNumber *> *> *receiveNode = [node scanWithStart:@10 reduceWithIndex:^id _Nonnull(NSNumber *running, NSNumber * _Nonnull next, NSUInteger index) {
                return @(running.integerValue * next.integerValue + index);
            }];
            node.value = @1;
            node.value = @3;
            // init 10
            // reduce = init * next + index
            // 10 * 1 + 0 = 10
            // 10 * 1 + 1 = 11
            // 11 * 3 + 2 = 35
            expect(receiveNode.value).to(equal(@35));
        });
        
        it(@"can change upstream", ^{
            EZRMutableNode<NSNumber *> *node = [EZRMutableNode value:@1];
            EZRNode<NSArray<NSNumber *> *> *receiveNode = [node scanWithStart:@10 reduceWithIndex:^id _Nonnull(NSNumber *running, NSNumber * _Nonnull next, NSUInteger index) {
                return @(running.integerValue * next.integerValue + index);
            }];
            node.value = @1;
            node.value = @3;
            // init 10
            // reduce = init * next + index
            // 10 * 1 + 0 = 10
            // 10 * 1 + 1 = 11
            // 11 * 3 + 2 = 35
            expect(receiveNode.value).to(equal(@35));
            EZRMutableNode<NSNumber *> *anotherNode = [EZRMutableNode value:@20];
            EZRTransform *transform = receiveNode.upstreamTransforms.firstObject;
            transform.from = anotherNode;
            anotherNode.value = @21;
            anotherNode.value = @23;
            // init 10
            // reduce = init * next + index
            // 10 * 20 + 0 = 200
            // 200 * 21 + 1 = 4201
            // 4201 * 23 + 2 = 96625
            expect(receiveNode.value).to(equal(@96625));
        });
        
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                EZRMutableNode<NSNumber *> *node1 = [EZRMutableNode value:@0];
                EZRNode<NSArray<NSNumber *> *> *node2 = [node1 scanWithStart:[NSMutableArray array] reduce:^id _Nonnull(NSMutableArray<NSNumber *> *running, NSNumber * _Nonnull next) {
                    [running addObject:next];
                    return running;
                }];
                node1.value = @1;
                node1.value = @3;
                [checkTool checkObj:node1];
                [checkTool checkObj:node2];
                
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });
    
    context(@"- combine: operation,", ^{
        it(@"can combine each value to an array", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@1];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"1"];
            
            EZRNode<EZTuple2<NSNumber *, NSString *> *> *value3 = [EZRNode combine:@[value1, value2]];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            expect(value3.value).to(equal(EZTuple(@1, @"1")));
            
            value1.value = @2;
            value2.value = @"2";
            value1.value = @3;
            
            expect(value3).to(receive(@[EZTuple(@1, @"1"), EZTuple(@2, @"1"), EZTuple(@2, @"2"), EZTuple(@3, @"2")]));
        });
    
        it(@"can combine using instance method", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@1];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"1"];
            
            EZRNode<EZTuple2<NSNumber *, NSString *> *> *value3 = [value1 combine:value2];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            expect(value3.value).to(equal(EZTuple(@1, @"1")));
            
            value1.value = @2;
            value2.value = @"2";
            value1.value = @3;
            
            expect(value3).to(receive(@[EZTuple(@1, @"1"), EZTuple(@2, @"1"), EZTuple(@2, @"2"), EZTuple(@3, @"2")]));
        });
    
        it(@"can support nil value", ^{
            EZRMutableNode *value1 = [EZRMutableNode value:@1];
            EZRMutableNode *value2 = [EZRMutableNode value:@"1"];
            
            EZRNode<EZTuple2<NSNumber *, NSString *> *> *value3 = [EZRNode combine:@[value1, value2]];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            value1.value = nil;
            value2.value = @"2";
            value1.value = @3;
            
            expect(value3).to(receive(@[EZTuple(@1, @"1"),EZTuple(nil, @"1"),EZTuple(nil, @"2"),EZTuple(@3, @"2")]));
        });
    
        it(@"can add an upstream after combining", ^{
            EZRMutableNode *valueA = [EZRMutableNode value:@1];
            EZRMutableNode *valueB = [EZRMutableNode value:@"1"];
            EZRMutableNode *valueC = [EZRMutableNode value:@NO];
            
            EZRNode<EZTuple2<NSNumber *, NSString *> *> *value = [EZRNode combine:@[valueA, valueB]];
            expect(value.value).to(equal(EZTuple(@1, @"1")));
            
            NSObject *listener = [NSObject new];
            [value startListenForTestWithObj:listener];
            
            [value linkTo:valueC];
            expect(value.value).to(equal(@NO));
            
            valueA.value = @2;
            valueC.value = @YES;
            valueB.value = @"2";
            
            expect(value).to(receive(@[EZTuple(@1, @"1"), @NO,EZTuple(@2, @"1"), @YES,EZTuple(@2, @"2"),]));
        });
    
        it(@"should not receive new value when remove an combining upstream node", ^{
            EZRNode<NSNumber *> *valueA = [EZRNode value:@1];
            EZRMutableNode<NSString *> *valueB = [EZRMutableNode value:@"1"];
            EZRMutableNode<NSNumber *> *valueC = [EZRMutableNode value:@NO];
            
            EZRNode<EZTuple3<NSNumber *, NSString *, NSNumber *> *> *value = [EZRNode combine:@[valueA, valueB, valueC]];
            
            NSObject *listener = [NSObject new];
            [value startListenForTestWithObj:listener];
            [valueB removeDownstreamNode:value];
            
            valueB.value = @"2";
            expect(value.value).notTo(equal(EZTuple(@1, @"2", @NO)));
            
            valueC.value = @YES;
            expect(value).to(receive(@[EZTuple(@1, @"1", @NO)]));
        });
    
        it(@"can auto remove a deallocated upstream after combining", ^{
            EZRNode *valueA = [EZRNode value:@1];
            __weak EZRNode *valueB = nil;
            EZRNode *valueC = [EZRNode value:@NO];
            EZRNode *value = nil;
            
            @autoreleasepool {
                EZRNode *newValue = EZRNode.new;
                valueB = newValue;
                value = [EZRNode combine:@[valueA, valueB, valueC]];
                
                NSObject *listener = [NSObject new];
                [value startListenForTestWithObj:listener];
                expect(value).to(beEmptyValue());
            }
            expect(value.value).notTo(equal(@[@1, @NO]));
        });
    
        it(@"can use EZRCombine macro define block easily", ^{
            EZRNode *value1 = [EZRNode value:@1];
            EZRNode *value2 = [EZRNode value:@1];
            
            EZRNode *value3 = [EZRCombine(value1, value2) mapEach:^id(id arg1, id arg2) {
                return nil;
            }];
            
            expect(value3.value).to(beNil());
        });
    
        it(@"can combine value's changes each time", ^{
            EZRMutableNode *value1 = [EZRMutableNode value:@1];
            EZRMutableNode *value2 = [EZRMutableNode value:@1];
            
            EZRNode *value3 = [EZRCombine(value1, value2) mapEach:^id(id arg1, id arg2) {
                return @([arg1 integerValue] + [arg2 integerValue]);
            }];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            value1.value = @2;
            value1.value = @5;
            value2.value = @7;
            value2.value = @1;
            
            expect(value3.value).to(equal(@6));
            expect(value3).to(receive(@[@2, @3, @6, @12, @6]));
        });
    
        it(@"should raise exception when set value to mapEach's upstream", ^{
            EZRMutableNode *valueA = [EZRMutableNode value:@1];
            EZRMutableNode *valueB = [EZRMutableNode value:@1];
            
            EZRNode *value = [EZRCombine(valueA, valueB) mapEach:^id(id arg1, id arg2) {
                return @([arg1 integerValue] + [arg2 integerValue]);
            }];
            
            NSObject *listener = [NSObject new];
            [value startListenForTestWithObj:listener];;
            
            valueA.value = @2;
            valueA.value = @5;
            valueB.value = @7;
            expectAction(^(){
                value.upstreamNodes.firstObject.mutablify.value = @"";
            }).to(raiseException().named(EZRNodeExceptionName).reason(EZRExceptionReason_MapEachNextValueNotTuple));
        });
    
        it(@"won't get a combined value until each upstream is not empty", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode new];
            EZRMutableNode<NSNumber *> *value2 = [EZRMutableNode new];
            
            EZRNode<EZTuple2<NSNumber *, NSNumber *> *> *value3 = [EZRNode combine:@[value1, value2]];
            expect(value3).to(beEmptyValue());
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            value1.value = @1;
            expect(value3).to(beEmptyValue());
            
            value2.value = @2;
            expect(value3).notTo(beEmptyValue());
            
            expect(value3).to(receive(@[EZTuple(@1, @2)]));
        });
    
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                EZRNode *value1 = [EZRNode value:@1];
                EZRNode *value2 = [EZRNode value:@1];
                EZRNode *value3 = [EZRNode combine:@[value1, value2]];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
                [checkTool checkObj:value3];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });
    
    context(@"- merge: operation,", ^{
        it(@"can merge values", ^{
            EZRMutableNode *value1 = [EZRMutableNode value:@1];
            EZRMutableNode *value2 = [EZRMutableNode value:@2];
            
            EZRNode *value3 = [EZRNode merge:@[value1, value2]];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            expect(value3.value).to(equal(@2));
            
            value1.value = @3;
            value2.value = @9;
            value1.value = @3;
            
            expect(value3).to(receive(@[@2, @3, @9, @3]));
        });
    
        it(@"can merge using instance method", ^{
            EZRMutableNode *value1 = [EZRMutableNode value:@1];
            EZRMutableNode *value2 = [EZRMutableNode value:@2];
            
            EZRNode *value3 = [value1 merge:value2];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            expect(value3.value).to(equal(@2));
            
            value1.value = @3;
            value2.value = @9;
            value1.value = @3;
            
            expect(value3).to(receive(@[@2, @3, @9, @3]));
        });
    
        it(@"can add an upstream after merging", ^{
            EZRMutableNode *valueA = [EZRMutableNode value:@1];
            EZRMutableNode *valueB = [EZRMutableNode value:@"1"];
            EZRMutableNode *valueC = [EZRMutableNode value:@NO];
            
            EZRNode *value = [EZRNode merge:@[valueA, valueB]];
            expect(value.value).to(equal(@"1"));
            
            NSObject *listener = [NSObject new];
            [value startListenForTestWithObj:listener];
            
            [value linkTo:valueC];
            expect(value.value).to(equal(@NO));
            
            valueA.value = @2;
            valueB.value = @"2";
            valueC.value = @YES;
            
            expect(value).to(receive(@[@"1", @NO, @2, @"2", @YES]));
        });
    
        it(@"can remove an upstream after merging", ^{
            EZRNode *valueA = [EZRNode value:@1];
            EZRMutableNode *valueB = EZRMutableNode.new;
            EZRMutableNode *valueC = [EZRMutableNode value:@NO];
            
            EZRNode *value = [EZRNode merge:@[valueA, valueB, valueC]];
            
            NSObject *listener = [NSObject new];
            [value startListenForTestWithObj:listener];
            expect(value.value).to(equal(@NO));
            [valueB removeDownstreamNode:value];
            
            valueB.value = @"a";
            
            expect(value.value).notTo(equal(@"a"));
            
            valueC.value = @YES;
            expect(value).to(receive(@[@NO, @YES]));
        });
    
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                EZRNode *value1 = [EZRNode value:@1];
                EZRNode *value2 = [EZRNode value:@1];
                EZRNode *value3 = [EZRNode merge:@[value1, value2]];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
                [checkTool checkObj:value3];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });
    
    context(@"- zip: operation,", ^{
        it(@"can zip several EZRNodes", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@0];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"a"];
            EZRMutableNode<NSString *> *value3 = [EZRMutableNode value:@"A"];
            
            EZRNode<EZTuple3<NSNumber *, NSString *, NSString *> *> *zippedValue1 = [EZRNode zip:@[value1, value2, value3]];
            NSObject *listener = [NSObject new];
            [zippedValue1 startListenForTestWithObj:listener];
            expect(zippedValue1.value).to(equal(EZTuple(@0, @"a", @"A")));
            value1.value = @1;
            value1.value = @2;
            value1.value = @3;
            value2.value = @"b";
            value1.value = @4;
            value2.value = @"c";
            expect(zippedValue1.value).to(equal(EZTuple(@0, @"a", @"A")));
            value3.value = @"B";
            expect(zippedValue1.value).to(equal(EZTuple(@1, @"b", @"B")));
            value3.value = @"C";
            expect(zippedValue1.value).to(equal(EZTuple(@2, @"c", @"C")));
            expect(zippedValue1).to(receive(@[EZTuple(@0, @"a", @"A"),EZTuple(@1, @"b", @"B"),EZTuple(@2, @"c", @"C")]));
        });
    
        it(@"can zip using instance method", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@0];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"a"];
            
            EZRNode<EZTuple2<NSNumber *, NSString *> *>*zippedValue1 = [value1 zip:value2];
            NSObject *listener = [NSObject new];
            [zippedValue1 startListenForTestWithObj:listener];
            
            expect(zippedValue1.value).to(equal(EZTuple(@0, @"a")));
            value1.value = @1;
            value1.value = @2;
            value1.value = @3;
            value2.value = @"b";
            expect(zippedValue1.value).to(equal(EZTuple(@1, @"b")));
            value1.value = @4;
            value2.value = @"c";
            
            expect(zippedValue1.value).to(equal(EZTuple(@2, @"c")));
            
            expect(zippedValue1).to(receive(@[EZTuple(@0, @"a"),EZTuple(@1, @"b"),EZTuple(@2, @"c")]));
        });
    
        it(@"keeps empty until every upstream has a non-empty value using zip", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode new];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode new];
            EZRNode<NSString *> *value3 = [EZRNode value:@"A"];
            EZRNode *zippedValue = [EZRNode zip:@[value1, value2, value3]];
            NSObject *listener = [NSObject new];
            [zippedValue startListenForTestWithObj:listener];
            expect(zippedValue).to(beEmptyValue());
            value1.value = @100;
            value2.value = @"bbb";
            expect(zippedValue.value).to(equal(EZTuple(@100, @"bbb", @"A")));
            expect(zippedValue).to(receive(@[EZTuple(@100, @"bbb", @"A")]));
        });
    
        it(@"support nil value", ^{
            EZRNode<NSNumber *> *value1 = [EZRNode value:nil];
            EZRNode<NSString *> *value2 = [EZRNode value:@"a"];
            EZRNode<NSString *> *value3 = [EZRNode value:@"A"];
            
            EZRNode<EZTuple3<NSNumber *, NSString *, NSString *> *> *zippedValue = [EZRNode zip:@[value1, value2, value3]];
            
            NSObject *listener = [NSObject new];
            [zippedValue startListenForTestWithObj:listener];
            expect(zippedValue).to(receive(@[EZTuple(nil, @"a", @"A")]));
        });
    
        it(@"can add upstreamNodes after zipping", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:nil];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"a"];
            EZRMutableNode<NSString *> *value3 = [EZRMutableNode new];
            
            EZRNode<EZTuple2<NSNumber *, NSString *> *> *zippedValue = [EZRNode zip:@[value1, value2]];
            
            NSObject *listener = [NSObject new];
            [zippedValue startListenForTestWithObj:listener];
            expect(zippedValue.value).to(equal(EZTuple(nil, @"a")));
            
            [zippedValue linkTo:value3];
            value3.value = @"AAA";
            expect(zippedValue.value).to(equal(@"AAA"));
            value1.value = @123;
            value1.value = @333;
            value1.value = @444;
            value2.value = @"aaa";
            expect(zippedValue.value).to(equal(EZTuple(@123, @"aaa")));
            
            expect(zippedValue).to(receive(@[EZTuple(nil, @"a"), @"AAA",EZTuple(@123, @"aaa")]));
        });
    
        it(@"should not receive new value after removing zipping upstreamNodes", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@10];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"a"];
            EZRMutableNode<NSString *> *value3 = [EZRMutableNode value:@"A"];
            
            EZRNode<EZTuple3<NSNumber *, NSString *, NSString *> *> *zippedValue = [EZRNode zip:@[value1, value2, value3]];
            
            NSObject *listener = [NSObject new];
            [zippedValue startListenForTestWithObj:listener];
            
            expect(zippedValue.value).to(equal(EZTuple(@10, @"a", @"A")));
            [zippedValue removeUpstreamNode:value1];
            value2.value = @"b";
            value2.value = @"c";
            value2.value = @"d";
            value3.value = @"B";
            value3.value = @"C";
            value1.value = @100;
            expect(zippedValue).to(receive(@[EZTuple(@10, @"a", @"A")]));
        });
        
        it(@"can use EZRZip macro to zip values", ^{
            EZRMutableNode<NSNumber *> *value1 = [EZRMutableNode value:@100];
            EZRMutableNode<NSString *> *value2 = [EZRMutableNode value:@"A"];
            
            EZRNode *value3 = [EZRZip(value1, value2) mapEach:^id _Nonnull(id _Nonnull arg0, id _Nonnull arg1) {
                return [NSString stringWithFormat:@"%@: %@", arg0, arg1];
            }];
            
            NSObject *listener = [NSObject new];
            [value3 startListenForTestWithObj:listener];
            
            value1.value = @200;
            value1.value = @500;
            value2.value = @"BBB";
            value2.value = @"CCCCC";
            
            expect(value3.value).to(equal(@"500: CCCCC"));
            expect(value3).to(receive(@[@"100: A", @"200: BBB", @"500: CCCCC"]));
        });
    
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                EZRNode *value1 = [EZRNode value:@1];
                EZRNode *value2 = [EZRNode value:@1];
                EZRNode *value3 = [EZRNode zip:@[value1, value2]];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
                [checkTool checkObj:value3];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });
    
    context(@"- throttle operation,", ^{
        it(@"only receives value which throttle long enough", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_SERIAL);
            EZRMutableNode<NSString *> *value = [EZRMutableNode new];
            EZRNode<NSString *> *throttledValue = [value throttleOnMainQueue:0.1];
            NSObject *listener = [NSObject new];
            [throttledValue startListenForTestWithObj:listener];
            
            waitUntilTimeout(2, ^(void (^done)(void)) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.12 * NSEC_PER_SEC), q, ^{
                    value.value = @"r";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15 * NSEC_PER_SEC), q, ^{
                    value.value = @"re";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.80 * NSEC_PER_SEC), q, ^{
                    value.value = @"res";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.84 * NSEC_PER_SEC), q, ^{
                    value.value = @"resu";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.20 * NSEC_PER_SEC), q, ^{
                    value.value = @"resul";
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.22 * NSEC_PER_SEC), q, ^{
                    value.value = @"result";
                });
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), q, ^{
                    done();
                });
            });
            
            expect(throttledValue).to(receive(@[@"re", @"resu", @"result"]));
        });
    
        it(@"throttle should ignores empty values", ^{
            EZRMutableNode<NSString *> *value = [EZRMutableNode new];
            EZRNode<NSString *> *throttledValue = [value throttleOnMainQueue:0.1];
            NSObject *listener = [NSObject new];
            [throttledValue startListenForTestWithObj:listener];
            
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
    
        it(@"should invoke the listeners in the main queue when it was created in the main queue", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            __block EZRNode *throttledValue = nil;
            NSObject *listener = [NSObject new];
            
            waitUntil(^(void (^done)(void)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    EZRMutableNode *value = [EZRMutableNode value:@100];
                    throttledValue = [value throttleOnMainQueue:0.1];
                    [throttledValue startListenForTestWithObj:listener];
                    [[throttledValue listenedBy:listener] withBlock:^(id  _Nullable next) {
                        expect([NSThread isMainThread]).to(beTruthy());
                    }];
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
        
        it(@"should invoke the listeners in a background queue when it created in a background queue", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            __block EZRNode *throttledValue = nil;
            NSObject *listener = [NSObject new];
            waitUntil(^(void (^done)(void)) {
                dispatch_async(q, ^{
                    EZRMutableNode *value = [EZRMutableNode value:@100];
                    throttledValue = [value throttle:0.1 queue:q];
                    [throttledValue startListenForTestWithObj:listener];
                    [[throttledValue listenedBy:listener] withBlock:^(id  _Nullable next) {
                        expect([NSThread isMainThread]).to(beFalsy());
                    }];
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
        
        it(@"can invoke listen on the specified queue", ^{
            dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
            __block EZRNode *throttledValue = nil;
            NSObject *listener = [NSObject new];
            waitUntil(^(void (^done)(void)) {
                dispatch_async(q, ^{
                    EZRMutableNode *value = [EZRMutableNode value:@100];
                    throttledValue = [value throttle:0.1 queue:dispatch_get_main_queue()];
                    [throttledValue startListenForTestWithObj:listener];
                    [[throttledValue listenedBy:listener] withBlock:^(id  _Nullable next) {
                        expect([NSThread isMainThread]).to(beTruthy());
                    }];
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
            
            __block EZRNode *throttledValue2 = nil;
            listener = [NSObject new];
            waitUntil(^(void (^done)(void)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    EZRMutableNode *value = [EZRMutableNode value:@1000];
                    throttledValue2 = [value throttle:0.1 queue:q];
                    [throttledValue2 startListenForTestWithObj:listener];
                    [[throttledValue2 listenedBy:listener] withBlock:^(id  _Nullable next) {
                        expect([NSThread isMainThread]).to(beFalsy());
                    }];
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
        
        it(@"should raise an asset when throttling with a number less than zero", ^(){
            EZRNode *value = [EZRNode value:@1000];
            
            assertExpect(^{
                [value throttleOnMainQueue:-1];
            }).to(hasParameterAssert());
        });
        
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                waitUntil(^(void (^done)(void)) {
                    NSObject *listener = [NSObject new];
                    EZRNode<NSNumber *> *value = [EZRNode value:@10];
                    
                    EZRNode<NSNumber *> *throttledValue = [value throttleOnMainQueue:0.5];
                    EZRNode<NSNumber *> *throttledValue2 = [value throttle:0.2 queue:dispatch_get_main_queue()];
                    [[throttledValue listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                        
                    }];
                    [[throttledValue2 listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                        
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
    
    it(@"can use switch case split value sequence", ^{
        EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"Lilei: hello!"];
        EZRNode<EZRSwitchedNodeTuple<NSString *> *> *nodes = [node switch:^id<NSCopying> _Nonnull(NSString * _Nullable next) {
            return [[next componentsSeparatedByString:@":"] firstObject];
        }];
        EZRNode<NSString *> *lileiSaid = [nodes case:@"Lilei"];
        EZRNode<NSString *> *hanmeimeiSaid = [nodes case:@"HanMeiMei"];
        [lileiSaid startListenForTestWithObj:self];
        [hanmeimeiSaid startListenForTestWithObj:self];
        node.value = @"Lilei: Hello? Anybody here?";
        EZRNode<NSString *> *anotherlilei = [nodes case:@"Lilei"];
        [anotherlilei startListenForTestWithObj:self];
        node.value = @"Lilei: Hello? Anybody here Again?";
        node.value = @"HanMeiMei: I'm Han Meimei";
        expect(lileiSaid).to(receive(@[@"Lilei: hello!",
                                       @"Lilei: Hello? Anybody here?",
                                       @"Lilei: Hello? Anybody here Again?"]));
        expect(anotherlilei).to(receive(@[@"Lilei: Hello? Anybody here?",
                                          @"Lilei: Hello? Anybody here Again?"]));
        expect(hanmeimeiSaid).to(receive(@[@"HanMeiMei: I'm Han Meimei"]));
    });
    
    it(@"switch case operation supports nil key", ^{
        EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"Lilei: hello!"];
        EZRNode<EZRSwitchedNodeTuple<id> *> *nodes = [node switchMap:^EZTuple2<id<NSCopying>,id> * _Nonnull(NSString * _Nullable next) {
            NSArray<NSString *> *sentence = [next componentsSeparatedByString:@":"];
            NSString *key = [sentence firstObject];
            key = [key isEqualToString:@"Lilei"] ? nil : key;
            return EZTuple(key, [sentence lastObject]);
        }];
        EZRNode<NSString *> *lileiSaid = [nodes default];
        EZRNode<NSString *> *hanmeimeiSaid = [nodes case:@"HanMeiMei"];
        [lileiSaid startListenForTestWithObj:self];
        [hanmeimeiSaid startListenForTestWithObj:self];
        node.value = @"Lilei: Hello? Anybody here?";
        EZRNode<NSString *> *anotherlilei = [nodes case:nil];
        [anotherlilei startListenForTestWithObj:self];
        node.value = @"Lilei: Hello? Anybody here Again?";
        node.value = @"HanMeiMei: I'm Han Meimei";
        expect(lileiSaid).to(receive(@[@" hello!",
                                       @" Hello? Anybody here?",
                                       @" Hello? Anybody here Again?"]));
        expect(anotherlilei).to(receive(@[@" Hello? Anybody here?",
                                          @" Hello? Anybody here Again?"]));
        expect(hanmeimeiSaid).to(receive(@[@" I'm Han Meimei"]));
    });
    
    it(@"can split 2 value sequences from origin sequence use if operation", ^{
        EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"Lilei: hello!"];
        
        __block EZRNode *liLeisaid;
        __block EZRNode *othersaid;
        
        EZRIFResult *resultNode = [[[node if:^BOOL(NSString * _Nullable next) {
            return [[[next componentsSeparatedByString:@":"] firstObject] isEqualToString:@"Lilei"];
        }] then:^(EZRNode * _Nonnull node) {
            liLeisaid = node;
            
        }] else:^(EZRNode * _Nonnull node) {
            othersaid = node;
            
        }];
        expect(liLeisaid).to(beIdenticalTo(resultNode.thenNode));
        expect(othersaid).to(beIdenticalTo(resultNode.elseNode));
    });
    
    it(@"can split 2 value sequences from origin sequence use if operation", ^{
        EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"Lilei: hello!"];
        
        __block EZRNode *liLeisaid;
        __block EZRNode *othersaid;
        
        [[[node if:^BOOL(NSString * _Nullable next) {
            return [[[next componentsSeparatedByString:@":"] firstObject] isEqualToString:@"Lilei"];
        }] then:^(EZRNode * _Nonnull node) {
            liLeisaid = node;
            [node startListenForTestWithObj:self];
        }] else:^(EZRNode * _Nonnull node) {
            othersaid = node;
            [node startListenForTestWithObj:self];
        }];
        
        node.value = @"Lilei: Hello? Anybody here?";
        node.value = @"HanMeiMei: This is HanMeimei";
        node.value = @"Tony: This is Tony";
        expect(liLeisaid).to(receive(@[@"Lilei: hello!",
                                       @"Lilei: Hello? Anybody here?"
                                       ]));
        expect(othersaid).to(receive(@[@"HanMeiMei: This is HanMeimei",
                                       @"Tony: This is Tony"
                                       ]));
    });
    
    
    it(@"can be released correctly when using switch case operation", ^{
        expectCheckTool(^(CheckReleaseTool *checkTool) {
            EZRMutableNode<NSString *> *node = [EZRMutableNode value:@"Lilei: hello!"];
            EZRNode<EZRSwitchedNodeTuple<NSString *> *> *nodes = [node switch:^id<NSCopying> _Nonnull(NSString * _Nullable next) {
                return [[next componentsSeparatedByString:@":"] firstObject];
            }];
            EZRNode<NSString *> *lileiSaid = [nodes case:@"Lilei"];
            EZRNode<NSString *> *hanmeimeiSaid = [nodes case:@"HanMeiMei"];
            
            
            node.value = @"Lilei: Hello? Anybody here?";
            EZRNode<NSString *> *anotherlilei = [nodes case:@"Lilei"];
            
            node.value = @"Lilei: Hello? Anybody here Again?";
            node.value = @"HanMeiMei: I'm Han Meimei";
            [checkTool checkObj:node];
            [checkTool checkObj:nodes];
            [checkTool checkObj:lileiSaid];
            [checkTool checkObj:hanmeimeiSaid];
            [checkTool checkObj:anotherlilei];
        }).to(beReleasedCorrectly());
    });

    it(@"should raise an exception if a node was generated incorrectly", ^{
        EZRMutableNode *node = [EZRMutableNode new];
        EZRNode *casedNode __attribute__((unused))= [node case:@"xx"];
        
        expectAction(^(){
            node.value = @"11111";
        }).to(raiseException().named(EZRNodeExceptionName).reason(EZRExceptionReason_CasedNodeMustGenerateBySwitchOrSwitchMapOperation));
        
    });
    
    it(@"can delay sending values", ^{
        dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
        EZRMutableNode<NSString *> *node = [EZRMutableNode new];
        EZRNode<NSString *> *delayNode = [node delay:0.1 queue:q];
        
        NSObject *listener = [NSObject new];
        [delayNode startListenForTestWithObj:listener];
        
        node.value = @"A";
        expect(delayNode).to(beEmptyValue());
        
        expect(delayNode).withTimeout(0.2).toEventually(receive(@[@"A"]));
        
    });
    
    it(@"should delay sending values in the main queue if it was created in the main queue", ^{
        __block EZRNode *delayNode = nil;
        NSObject *listener = [NSObject new];
        
        waitUntilTimeout(0.5, ^(void (^done)(void)) {
            EZRMutableNode *node = [EZRMutableNode value:@100];
            delayNode = [node delayOnMainQueue:0.1];
            [delayNode startListenForTestWithObj:listener];
            [[delayNode listenedBy:listener] withBlock:^(id  _Nullable next) {
                expect([NSThread isMainThread]).to(beTrue());
            }];
            
            node.value = @200;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                node.value = @300;
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                expect(delayNode).to(receive(@[@100, @200, @300]));
                done();
            });
        });
    });
    
    it(@"should delay sending values in the main queue if it was created in the special queue", ^{
        dispatch_queue_t q = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
        __block EZRNode *delayNode = nil;
        NSObject *listener = [NSObject new];
        waitUntil(^(void (^done)(void)) {
            EZRMutableNode *node = [EZRMutableNode value:@100];
            delayNode = [node delay:0.1 queue:q];
            [delayNode startListenForTestWithObj:listener];
            [[delayNode listenedBy:listener] withBlock:^(id  _Nullable next) {
                expect([NSThread isMainThread]).to(beFalse());
            }];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                node.value = @200;
                
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                node.value = @300;
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                done();
            });
        });
        
        expect(delayNode).to(receive(@[@100, @200, @300]));
        
    });
    
    
    it(@"delaying with a number less than zero should raise an asset", ^(){
        EZRNode *node = [EZRNode value:@1000];
        
        assertExpect(^{
            [node delayOnMainQueue:-1];
        }).to(hasParameterAssert());
    });

    it(@"can be released correctly when using delay operation", ^{
        void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
            waitUntil(^(void (^done)(void)) {
                NSObject *listener = [NSObject new];
                EZRNode<NSNumber *> *value = [EZRNode value:@10];
                
                EZRNode<NSNumber *> *throttledValue = [value throttleOnMainQueue:0.5];
                EZRNode<NSNumber *> *throttledValue2 = [value throttle:0.2 queue:dispatch_get_main_queue()];
                [[throttledValue listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                    
                }];
                [[throttledValue2 listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                    
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

QuickSpecEnd
