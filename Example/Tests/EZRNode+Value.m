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

QuickSpecBegin(EZRNodeValue)

describe(@"EZRNode", ^{
    context(@"- valueWithDefault: method,", ^{
        it(@"can fetch a default value if value is empty", ^{
            EZRNode<NSNumber *> *testNode = [EZRNode new];
            NSNumber *value = testNode.value;
            expect(value).to(equal([EZREmpty empty]));
            
            value = [testNode valueWithDefault:@1];
            expect(value).to(equal(@1));
            
            testNode.mutablify.value = @2;
            value = [testNode valueWithDefault:@1];
            expect(value).to(equal(@2));
        });
    });
    
    context(@"- getValue: method,", ^{
        it(@"can process value if node is not empty", ^{
            EZRNode<NSNumber *> *testNode = [EZRNode new];
            
            __block BOOL flag = NO;
            [testNode getValue:^(NSNumber * _Nullable value) {
                flag = YES;
            }];
            expect(flag).to(beFalse());
            
            flag = NO;
            testNode.mutablify.value = @2;
            [testNode getValue:^(NSNumber * _Nullable value) {
                flag = YES;
            }];
            expect(flag).to(beTrue());
        });
    });
});

QuickSpecEnd
