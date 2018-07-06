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

@import Foundation;
@import Quick;
@import Nimble;
@import EasyReact;

id<NMBMatcher> beEmptyValue(void);
id<NMBMatcher> receive(NSArray *arr);
id<NMBMatcher> beReleasedCorrectly(void);
id<NMBMatcher> hasParameterAssert(void);
id<NMBMatcher> hasAssert(void);
id<NMBMatcher> matchDotDSL(NSArray<EZRNode *> *nodes, NSArray<id<EZRTransformEdge>> *transforms);


#define  expectCheckTool(check)                                                                                         \
                CheckReleaseToolBlockContainer *container = [CheckReleaseToolBlockContainer new];                       \
                container.checkReleaseTool = check;                                                                     \
                expect(container)                                                                                       \

#define  assertExpect(block)                                                                                            \
                AssertBlockContainer *container = [AssertBlockContainer new];                                           \
                container.action = block;                                                                               \
                expect(container)                                                                                       \


