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

#import "ERUsefulBlocks.h"

ERCheckBlock er_isKindOf(Class class) {
    return ^BOOL(id value) {
        return [value isKindOfClass:class];
    };
}

ERCheckBlock er_isEqual(id target) {
    return ^BOOL(id value) {
        return [value isEqual:target];
    };
}

ERCheckBlock er_not(ERCheckBlock block) {
    return ^BOOL(id value) {
        return !block(value);
    };
}
