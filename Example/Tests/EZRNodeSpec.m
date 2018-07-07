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

describe(@"EZRNode", ^{
    it(@"can store a value", ^{
        EZRNode *testNode = [EZRNode value:@1];
        
        expect(testNode.value).to(equal(@1));
        expect(testNode).notTo(beEmptyValue());
    });
    
    context(@"-init method,",^{
        it(@"should get an empty value", ^{
            EZRNode *testNode = [EZRNode new];
            expect(testNode).to(beEmptyValue());
            expect(testNode.isEmpty).to(beTrue());
        });
    });
    
    it(@"should raise exception when set value to a readonly EZRNode", ^{
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
    
    context(@"- listenedBy: method,", ^{
        it(@"can be listened by listener", ^{
            NSObject *listener = [NSObject new];
            EZRNode<NSNumber *> *node = [EZRNode value:@1];
            __block NSNumber *result = nil;
            [[node listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                result = next;
            }];
            expect(result).to(equal((@1)));
        });
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
    
    it(@"should raise an asset when delivering the listen block of an EZRNode to a NULL queue",^{
        NSObject *listener = [NSObject new];
        dispatch_queue_t queue = NULL;
        
        assertExpect(^{
            EZRNode *value = [EZRNode value:@100];
            void (^listenerBlock)(id _Nullable next) = ^(id _Nullable next) {};
            [[value listenedBy:listener] withBlock:listenerBlock on:queue];
        }).to(hasParameterAssert());
    });
    
    it(@"can add your customized listen edge", ^{
        NSObject *listener = [NSObject new];
        EZRNode<NSNumber *> *testNode = [EZRNode value:@1];
        
        TestListenEdge *edge = [TestListenEdge new];
        [[testNode listenedBy:listener] withListenEdge:edge];
        
        expect(edge.receiveValues).to(equal(@[@1]));
    });
    
    it(@"can be released correctly after being listened", ^{
        void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
            NSObject *listener = [NSObject new];
            EZRNode<NSNumber *> *testNode = [EZRNode value:@1];
            TestListenEdge *edge = [TestListenEdge new];
            [[testNode listenedBy:listener] withListenEdge:edge];
            [checkTool checkObj:testNode];
        };
        expectCheckTool(check).to(beReleasedCorrectly());
    });
    
});

describe(@"Mutable status", ^{
    it(@"should be immutable for EZRNode", ^{
        EZRNode *node = [EZRNode new];
        expect(node.isMutable).to(beFalse());
    });
    
    it(@"should be mutable for EZRMutableNode", ^{
        EZRMutableNode *node = [EZRMutableNode new];
        expect(node.isMutable).to(beTrue());
    });
    
    it(@"of node can switch from immutable to mutable use mutabify method", ^{
        EZRNode *node = [EZRNode new];
        expect(node.isMutable).to(beFalse());
        EZRMutableNode *mutableNode = [node mutablify];
        expect(node.isMutable).to(beTrue());
        expect(mutableNode.isMutable).to(beTrue());
    });
});

//upstream and downstream
describe(@"Node with link relationship", ^{
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
    
    it(@"can cancel the link", ^{
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
    
    context(@"- upstreamTransformsFromNode: method,", ^{
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
        
        it(@"should fetch empty upstream transfrom from node when there is no relationship", ^{
            EZRNode *node = [EZRNode new];
            EZRNode *from = [EZRNode new];
            
            NSArray *array = [node upstreamTransformsFromNode:from];
            
            expect(array).to(beEmpty());
        });
    });
    
    context(@"- upstreamTransformsFromNode: method,", ^{
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
        
        it(@"should fetch empty downstream transfrom from node when there is no relationship", ^{
            EZRNode *node = [EZRNode new];
            EZRNode *to = [EZRNode new];
            
            NSArray *array = [node downstreamTransformsToNode:to];
            
            expect(array).to(beEmpty());
        });
    });
    
    it(@"should raise an asset when adding a transform twice",^{
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
    
    it(@"should not have side effect when removing a node which has no relationship as downstream", ^{
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
    
    it(@"should not have side effect when removing a node which has no relationship as upstream", ^{
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

//Node transform and listener memory management
describe(@"Node", ^{
    
    it(@"cann't dealloc with downstream or listener", ^{
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
    
    it(@"should dealloc when node's downstream dealloc", ^{
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
    
    it(@"should dealloc when node's listener canceled", ^{
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
    
    it(@"should dealloc if node has upstream but neither listener nor strong reference", ^{
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
    
    it(@"should dealloc when the listen chain's last listener canceled", ^{
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
