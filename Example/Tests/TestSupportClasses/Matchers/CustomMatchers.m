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

#import "EasyReact_Tests-Swift.h"

id<NMBMatcher> beEmptyValue() {
    return [NMBObjCMatcher beEmptyValueMatcher];
}

id<NMBMatcher> receive(NSArray *arr) {
    return [NMBObjCMatcher receiveMatcher:arr];
}

id<NMBMatcher> beReleasedCorrectly() {
    return [NMBObjCMatcher beReleasedCorrectlyMatcher];
}

id<NMBMatcher> hasParameterAssert() {
    return [NMBObjCMatcher hasParameterAssertMatcher];
}

id<NMBMatcher> hasAssert() {
    return [NMBObjCMatcher hasAssertMatcher];
}

id<NMBMatcher> matchDotDSL(NSArray<ERNode *> *nodes, NSArray<ERTransform *> *transforms) {
    return [NMBObjCMatcher matchDotDSL:nodes transforms:transforms];
}
