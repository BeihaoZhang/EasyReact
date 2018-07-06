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

// https://github.com/Specta/Specta

SpecBegin(ERNode)

describe(@"ERNode common test", ^{
    context(@"common test", ^{
        it(@"can store a value", ^{
            ERNode *testValue = [ERNode value:@1];
            
            expect(testValue.value).to.equal(@1);
        });
        
        it(@"can get a empty value if only use init without first value", ^{
            ERNode *testValue = [ERNode new];
            
            expect(testValue).to.beEmptyValue();
        });
        
        it(@"can get last value when set some times", ^{
            ERNode *testValue = [ERNode value:@1];
            
            testValue.value = @2;
            testValue.value = @3;
            
            expect(testValue.value).to.equal(@3);
        });
        
        it(@"can listen each values after listening", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            
            NSMutableArray<NSNumber *> *array = [@[] mutableCopy];
            [testValue listen:^(NSNumber *next) {
                [array addObject:next];
            }];
            
            testValue.value = @2;
            testValue.value = @3;
            
            expect(array).to.equal(@[@1, @2, @3]);
        });
        
        it(@"can add your custom listener", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            TestListener *listener = [TestListener new];
            
            [testValue addListener:listener];
            
            testValue.value = @2;
            testValue.value = @3;
            
            expect(listener.receiveValues).to.haveCount(3);
            expect(listener.receiveValues).to.equal(@[@1, @2, @3]);
        });
        
        it(@"can't callback the empty value", ^{
            ERNode<NSNumber *> *testValue = [ERNode new];
            
            [testValue startListenForTest];
            
            testValue.value = @2;
            testValue.value = @3;
            
            expect(testValue).to.receive(@[@2, @3]);
        });
        
        it(@"can stop listen after listening", ^{
            ERNode<NSNumber *> *testValue = [ERNode value:@1];
            
            id<ERCancelable> cancelable = [testValue startListenForTest];
            
            testValue.value = @2;
            [cancelable cancel];
            testValue.value = @3;
            
            expect(testValue).to.receive(@[@1, @2]);
        });
        
        it(@"can be released correctly after listening", ^{
            TestListener *listener = TestListener.new;
            
            expect(^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testValue = [ERNode value:@1];
                [testValue addListener:listener];
                
                [checkTool checkObj:testValue];
            }).to.beReleasedCorrectly();
            
            expect(listener.receiveValues).to.equal(@[@1]);
        });
    });
    
    context(@"upstream and downstream", ^{
        it(@"can add another ERNode as a downstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value1 addDownstreamNode:value2];
            
            expect(value2.value).to.equal(@1);
            expect(value2.hasUpstreamNode).to.beTruthy();
            expect(value1.hasDownstreamNode).to.beTruthy();
            
            value1.value = @2;
            expect(value2.value).to.equal(@2);
        });
        
        it(@"will raise an exception when set value to a downstream ERNode which is single upstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value1 addDownstreamNode:value2];
            
            expect(value1.isSingleUpstream).to.beTruthy();
            
            expect(^{
                value2.value = @2;
            }).to.raiseWithReason(ERNodeExceptionName, ERExceptionReason_SetNodeWhenItIsDownstream);
        });
        
        it(@"will raise an exception when set value to a downstream which is already have upstream and it is signle upstream ", ^{
            ERNode<NSNumber *> *value1 = ERNode.new;
            ERNode<NSNumber *> *value2 = ERNode.new;
            ERNode<NSNumber *> *value = ERNode.new;
            
            expect(value.isSingleUpstream).to.beTruthy();
            
            [value1 addDownstreamNode:value];
            
            expect(^{
                [value2 addDownstreamNode:value];
            }).to.raiseWithReason(ERNodeExceptionName, ERExceptionReason_SetDownstreamAlreadyHaveUpstream);
        });
        
        it(@"can be added as downstream more than one time if it is not a single upstream ERNode", ^{
            ERNode<NSNumber *> *value1 = ERNode.new;
            ERNode<NSNumber *> *value2 = ERNode.new;
            ERNode *value = [ERNode multiUpstreamNode];
            
            expect(value.isSingleUpstream).to.beFalsy();
            
            [value1 addDownstreamNode:value];
            [value2 addDownstreamNode:value];
            expect(value1.hasDownstreamNode).to.beTruthy();
            expect(value2.hasDownstreamNode).to.beTruthy();
            expect(value.hasUpstreamNode).to.beTruthy();
            expect(value.upstreamNodes).to.haveCount(2);
            expect(value.upstreamNodes).to.contain(value1);
            expect(value.upstreamNodes).to.contain(value2);

            value1.value = @2;
            expect(value.value).to.equal(@2);
            value2.value = @3;
            expect(value.value).to.equal(@3);
        });
        
        it(@"can remove a downstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value1 addDownstreamNode:value2];
            
            [value1 removeDownstreamNode:value2];
            expect(value2.hasUpstreamNode).to.beFalsy();
            expect(value1.hasDownstreamNode).to.beFalsy();
            
            value1.value = @2;
            expect(value2.value).notTo.equal(@2);
        });
        
        it(@"won't have side effect when you remove a downstream which is not really downstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value1 removeDownstreamNode:value2];
            expect(value2.hasUpstreamNode).to.beFalsy();
            expect(value1.hasDownstreamNode).to.beFalsy();
            
            value1.value = @2;
            expect(value2.value).notTo.equal(@2);
        });
        
        it(@"can remove all downstreamNodes", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            ERNode<NSNumber *> *value3 = ERNode.new;
            
            [value1 addDownstreamNode:value2];
            [value1 addDownstreamNode:value3];
            
            expect(value1.downstreamNodes).to.haveCount(2);
            expect(value1.downstreamNodes).to.contain(value2);
            expect(value1.downstreamNodes).to.contain(value3);
            
            [value1 removeDownstreamNodes];
            expect(value1.hasDownstreamNode).to.beFalsy();
            expect(value2.hasUpstreamNode).to.beFalsy();
            expect(value3.hasUpstreamNode).to.beFalsy();
            
            value1.value = @2;
            expect(value2.value).notTo.equal(@2);
            expect(value3.value).notTo.equal(@2);
        });
        
        it(@"can add another ERNode as a upstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value2 setUpstreamNode:value1];
            
            expect(value2.value).to.equal(@1);
            expect(value2.hasUpstreamNode).to.beTruthy();
            expect(value1.hasDownstreamNode).to.beTruthy();
            
            value1.value = @2;
            expect(value2.value).to.equal(@2);
        });
        
        it(@"can set a new upstream exchange old upstream", ^{
            ERNode<NSNumber *> *valueA = [ERNode value:@1];
            ERNode<NSNumber *> *valueB = [ERNode value:@2];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value2 setUpstreamNode:valueA];
            expect(value2.value).to.equal(@1);
            expect(value2.hasUpstreamNode).to.beTruthy();
            expect(valueA.hasDownstreamNode).to.beTruthy();
            
            [value2 setUpstreamNode:valueB];
            expect(value2.value).to.equal(@2);
            expect(value2.hasUpstreamNode).to.beTruthy();
            expect(valueA.hasDownstreamNode).to.beFalsy();
            expect(valueB.hasDownstreamNode).to.beTruthy();
        });
        
        it(@"will raise an exception if set a upstream but it is multi upstream ERNode", ^{
            ERNode<NSNumber *> *valueA = [ERNode value:@1];
            ERNode *value = [ERNode multiUpstreamNode];
            
            expect(^{
                [value setUpstreamNode:valueA];
            }).to.raiseWithReason(ERNodeExceptionName, ERExceptionReason_SetUpstreamButItsMultiUpstream);
        });
        
        it(@"can add a new upstream if it is a multi upstream ERNode", ^{
            ERNode<NSNumber *> *value1 = ERNode.new;
            ERNode<NSNumber *> *value2 = ERNode.new;
            ERNode *value = [ERNode multiUpstreamNode];
            
            expect(value.isSingleUpstream).to.beFalsy();
            
            [value addUpstreamNode:value1];
            [value addUpstreamNode:value2];
            expect(value1.hasDownstreamNode).to.beTruthy();
            expect(value2.hasDownstreamNode).to.beTruthy();
            expect(value.hasUpstreamNode).to.beTruthy();
            expect(value.upstreamNodes).to.haveCount(2);
            expect(value.upstreamNodes).to.contain(value1);
            expect(value.upstreamNodes).to.contain(value2);
            
            value1.value = @2;
            expect(value.value).to.equal(@2);
            value2.value = @3;
            expect(value.value).to.equal(@3);
        });
        
        it(@"will raise an exception if add a upstream but it is single upstream ERNode", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            expect(^{
                [value2 addUpstreamNode:value1];
            }).to.raiseWithReason(ERNodeExceptionName, ERExceptionReason_AddUpstreamButItsSingleUpstream);
        });
        
        it(@"can remove upstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value2 setUpstreamNode:value1];
            expect(value2.hasUpstreamNode).to.beTruthy();
            expect(value1.hasDownstreamNode).to.beTruthy();
            [value2 removeUpstreamNode:value1];
            expect(value2.hasUpstreamNode).to.beFalsy();
            expect(value1.hasDownstreamNode).to.beFalsy();
        });
        
        it(@"won't have side effect when you remove a upstream which is not really upstream", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value1 removeDownstreamNode:value2];
            expect(value2.hasUpstreamNode).to.beFalsy();
            expect(value1.hasDownstreamNode).to.beFalsy();
            
            value1.value = @2;
            expect(value2.value).notTo.equal(@2);
        });
        
        it(@"can remove all upstreamNodes for single upstream ERNode", ^{
            ERNode<NSNumber *> *value1 = [ERNode value:@1];
            ERNode<NSNumber *> *value2 = ERNode.new;
            
            [value2 setUpstreamNode:value1];
            value1.value = @2;
            
            [value2 removeUpstreamNodes];
            expect(value2.hasUpstreamNode).to.beFalsy();
            expect(value1.hasDownstreamNode).to.beFalsy();
            
            value1.value = @3;
            expect(value2.value).notTo.equal(@3);
        });
        
        it(@"can remove all upstreamNodes for multi upstream ERNode", ^{
            ERNode<NSNumber *> *value1 = ERNode.new;
            ERNode<NSNumber *> *value2 = ERNode.new;
            ERNode *value = [ERNode multiUpstreamNode];
            
            [value addUpstreamNode:value1];
            [value addUpstreamNode:value2];
            
            [value removeUpstreamNodes];
            expect(value.hasUpstreamNode).to.beFalsy();
            expect(value1.hasDownstreamNode).to.beFalsy();
            expect(value2.hasDownstreamNode).to.beFalsy();
            
            value1.value = @3;
            expect(value.value).notTo.equal(@3);
            value2.value = @2;
            expect(value.value).notTo.equal(@2);
        });
        
        it(@"will dealloc if upstream dealloc", ^{
            __weak ERNode *value1 = nil;
            __weak ERNode *value2 = nil;
            @autoreleasepool {
                value1 = [ERNode value:@1];
                ERNode *value = ERNode.new;
                value2 = value;
                [value1 addDownstreamNode:value2];
                
                expect(value2).notTo.beNil();
            }
            expect(value2).to.beNil();
            
            ERNode *value3 = [ERNode value:@3];
            @autoreleasepool {
                ERNode *value = ERNode.new;
                value2 = value;
                [value3 addDownstreamNode:value2];
                
                [value2 removeUpstreamNodes];
            }
            expect(value2).to.beNil();
        });
        
        it(@"cann't dealloc if have upstream and listener", ^{
            ERNode *value1 = [ERNode value:@1];
            __weak ERNode *value2 = nil;
            @autoreleasepool {
                ERNode *value = ERNode.new;
                value2 = value;
                [value1 addDownstreamNode:value2];
                
                [value2 listen:^(id next) {
                    
                }];
            }
            expect(value2).notTo.beNil();
            expect(value1.hasDownstreamNode).to.beTruthy();
        });
        
        it(@"will dealloc if have upstream but not listener or strong reference", ^{
            ERNode *value1 = [ERNode value:@1];
            __weak ERNode *value2 = nil;
            @autoreleasepool {
                ERNode *value = ERNode.new;
                value2 = value;
                [value1 addDownstreamNode:value2];
            }
            expect(value2).to.beNil();
            expect(value1.hasDownstreamNode).to.beFalsy();
        });
        
        it(@"will be released when its upstream is released even if there is a listener listening to it", ^{
            expect(^(CheckReleaseTool *checkTool) {
                ERNode *value1 = [ERNode value:@1];
                ERNode *value2 = ERNode.new;
                
                [value1 addDownstreamNode:value2];
                [value2 listen:^(id next) {
                    
                }];
                
                [checkTool checkObj:value1];
                [checkTool checkObj:value2];
            }).to.beReleasedCorrectly();
        });
        
        it(@"won't dealloc if have upstream not listener but as a strong reference", ^{
            ERNode *value1 = [ERNode value:@1];
            ERNode *value2 = nil;
            @autoreleasepool {
                ERNode *value = ERNode.new;
                value2 = value;
                [value1 addDownstreamNode:value2];
            }
            expect(value2).notTo.beNil();
            expect(value1.hasDownstreamNode).to.beTruthy();
        });
        
        it(@"will dealloc after last listener cancel", ^{
            ERNode *value1 = [ERNode value:@1];
            __weak ERNode *value2 = nil;
            id<ERCancelable> cancelable = nil;
            @autoreleasepool {
                @autoreleasepool {
                    ERNode *value = ERNode.new;
                    value2 = value;
                    
                    [value2 setUpstreamNode:value1];
                    
                    cancelable = [value2 listen:^(id next) {
                        
                    }];
                }
                expect(value2).notTo.beNil();
                expect(value1.hasDownstreamNode).to.beTruthy();
                
                [cancelable cancel];
            }
            expect(value2).to.beNil();
            expect(value1.hasDownstreamNode).to.beFalsy();
        });
        
        it(@"will dealloc as a chain after last listener cancel", ^{
            ERNode *value1 = [ERNode value:@1];
            __weak ERNode *value2 = nil;
            __weak ERNode *value3 = nil;
            id<ERCancelable> cancelable = nil;
            @autoreleasepool {
                @autoreleasepool {
                    ERNode *strongValue1 = [ERNode value:EREmpty.empty];
                    ERNode *strongValue2 = [ERNode value:EREmpty.empty];
                    value2 = strongValue1;
                    value3 = strongValue2;

                    [value2 setUpstreamNode:value1];
                    [value3 setUpstreamNode:value2];

                    cancelable = [value3 listen:^(id next) {
                        
                    }];
                }
                expect(value2).notTo.beNil();
                expect(value3).notTo.beNil();
                expect(value1.hasDownstreamNode).to.beTruthy();
                expect(value2.hasDownstreamNode).to.beTruthy();
                
                [cancelable cancel];
            }
            expect(value2).to.beNil();
            expect(value3).to.beNil();
            expect(value1.hasDownstreamNode).to.beFalsy();
        });
        
        it(@"will automatically remove a released upstream", ^{
            __weak ERNode *value1 = nil;
            ERNode *value2 = nil;
            @autoreleasepool {
                ERNode *strongValue1 = [ERNode value:@1];
                value1 = strongValue1;
                value2 = ERNode.new;
                
                [value2 setUpstreamNode:value1];
                expect(value2.hasUpstreamNode).to.beTruthy();
            }
            expect(value1).to.beNil();
            expect(value2).notTo.beNil();
            expect(value2.hasUpstreamNode).to.beFalsy();
        });
    });
    
});

SpecEnd

