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

QuickSpecBegin(NSObjectExtension)

describe(@"NSObject extension test", ^{
    context(@"KVO", ^{
        it(@"can get a value from an object(KVO)", ^{
            TestKVOClass *obj = [TestKVOClass new];
            obj.property1 = @"aaa";
            
            EZRNode *observer = obj.ezr_path[@"property1"];
            
            [observer startListenForTestWithObj:obj];
            expect(observer.value).to(equal(@"aaa"));
            
            obj.property1 = @"bbb";
            expect(observer.value).to(equal(@"bbb"));
            
            expect(observer).to(receive(@[@"aaa", @"bbb"]));
        });

        it(@"becomes nil if the property is set to nil", ^{
            TestKVOClass *obj = [TestKVOClass new];
            obj.property1 = @"aaa";
            
            EZRNode *observer = obj.ezr_path[@"property1"];
            expect(observer.value).to(equal(@"aaa"));
            
            obj.property1 = nil;
            expect(observer.value).to(beNil());
        });
    });

    context(@"KVC", ^{
        it(@"can set a value to an object (KVC)", ^{
            TestKVOClass *obj = [TestKVOClass new];
            obj.property1 = @"aaa";
            
            EZRMutableNode *setter = obj.ezr_path[@"property1"];
            setter.value = @"bbb";
            
            expect(obj.property1).to(equal(@"bbb"));
        });
        
        it(@"can set an upstream EZRNode", ^{
            TestKVOClass *obj = [TestKVOClass new];
            obj.property1 = @"aaa";
            
            EZRNode *value = obj.ezr_path[@"property1"];
            EZRNode *upstreamValue = [EZRNode value:@"bbb"];
            [value linkTo:upstreamValue];
            expect(obj.property1).to(equal(@"bbb"));
        });
        
        it(@"can set keypath use ezr_path property", ^{
            TestKVOClass *obj = [TestKVOClass new];
            EZRMutableNode *node = [EZRMutableNode new];
            
            obj.ezr_path[@"property1"] = node;
            
            node.value = @"xxx";
            expect(obj.property1).to(equal(@"xxx"));
        });
    });

    context(@"EZR_PATH Macro", ^{
        it (@"equivalent to ezr_path", ^{
            TestKVOClass *obj = [TestKVOClass new];
            obj.property1 = @"aaa";

            EZRMutableNode *node1 = obj.ezr_path[@"property1"];
            EZRMutableNode *node2 = EZR_PATH(obj, property1);
            expect(node1).to(equal(node2));
        });
        
        it(@"can set a value to an object use EZR_PATH Macro", ^{
            TestKVOClass *obj = [TestKVOClass new];
            obj.property1 = @"aaa";
            
            EZRMutableNode *setter = EZR_PATH(obj, property1);
            expect(setter.value).to(equal(@"aaa"));

            setter.value = @"bbb";
            expect(obj.property1).to(equal(@"bbb"));
        });
        
        it(@"can get a value from an object use EZR_PATH Macro", ^{
            TestKVOClass *obj = [TestKVOClass new];
            EZRMutableNode *node = [EZRMutableNode new];
            
            EZR_PATH(obj, property1) = node;
            node.value = @"xxx";
            
            expect(obj.property1).to(equal(@"xxx"));
        });
    });

    context(@"sync", ^{
        it(@"can sync two values bidirectionally", ^{
            TestKVOClass *obj1 = [TestKVOClass new];
            TestKVOClass *obj2 = [TestKVOClass new];
            
            EZR_PATH(obj2, property3) = EZR_PATH(obj1, property1);
            
            obj1.property1 = @"xxx";
            expect(obj2.property3).to(equal(@"xxx"));
            
            obj2.property3 = @"yyy";
            expect(obj1.property1).to(equal(@"yyy"));
        });
        
        it(@"can sync value from another object use ezr_path", ^{
            TestKVOClass *obj1 = [TestKVOClass new];
            TestKVOClass *obj2 = [TestKVOClass new];
            
            obj1.property1 = @"xxx";
            obj2.property3 = @"yyy";
            
            EZR_PATH(obj2, property3) = EZR_PATH(obj1, property1);
            expect(obj1.property1).to(equal(@"xxx"));
            expect(obj2.property3).to(equal(@"xxx"));
        });
        
        it(@"can set deep path and get deep path", ^{
            TestKVOClass<TestKVOClass *, id, id> *obj1 = [TestKVOClass new];
            TestKVOClass<id, id, TestKVOClass *> *obj2 = [TestKVOClass new];
            
            obj1.property1 = [TestKVOClass new];
            obj2.property3 = [TestKVOClass new];
            
            EZR_PATH(obj2, property3.property3) = EZR_PATH(obj1, property1.property1);
            
            obj1.property1.property1 = @"15";
            expect(obj2.property3.property3).to(equal(@"15"));
            
            obj1.property1 = [TestKVOClass new];
            expect(obj2.property3.property3).to(beNil());
            
            obj1.property1.property1 = @1;
            expect(obj2.property3.property3).to(equal(@1));
        });
    });

    context(@"converting", ^{
        it(@"can convert a NSObject to a EZRNode", ^{
            UIView *obj = [[UIView alloc] initWithFrame:CGRectZero];
            EZRNode *node = [obj ezr_toNode];
            expect(node.value).to(equal(obj));
        });
        
        it(@"can convert a NSObject to a EZRMutableNode", ^{
            UIView *obj = [[UIView alloc] initWithFrame:CGRectZero];
            EZRMutableNode *node = [obj ezr_toMutableNode];
            expect(node.value).to(equal(obj));
        });
    });
    
    context(@"dealloc", ^{
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *tool) = ^(CheckReleaseTool *checkTool) {
                TestKVOClass *obj1 = [TestKVOClass new];
                TestKVOClass *obj2 = [TestKVOClass new];
                
                EZR_PATH(obj2, property3) = EZR_PATH(obj1, property1);
                
                [checkTool checkObj:obj1];
                [checkTool checkObj:obj2];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
        
        it(@"will be released if no one is listening", ^{
            expectCheckTool(^(CheckReleaseTool *checkTool) {
                TestKVOClass *obj = TestKVOClass.new;
                EZRNode *value = EZR_PATH(obj, property1);
                [checkTool checkObj:value];
            }).to(beReleasedCorrectly());
        });
        
        it(@"will be released after all the listeners stop listening", ^{
            NSObject *listener = [NSObject new];
            __weak EZRNode *value = nil;
            @autoreleasepool {
                TestKVOClass *obj = TestKVOClass.new;
                id<EZRCancelable> cancelable = nil;
                @autoreleasepool {
                    EZRNode *strongValue = EZR_PATH(obj, property1);
                    value = strongValue;
                    cancelable = [[value listenedBy:listener] withBlock:^(id  _Nullable next) {
                        
                    }];
                }
                expect(value).notTo(beNil());
                [cancelable cancel];
            }
            expect(value).to(beNil());
        });
    });
});

QuickSpecEnd
