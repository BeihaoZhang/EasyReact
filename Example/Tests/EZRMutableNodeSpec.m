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

QuickSpecBegin(ERMutableNodeSpec)

describe(@"EZRMutableNode common test", ^{
    context(@"common test", ^{
        it(@"can store a value", ^{
            EZRMutableNode *testNode = [EZRMutableNode value:@1];
            
            expect(testNode.value).to(equal(@1));
            expect(testNode).notTo(beEmptyValue());
        });
        
        it(@"can get a empty value if only use init without first value", ^{
            EZRMutableNode *testNode = [EZRMutableNode new];
            expect(testNode).to(beEmptyValue());
            expect(testNode.isEmpty).to(beTrue());
        });
        
        it(@"can get last value when set some times", ^{
            EZRMutableNode *testNode = [EZRMutableNode value:@1];
            testNode.value = @2;
            testNode.value = @3;
            expect(testNode.value).to(equal(@3));
        });
        
        it(@"can be modified", ^{
            EZRMutableNode *testNode = [EZRMutableNode value:@1];
            testNode.value = @2;
            expect(testNode.value).to(equal(@2));
            testNode.value = @3;
            expect(testNode.value).to(equal(@3));
        });

        it(@"can clean the value", ^{
            EZRMutableNode *testNode = [EZRMutableNode value:@1];

            expect(testNode.value).to(equal(@1));
            [testNode clean];
            expect(testNode).to(beEmptyValue());
        });
    });
    
    context(@"listener test", ^{
        it(@"can listen each values when listener alive", ^{
            NSObject *listener = [NSObject new];
            EZRMutableNode<NSNumber *> *testNode = [EZRMutableNode value:@1];
            NSMutableArray<NSNumber *> *array = [NSMutableArray array];
            @autoreleasepool {
                [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                    [array addObject:next];
                }];
            }
            expect(testNode.hasListener).to(beTrue());
            
            testNode.value = @2;
            testNode.value = @3;
            
            expect(array).to(equal(@[@1, @2, @3]));
            
            NSMutableArray<NSNumber *> *array2 = [NSMutableArray array];
            
            [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                [array2 addObject:next];
            }];
            
            testNode.value = @4;
            testNode.value = @5;
            
            expect(array2).to(equal(@[@3, @4, @5]));
        });

        
        it(@"can not listen values after listener dealloc", ^{
            EZRMutableNode<NSNumber *> *testNode = [EZRMutableNode value:@1];
            NSMutableArray<NSNumber *> *array = [NSMutableArray array];
            
            @autoreleasepool{
                NSObject *listener = [NSObject new];
                
                [[testNode listenedBy:listener] withBlock:^(NSNumber * _Nullable next) {
                    [array addObject:next];
                }];
                expect(testNode.hasListener).to(beTrue());
                expect(array).to(equal(@[@1]));
            }
            
            testNode.value = @2;
            testNode.value = @3;
            expect(testNode.hasListener).to(beFalse());
            expect(array).to(equal(@[@1]));
        });
        
        it(@"can add your custom listen handler", ^{
            NSObject *listener = [NSObject new];
            EZRMutableNode<NSNumber *> *testNode = [EZRMutableNode value:@1];
            TestListenTransform *listenTransform = [TestListenTransform new];
            
            [[testNode listenedBy:listener] withListenTransform:listenTransform];
            testNode.value = @2;
            testNode.value = @3;
            
            expect(listenTransform.receiveValues).to(haveCount(3));
            expect(listenTransform.receiveValues).to(equal(@[@1, @2, @3]));
        });
        
        it(@"can't callback the empty value", ^{
            NSObject *listener = [NSObject new];
            EZRMutableNode<NSNumber *> *testNode = [EZRMutableNode new];
            [testNode startListenForTestWithObj:listener];
            
            testNode.value = @2;
            testNode.value = @3;
            testNode.value = (NSNumber *)EZREmpty.new;
            
            expect(testNode).to(receive(@[@2, @3]));
        });
    });
});

QuickSpecEnd
