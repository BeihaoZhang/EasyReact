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

QuickSpecBegin(ERNodeSpec)

describe(@"ERNode common test", ^{
    context(@"common test", ^{
        it(@"can store a value", ^{
            ERNode *testNode = [ERNode value:@1];
            
            expect(testNode.value).to(equal(@1));
            expect(testNode).notTo(beEmptyValue());
        });
        
        it(@"can get a empty value if only use init without first value", ^{
            ERNode *testNode = [ERNode new];
            expect(testNode).to(beEmptyValue());
            expect(testNode.isEmpty).to(beTrue());
        });
        
        it(@"can clean the value", ^{
            ERNode *testNode = [ERNode value:@1];
            
            expect(testNode.value).to(equal(@1));
            [testNode clean];
            expect(testNode).to(beEmptyValue());
        });
        
        it(@"can get last value when set some times", ^{
            ERNode *testNode = [ERNode value:@1];
            testNode.value = @2;
            testNode.value = @3;
            expect(testNode.value).to(equal(@3));
        });
        
        it(@"can listen each values after listening", ^{
            ERNode<NSNumber *> *testNode = [ERNode value:@1];
            NSMutableArray<NSNumber *> *array = [NSMutableArray array];
            [testNode listen:^(NSNumber *next) {
                [array addObject:next];
            }];
            testNode.value = @2;
            testNode.value = @3;
            
            expect(testNode.hasListener).to(beTruthy());
            expect(array).to(equal(@[@1, @2, @3]));
            
            NSMutableArray<NSNumber *> *array2 = [NSMutableArray array];
            [testNode listen:^(NSNumber *next) {
                [array2 addObject:next];
            }];
            
            testNode.value = @4;
            testNode.value = @5;
            
            expect(array2).to(equal(@[@3, @4, @5]));
        });
        
        it(@"can deliver the listen block of an ERNode to the main queue", ^{
            dispatch_queue_t queue = dispatch_queue_create("test-queue", DISPATCH_QUEUE_SERIAL);
            
            waitUntil(^(void (^done)(void)) {
                dispatch_async(queue, ^{
                    ERNode *value = [ERNode value:@100];
                    [value listenOnMainQueue:^(id  _Nullable next) {
                        expect([NSThread isMainThread]).to(beTrue());
                    }];
                    value.value = @200;
                    done();
                });
            });
        });
        
        it(@"can deliver the listen block of an ERNode to a specified queue", ^{
            dispatch_queue_t queue = dispatch_queue_create("test-queue", DISPATCH_QUEUE_SERIAL);
            
            waitUntil(^(void (^done)(void)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ERNode *value = [ERNode value:@100];
                    ERListenerBlockType listenrBlock = ^(id _Nullable next) {
                        expect([NSThread isMainThread]).to(beFalsy());
                    };
                    [value listen:listenrBlock on:queue];
                    value.value = @200;
                    done();
                });
            });
        });
        
        it(@"deliver the listen block of an ERNode to a NULL queue should raise an asset",^{
            dispatch_queue_t queue = NULL;
            
            assertExpect(^{
                ERNode *value = [ERNode value:@100];
                ERListenerBlockType listenrBlock = ^(id _Nullable next) {};
                [value listen:listenrBlock on:queue];
                value.value = @200;
            }).to(hasParameterAssert());
        });
        
        it(@"should raise an asset if initalizing an ERBlockDeliveredListener use a NULL queue ",^{
            dispatch_queue_t queue = NULL;
            ERListenerBlockType listenrBlock = ^(id _Nullable next) {};
            
            assertExpect(^{
                ERBlockDeliveredListener *listener __attribute((unused)) = [[ERBlockDeliveredListener alloc] initWithBlock:listenrBlock on:queue];
            }).to(hasParameterAssert());
        });
        
        it(@"can add your custom listener", ^{
            ERNode<NSNumber *> *testNode = [ERNode value:@1];
            TestListener *listener = [TestListener new];
            
            [testNode addListener:listener];
            
            testNode.value = @2;
            testNode.value = @3;
            
            expect(listener.receiveValues).to(haveCount(3));
            expect(listener.receiveValues).to(equal(@[@1, @2, @3]));
        });
        
        it(@"can't callback the empty value", ^{
            ERNode<NSNumber *> *testNode = [ERNode new];
            
            [testNode startListenForTest];
            
            testNode.value = @2;
            testNode.value = @3;
            testNode.value = (NSNumber *)EREmpty.new;
            
            expect(testNode).to(receive(@[@2, @3]));
        });
        
        it(@"can stop listen using cancelable object after listening", ^{
            ERNode<NSNumber *> *testNode = [ERNode value:@1];
            
            id<ERCancelable> cancelable = [testNode startListenForTest];
            
            testNode.value = @2;
            [cancelable cancel];
            testNode.value = @3;
            
            expect(testNode).to(receive(@[@1,@2]));
        });
        
        it(@"can be released correctly after listening", ^{
            TestListener *listener = TestListener.new;
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                ERNode<NSNumber *> *testNode = [ERNode value:@1];
                [testNode addListener:listener];
                [checkTool checkObj:testNode];
            };
            
            expectCheckTool(check).to(beReleasedCorrectly());
        });
        
    });
    
    context(@" upstream and downstream", ^{
        
        it(@"can link another ERNode as an upstream", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = [ERNode new];
            
            ERTransform *transform = [ERTransform new];
            expect(transform.from).to(beNil());
            expect(transform.to).to(beNil());
            
            [downstream linkTo:upstream transform:transform];
            expect(downstream.value).to(equal(@1));
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(upstream.downstreamNodes).to(contain(downstream));
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(downstream.upstreamNodes).to(contain(upstream));
            expect(transform.from).to(equal(upstream));
            expect(transform.to).to(equal(downstream));
            upstream.value = @2;
            expect(downstream.value).to(equal(@2));
        });
        
        it(@"can cancel two ERNode's link", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = [ERNode new];
            
            id<ERCancelable> cancelable = [downstream linkTo:upstream transform:[ERTransform new]];
            
            expect(downstream.value).to(equal(@1));
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(upstream.hasDownstreamNode).to(beTruthy());
            
            [cancelable cancel];
            upstream.value = @2;
            
            expect(downstream.value).notTo(equal(@2));
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(downstream.hasDownstreamNode).to(beFalsy());
        });
        
        it(@"can link another ERNode use default transform",^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = [ERNode new];
            [downstream linkTo:upstream];
            
            expect(downstream.value).to(equal(@1));
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(upstream.downstreamNodes).to(contain(downstream));
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(downstream.upstreamNodes).to(contain(upstream));
            upstream.value = @2;
            expect(downstream.value).to(equal(@2));
        });
        
        it(@"can set another value after linkTo another Node",^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = [ERNode new];
            [downstream linkTo:upstream];
            
            upstream.value = @2;
            expect(downstream.value).to(equal(@2));
            
            downstream.value = @3;
            expect(downstream.value).to(equal(@3));
            expect(upstream.value).notTo(equal(@3));
            
            upstream.value = @4;
            expect(upstream.value).to(equal(@4));
            expect(downstream.value).to(equal(@4));
        });
        
        it(@"can remove a downstream", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = ERNode.new;
            
            [downstream linkTo:upstream];
            expect(downstream.value).to(equal(@1));
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(upstream.hasDownstreamNode).to(beTruthy());
            
            [upstream removeDownstreamNode:downstream];
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"can remove a downstream transform",^(){
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = ERNode.new;
            ERTransform *transform = [ERTransform new];
            
            [downstream linkTo:upstream transform:transform];
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(transform.from).to(equal(upstream));
            expect(transform.to).to(equal(downstream));
            
            [upstream removeDownstreamTransform:transform];
            expect(upstream.hasDownstreamNode).to(beFalse());
            expect(downstream.hasUpstreamNode).to(beFalse());
            expect(transform.from).to(beNil());
            expect(transform.to).to(beNil());
            
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"add a transform twice times should raise an asset",^{
            ERNode<NSNumber *> *upstream1 = [ERNode value:@1];
            ERNode<NSNumber *> *downstream1 = ERNode.new;
            ERTransform *transform = [ERTransform new];
            [downstream1 linkTo:upstream1 transform:transform];
        
            expect(transform.from).to(equal(upstream1));
            expect(transform.to).to(equal(downstream1));
            
            assertExpect(^{
                ERNode<NSNumber *> *upstream2 = [ERNode value:@2];
                ERNode<NSNumber *> *downstream2 = ERNode.new;
                [downstream2 linkTo:upstream2 transform:transform];
            }).to(hasAssert());
            expect(transform.from).to(equal(upstream1));
            expect(transform.to).to(equal(downstream1));
        });
        
        it(@"should not have side effect when you remove a downstream which is not really downstream", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = ERNode.new;
            
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            
            [upstream removeDownstreamNode:downstream];
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"can remove all downstreamNodes", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream1 = ERNode.new;
            ERNode<NSNumber *> *downstream2 = ERNode.new;
            
            [downstream1 linkTo:upstream];
            [downstream2 linkTo:upstream];
            expect(upstream.downstreamNodes).to(haveCount(2));
            expect(upstream.downstreamNodes).to(contain(downstream1, downstream2));
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(downstream1.hasUpstreamNode).to(beTruthy());
            expect(downstream2.hasUpstreamNode).to(beTruthy());
            
            [upstream removeDownstreamNodes];
            expect(upstream.hasDownstreamNode).to(beFalse());
            expect(downstream1.hasUpstreamNode).to(beFalse());
            expect(downstream2.hasUpstreamNode).to(beFalse());
        });
        
        it(@"can remove an upstream node", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = ERNode.new;
            
            [downstream linkTo:upstream];
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(downstream.hasUpstreamNode).to(beTruthy());
            
            [downstream removeUpstreamNode:upstream];
            expect(upstream.hasDownstreamNode).to(beFalsy());
            expect(downstream.hasUpstreamNode).to(beFalsy());
            
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"can remove an upstream transform",^(){
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = ERNode.new;
            ERTransform *transform = [ERTransform new];
            
            [downstream linkTo:upstream transform:transform];
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(transform.from).to(equal(upstream));
            expect(transform.to).to(equal(downstream));
            
            [downstream removeUpstreamTransform:transform];
            expect(upstream.hasDownstreamNode).to(beFalse());
            expect(downstream.hasUpstreamNode).to(beFalse());
            expect(transform.from).to(beNil());
            expect(transform.to).to(beNil());
        });
        
        it(@"should not have side effect when you remove an upstream which is not really upstream", ^{
            ERNode<NSNumber *> *upstream = [ERNode value:@1];
            ERNode<NSNumber *> *downstream = ERNode.new;
            
            [downstream removeUpstreamNode:upstream];
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"should get new value when any upstreamNodes changed",^{
            ERNode<NSNumber *> *upstream1 = [ERNode value:@1];
            ERNode<NSNumber *> *upstream2 = [ERNode value:@2];
            ERNode<NSNumber *> *downstream = ERNode.new;
 
            [downstream linkTo:upstream1];
            expect(downstream.value).to(equal(@1));
            [downstream linkTo:upstream2];
            expect(downstream.value).to(equal(@2));

            upstream1.value = @3;
            expect(downstream.value).to(equal(@3));
            upstream2.value = @4;
            expect(downstream.value).to(equal(@4));
        });
        
        it(@"can remove all upstreamNodes", ^{
            ERNode<NSNumber *> *upstream1 = [ERNode value:@1];
            ERNode<NSNumber *> *upstream2 = [ERNode value:@2];
            ERNode<NSNumber *> *downstream = ERNode.new;

            [downstream linkTo:upstream1];
            [downstream linkTo:upstream2];
            expect(downstream.upstreamNodes).to(haveCount(2));
            expect(downstream.upstreamNodes).to(contain(upstream1,upstream2));
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(upstream1.hasDownstreamNode).to(beTruthy());
            expect(upstream2.hasDownstreamNode).to(beTruthy());
            
            [downstream removeUpstreamNodes];
            expect(upstream1.hasDownstreamNode).to(beFalse());
            expect(upstream2.hasDownstreamNode).to(beFalse());
            expect(downstream.hasUpstreamNode).to(beFalse());
            
            upstream1.value = @3;
            expect(downstream.value).notTo(equal(@3));
            upstream2.value = @4;
            expect(downstream.value).notTo(equal(@4));
        });
        
        it(@"should dealloc if upstream dealloc", ^{
            __weak ERNode *upstream = nil;
            __weak ERNode *downstream = nil;
            @autoreleasepool {
                ERNode *node = [ERNode value:@1];
                upstream = node;
                ERNode *value = ERNode.new;
                downstream = value;
                [downstream linkTo:upstream];
                expect(downstream).notTo(beNil());
            }
            expect(downstream).to(beNil());
            
            ERNode *upstream2 = [ERNode value:@3];
            @autoreleasepool {
                ERNode *value = ERNode.new;
                downstream = value;
                [downstream linkTo:upstream2];
                [downstream removeUpstreamNodes];
            }
            expect(downstream).to(beNil());
        });
        
        it(@"cann't dealloc if have upstream and listener", ^{
            ERNode *upstream = [ERNode value:@1];
            __weak ERNode *downstream = nil;
            @autoreleasepool {
                ERNode *value = ERNode.new;
                downstream = value;
                [downstream linkTo:upstream];
                [downstream listen:^(id  _Nullable next) {
                    
                }];
            }
            expect(downstream).notTo(beNil());
            expect(upstream.hasDownstreamNode).to(beTruthy());
        });
        
        it(@"should dealloc if have upstream but not listener or strong reference", ^{
            ERNode *upstream = [ERNode value:@1];
            __weak ERNode *downstream = nil;
            @autoreleasepool {
                ERNode *value = ERNode.new;
                downstream = value;
                [downstream linkTo:upstream];
            }
            expect(downstream).to(beNil());
            expect(upstream.hasDownstreamNode).to(beFalsy());
        });
        
        it(@"should be released when its upstream is released even if there is a listener listening to it", ^{
            void (^block)(CheckReleaseTool *) = ^(CheckReleaseTool *checkTool) {
                ERNode *upstream = [ERNode value:@1];
                upstream.name = @"up";
                ERNode *downstream = ERNode.new;
                downstream.name = @"down";
                
                [downstream linkTo:upstream];
                [downstream listen:^(id next) {
                    
                }];
                
                [checkTool checkObj:upstream];
                [checkTool checkObj:downstream];
            };
            expectCheckTool(block).to(beReleasedCorrectly());
        });
        
        it(@"should not dealloc if have upstream not listener but as a strong reference", ^{
            ERNode *upstream = [ERNode value:@1];
            ERNode *downstream = nil;
            @autoreleasepool {
                ERNode *value = ERNode.new;
                downstream = value;
                [downstream linkTo:upstream];
                
            }
            expect(downstream).notTo(beNil());
            expect(upstream.hasDownstreamNode).to(beTruthy());
        });
        
        it(@"should dealloc after last listener cancel", ^{
            ERNode *upstream = [ERNode value:@1];
            __weak ERNode *downstream = nil;
            id<ERCancelable> cancelable = nil;
            @autoreleasepool {
                @autoreleasepool {
                    ERNode *value = ERNode.new;
                    downstream = value;
                    
                    [downstream linkTo:upstream transform:ERTransform.new];
                    
                    cancelable = [downstream listen:^(id next) {
                        
                    }];
                }
                expect(downstream).notTo(beNil());
                expect(upstream.hasDownstreamNode).to(beTruthy());
                
                [cancelable cancel];
            }
            expect(downstream).to(beNil());
            expect(upstream.hasDownstreamNode).to(beFalsy());
        });
        
        it(@"should dealloc as a chain after last listener cancel", ^{
            ERNode *upstream = [ERNode value:@1];
            __weak ERNode *downstream1 = nil;
            __weak ERNode *downstream2 = nil;
            id<ERCancelable> cancelable = nil;
            @autoreleasepool {
                @autoreleasepool {
                    ERNode *strongValue1 = ERNode.new;
                    ERNode *strongValue2 = ERNode.new;
                    downstream1 = strongValue1;
                    downstream2 = strongValue2;
                    
                    
                    [downstream1 linkTo:upstream];
                    [downstream2 linkTo:upstream];
                    cancelable = [downstream2 listen:^(id next) {
                        
                    }];
                }
                expect(downstream1).to(beNil());
                expect(downstream2).notTo(beNil());
                expect(upstream.hasDownstreamNode).to(beTruthy());
                expect(downstream2.hasUpstreamNode).to(beTruthy());
                
                [cancelable cancel];
            }
            expect(downstream1).to(beNil());
            expect(downstream2).to(beNil());
            expect(upstream.hasDownstreamNode).to(beFalsy());
        });
        
        it(@"should automatically remove a released upstream", ^{
            __weak ERNode *upstream = nil;
            ERNode *downstream = nil;
            @autoreleasepool {
                ERNode *strongValue1 = [ERNode value:@1];
                upstream = strongValue1;
                downstream = ERNode.new;
                
                [downstream linkTo:upstream transform:ERTransform.new];
                expect(downstream.hasUpstreamNode).to(beTruthy());
            }
            expect(upstream).to(beNil());
            expect(downstream).notTo(beNil());
            expect(downstream.hasUpstreamNode).to(beFalsy());
        });
        
    });
    
});

QuickSpecEnd

