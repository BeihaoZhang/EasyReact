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

QuickSpecBegin(EZRNodeSpec)

describe(@"EZRNode common test", ^{
    context(@"common test", ^{
        it(@"can store a value", ^{
            EZRNode *testNode = [EZRNode value:@1];
            
            expect(testNode.value).to(equal(@1));
            expect(testNode).notTo(beEmptyValue());
        });
        
        it(@"can get a empty value if only use init without first value", ^{
            EZRNode *testNode = [EZRNode new];
            expect(testNode).to(beEmptyValue());
            expect(testNode.isEmpty).to(beTrue());
        });
        
        it(@"should raise exception when set value to a readonly Node", ^{
            EZRNode *testNode = [EZRNode new];
            EZRMutableNode *mutableNode = (EZRMutableNode *)testNode;
            
            expectAction(^{
                mutableNode.value = @1;
            }).to(raiseException().named(EZRNodeExceptionName).reason(EZRExceptionReason_CannotModifyEZRNode));
        });
        
        it(@"can make itself to mutable", ^{
            EZRNode *testNode = [EZRNode new];
            EZRMutableNode *mutableNode = [testNode mutablify];
            mutableNode.value = @1;
            expect(mutableNode.value).to(equal(@1));
            expect(testNode.value).to(equal(@1));
            expect(testNode).to(beIdenticalTo(mutableNode));
        });
        
        it(@"can be listened by listener use listenedBy", ^{
            NSObject *listener = [NSObject new];
            EZRNode<NSNumber *> *node = [EZRNode value:@1];
            __block NSNumber *result = nil;
            [[node listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                result = next;
            }];
            expect(result).to(equal((@1)));
        });
        
        it(@"can deliver the listen block of an EZRNode to the main queue", ^{
            NSObject *listener = [NSObject new];
            dispatch_queue_t queue = dispatch_queue_create("test-queue", DISPATCH_QUEUE_SERIAL);
            
            waitUntil(^(void (^done)(void)) {
                dispatch_async(queue, ^{
                    EZRNode *value = [EZRNode value:@100];
                    
                    [[value listenedBy:listener] withBlockOnMainQueue:^(id  _Nullable next) {
                        expect([NSThread isMainThread]).to(beTrue());
                    }];
                    done();
                });
            });
        });
        
        it(@"can deliver the listen block of an EZRNode to a specified queue", ^{
            NSObject *listener = [NSObject new];
            dispatch_queue_t queue = dispatch_queue_create("test-queue", DISPATCH_QUEUE_SERIAL);
            
            waitUntil(^(void (^done)(void)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    EZRNode *value = [EZRNode value:@100];
                    void (^listenerBlock)(id _Nullable next) = ^(id _Nullable next) {
                        expect([NSThread isMainThread]).to(beFalsy());
                    };
                    [[value listenedBy:listener] withBlock:listenerBlock on:queue];
                    done();
                });
            });
        });
        
        it(@"deliver the listen block of an EZRNode to a NULL queue should raise an asset",^{
            NSObject *listener = [NSObject new];
            dispatch_queue_t queue = NULL;
            
            assertExpect(^{
                EZRNode *value = [EZRNode value:@100];
                void (^listenerBlock)(id _Nullable next) = ^(id _Nullable next) {};
                [[value listenedBy:listener] withBlock:listenerBlock on:queue];
            }).to(hasParameterAssert());
        });
        
        it(@"can add your custom listen handler", ^{
            NSObject *listener = [NSObject new];
            EZRNode<NSNumber *> *testNode = [EZRNode value:@1];
            
            TestListenTransform *listenTransform = [TestListenTransform new];
            [[testNode listenedBy:listener] withListenTransform:listenTransform];
            
            expect(listenTransform.receiveValues).to(equal(@[@1]));
        });
        
        it(@"can be released correctly after listening", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                NSObject *listener = [NSObject new];
                EZRNode<NSNumber *> *testNode = [EZRNode value:@1];
                TestListenTransform *listenTransform = [TestListenTransform new];
                [[testNode listenedBy:listener] withListenTransform:listenTransform];
                [checkTool checkObj:testNode];
            };
            
            expectCheckTool(check).to(beReleasedCorrectly());
        });
        
    });
    
    context(@"mutate state test", ^{
        it(@"should be immutable for EZRNode", ^{
            EZRNode *node = [EZRNode new];
            expect(node.isMutable).to(beFalse());
        });
        
        it(@"should be mutable for EZRMutableNode", ^{
            EZRMutableNode *node = [EZRMutableNode new];
            expect(node.isMutable).to(beTrue());
        });
        
        it(@"can switch EZRNode to EZRMutableNode use mutabify method ", ^{
            EZRNode *node = [EZRNode new];
            expect(node.isMutable).to(beFalse());
            EZRMutableNode *mutableNode = [node mutablify];
            expect(node.isMutable).to(beTrue());
            expect(mutableNode.isMutable).to(beTrue());
        });
    });
    
    context(@"upstream and downstream", ^{
        
        it(@"can link another EZRNode as an upstream", ^{
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = [EZRNode new];
            
            EZRTransform *transform = [EZRTransform new];
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
        
        it(@"can cancel two EZRNode's link", ^{
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = [EZRNode new];
            
            id<EZRCancelable> cancelable = [downstream linkTo:upstream transform:[EZRTransform new]];
            
            expect(downstream.value).to(equal(@1));
            expect(downstream.hasUpstreamNode).to(beTruthy());
            expect(upstream.hasDownstreamNode).to(beTruthy());
            
            [cancelable cancel];
            upstream.value = @2;
            
            expect(downstream.value).notTo(equal(@2));
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(downstream.hasDownstreamNode).to(beFalsy());
        });
        
        it(@"can link another EZRNode use default transform",^{
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = [EZRNode new];
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
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRMutableNode<NSNumber *> *downstream = [EZRMutableNode new];
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
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = EZRNode.new;
            
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
        
        it(@"can fetch all upstream transfrom from node", ^{
            EZRNode *node = [EZRNode new];
            EZRNode *from = [EZRNode new];
            EZRTransform *transform1 = [EZRTransform new];
            EZRTransform *transform2 = [EZRTransform new];
            EZRTransform *transform3 = [EZRTransform new];
            [node linkTo:from transform:transform1];
            [node linkTo:from transform:transform2];
            [node linkTo:from transform:transform3];
            
            NSArray *array = [node upstreamTransformsFromNode:from];
            
            expect(array).to(equal(@[transform1, transform2, transform3]));
        });
        
        it(@"can fetch empty upstream transfrom from node which there is no relation between them", ^{
            EZRNode *node = [EZRNode new];
            EZRNode *from = [EZRNode new];
            
            NSArray *array = [node upstreamTransformsFromNode:from];
            
            expect(array).to(beEmpty());
        });
        
        it(@"can fetch all downstream transfrom to node", ^{
            EZRNode *node = [EZRNode new];
            EZRNode *to = [EZRNode new];
            EZRTransform *transform1 = [EZRTransform new];
            EZRTransform *transform2 = [EZRTransform new];
            EZRTransform *transform3 = [EZRTransform new];
            [to linkTo:node transform:transform1];
            [to linkTo:node transform:transform2];
            [to linkTo:node transform:transform3];
            
            NSArray *array = [node downstreamTransformsToNode:to];
            expect(array).to(equal(@[transform1, transform2, transform3]));
        });
        
        it(@"can fetch empty downstream transfrom from node which there is no relation between them", ^{
            EZRNode *node = [EZRNode new];
            EZRNode *to = [EZRNode new];
            
            NSArray *array = [node downstreamTransformsToNode:to];
            
            expect(array).to(beEmpty());
        });
        
        it(@"add a transform twice times should raise an asset",^{
            EZRNode<NSNumber *> *upstream1 = [EZRNode value:@1];
            EZRNode<NSNumber *> *downstream1 = EZRNode.new;
            EZRTransform *transform = [EZRTransform new];
            [downstream1 linkTo:upstream1 transform:transform];
            
            expect(transform.from).to(equal(upstream1));
            expect(transform.to).to(equal(downstream1));
            
            assertExpect(^{
                EZRNode<NSNumber *> *upstream2 = [EZRNode value:@2];
                EZRNode<NSNumber *> *downstream2 = EZRNode.new;
                [downstream2 linkTo:upstream2 transform:transform];
            }).to(hasAssert());
            expect(transform.from).to(equal(upstream1));
            expect(transform.to).to(equal(downstream1));
        });
        
        it(@"should not have side effect when you remove a downstream which is not really downstream", ^{
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = EZRNode.new;
            
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            
            [upstream removeDownstreamNode:downstream];
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"can remove all downstreamNodes", ^{
            EZRNode<NSNumber *> *upstream = [EZRNode value:@1];
            EZRNode<NSNumber *> *downstream1 = EZRNode.new;
            EZRNode<NSNumber *> *downstream2 = EZRNode.new;
            
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
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = EZRNode.new;
            
            [downstream linkTo:upstream];
            expect(upstream.hasDownstreamNode).to(beTruthy());
            expect(downstream.hasUpstreamNode).to(beTruthy());
            
            [downstream removeUpstreamNode:upstream];
            expect(upstream.hasDownstreamNode).to(beFalsy());
            expect(downstream.hasUpstreamNode).to(beFalsy());
            
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"should not have side effect when you remove an upstream which is not really upstream", ^{
            EZRMutableNode<NSNumber *> *upstream = [EZRMutableNode value:@1];
            EZRNode<NSNumber *> *downstream = EZRNode.new;
            
            [downstream removeUpstreamNode:upstream];
            expect(downstream.hasUpstreamNode).to(beFalsy());
            expect(upstream.hasDownstreamNode).to(beFalsy());
            upstream.value = @2;
            expect(downstream.value).notTo(equal(@2));
        });
        
        it(@"should get new value when any upstreamNodes changed",^{
            EZRMutableNode<NSNumber *> *upstream1 = [EZRMutableNode value:@1];
            EZRMutableNode<NSNumber *> *upstream2 = [EZRMutableNode value:@2];
            EZRNode<NSNumber *> *downstream = EZRNode.new;
            
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
            EZRMutableNode<NSNumber *> *upstream1 = [EZRMutableNode value:@1];
            EZRMutableNode<NSNumber *> *upstream2 = [EZRMutableNode value:@2];
            EZRNode<NSNumber *> *downstream = EZRNode.new;
            
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
    });
    
    context(@"node transform and listener memory management ", ^{
        it(@"cann't dealloc if have downstream or listener", ^{
            NSObject *listener = [NSObject new];
            __weak EZRNode *upstream = nil;
            
            @autoreleasepool {
                EZRNode *node = [EZRNode new];
                upstream = node;
                [[node listenedBy:listener] withBlock:^(id  _Nullable next) {
                    
                }];
            }
            
            expect(upstream).notTo(beNil());
            expect(upstream.hasListener).to(beTrue());
            
            upstream = nil;
            EZRNode *downstream = [EZRNode new];
            @autoreleasepool {
                EZRNode *value = EZRNode.new;
                upstream = value;
                [downstream linkTo:upstream];
            }
            expect(upstream).notTo(beNil());
            expect(upstream.hasDownstreamNode).to(beTrue());
        });
        
        it(@"should dealloc if downstream dealloc", ^{
            __weak EZRNode *upstream = nil;
            __weak EZRNode *downstream = nil;
            @autoreleasepool {
                EZRNode *node = [EZRNode value:@1];
                upstream = node;
                EZRNode *value = EZRNode.new;
                downstream = value;
                [downstream linkTo:upstream];
                expect(downstream).notTo(beNil());
            }
            expect(upstream).to(beNil());
            expect(downstream).to(beNil());
            
            EZRNode *upstream2 = [EZRNode value:@3];
            @autoreleasepool {
                EZRNode *value = EZRNode.new;
                downstream = value;
                [downstream linkTo:upstream2];
                [downstream removeUpstreamNodes];
            }
            expect(downstream).to(beNil());
        });
        
        it(@"should dealloc if listener cancelable cancel", ^{
            __weak EZRNode *upstream = nil;
            NSObject *object;
            @autoreleasepool {
                object = [NSObject new];
                EZRNode *node = [EZRNode value:@1];
                upstream = node;
                
                id<EZRCancelable> cancelable = [[node listenedBy:object] withBlock:^(id  _Nullable next) {
                    
                }];
                expect(upstream).notTo(beNil());
                [cancelable cancel];
            }
            expect(upstream).to(beNil());
            
            @autoreleasepool {
                EZRNode *node = [EZRNode value:@1];
                upstream = node;
                [[node listenedBy:object] withBlock:^(id  _Nullable next) {
                    
                }];
                expect(upstream).notTo(beNil());
                object = nil;
            }
            
            expect(upstream).to(beNil());
        });
        
        it(@"should dealloc if have upstream but not have listener or strong reference", ^{
            EZRNode *upstream = [EZRNode value:@1];
            __weak EZRNode *downstream = nil;
            @autoreleasepool {
                EZRNode *value = EZRNode.new;
                downstream = value;
                [downstream linkTo:upstream];
            }
            expect(downstream).to(beNil());
            expect(upstream).notTo(beNil());
        });
    });
    
    it(@"should dealloc as a chain after last listener cancel", ^{
        __weak EZRNode *upstream = nil;
        __weak EZRNode *middlestream = nil;
        __weak EZRNode *downstream = nil;
        NSObject *obj = [NSObject new];
        id<EZRCancelable> cancelable = nil;
        
        // up->middle->down
        @autoreleasepool {
            @autoreleasepool {
                EZRNode *strongValue1 = [EZRNode value:@1];
                EZRNode *strongValue2 = EZRNode.new;
                EZRNode *strongValue3 = EZRNode.new;
                upstream = strongValue1;
                middlestream = strongValue2;
                downstream = strongValue3;
                
                [middlestream linkTo:upstream];
                [downstream linkTo:middlestream];
                cancelable = [[downstream listenedBy:obj] withBlock:^(id  _Nullable next) {
                    
                }];
            }
            expect(upstream).notTo(beNil());
            expect(middlestream).notTo(beNil());
            expect(middlestream).notTo(beNil());
            
            [cancelable cancel];
        }
        expect(upstream).to(beNil());
        expect(middlestream).to(beNil());
        expect(middlestream).to(beNil());
    });
});

QuickSpecEnd
