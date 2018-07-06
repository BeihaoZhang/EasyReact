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

#import <ZTuple/ZTuple.h>
#import "ERMetaMacros.h"
#import "ERNode+MapEach.h"
#import "ERTypeDefine.h"
#import "ERNode+Operation.h"

@implementation ERNode (MapEach)

- (ERNode *)mapEach:(id (^)())block  {
    return [self map:^id _Nullable(ZTupleBase *tuple) {
        if (![tuple isKindOfClass:[ZTupleBase class]]) {
            ER_THROW(ERNodeExceptionName, ERExceptionReason_MapEachNextValueNotTuple, nil)
        }
        if (!block) {
            return nil;
        }
        switch (tuple.count) {
            case 0: return block();
            case 1: return block(tuple[0]);
            case 2: return block(tuple[0], tuple[1]);
            case 3: return block(tuple[0], tuple[1], tuple[2]);
            case 4: return block(tuple[0], tuple[1], tuple[2], tuple[3]);
            case 5: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4]);
            case 6: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5]);
            case 7: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6]);
            case 8: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7]);
            case 9: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8]);
            case 10: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8], tuple[9]);
            case 11: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8], tuple[9], tuple[10]);
            case 12: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8], tuple[9], tuple[10], tuple[11]);
            case 13: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8], tuple[9], tuple[10], tuple[11], tuple[12]);
            case 14: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8], tuple[9], tuple[10], tuple[11], tuple[12], tuple[13]);
            case 15: return block(tuple[0], tuple[1], tuple[2], tuple[3], tuple[4], tuple[5], tuple[6], tuple[7], tuple[8], tuple[9], tuple[10], tuple[11], tuple[12], tuple[13], tuple[14]);
                
            default:
                return nil;
        }
    }];
}

@end
