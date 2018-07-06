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

#import "NSObject+EZR_Extension.h"
#import "EZRPathTrampoline.h"
#import "EZRMutableNode.h"
@import ObjectiveC.runtime;
@import ObjectiveC.message;

static void *EZR_PathTrampolineKey = &EZR_PathTrampolineKey;

@implementation NSObject (EZR_Extension)

- (EZRPathTrampoline *)ezr_path {
    EZRPathTrampoline *pathTrampoline = objc_getAssociatedObject(self, EZR_PathTrampolineKey);
    
    if (!pathTrampoline) {
        @synchronized(self) {
            pathTrampoline = objc_getAssociatedObject(self, EZR_PathTrampolineKey);
            if (!pathTrampoline) {
                pathTrampoline = [[EZRPathTrampoline alloc] initWithTarget:self];
                objc_setAssociatedObject(self, EZR_PathTrampolineKey, pathTrampoline, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return pathTrampoline;
}

- (EZRNode *)ezr_toNode {
    return [EZRNode value:self];
}

- (EZRMutableNode *)ezr_toMutableNode {
    return [EZRMutableNode value:self];
}

@end

