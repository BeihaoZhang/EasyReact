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

QuickSpecBegin(ERNodeGraph)

describe(@"ERNode Graph test", ^{
    context(@"dot language", ^{
        it(@"should match node array and transform array use no cycle link", ^{
            ERNode *up1 = [[ERNode value:@"up1"] named:@"up1"];
            ERNode *up2 = [[ERNode value:@"up2"] named:@"up2"];
            ERNode *up1AnotherDown = [[ERNode value:@"up1AnotherDown"] named:@"up1AnotherDown"];;
            ERNode *node = [ERNode.new named:@"currentNode"];
            ERNode *down1 = [[ERNode value:@"down1"] named:@"down1"];
            ERNode *down2 = [[ERNode value:@"down2"] named:@"down2"];
            
            ERTransform *uptransform1 = [ERTransform new];
            ERTransform *uptransform2 = [ERTransform new];
            ERTransform *downtransform1 = [ERTransform new];
            ERTransform *downtransform2 = [ERTransform new];
            ERTransform *up1AnotherDownTransform = [ERTransform new];
            [node linkTo:up1 transform:uptransform1];
            [node linkTo:up2 transform:uptransform2];
            [down1 linkTo:node transform:downtransform1];
            [down2 linkTo:node transform:downtransform2];
            [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
            NSArray<ERNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
            NSArray<ERTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform];
            
            expect(node.graph).to(matchDotDSL(nodes, transforms));

        });
        
        it(@"should match node array and transform array use cycle link", ^{
            ERNode *up1 = [[ERNode value:@"up1"] named:@"up1"];
            ERNode *up2 = [[ERNode value:@"up2"] named:@"up2"];
            ERNode *node = [ERNode.new named:@"currentNode"];
            ERNode *down1 = [[ERNode value:@"down1"] named:@"down1"];
            ERNode *down2 = [[ERNode value:@"down2"] named:@"down2"];
            
            ERTransform *uptransform1 = [ERTransform new];
            ERTransform *uptransform2 = [ERTransform new];
            ERTransform *downtransform1 = [ERTransform new];
            ERTransform *downtransform2 = [ERTransform new];
            [node linkTo:up1 transform:uptransform1];
            [node linkTo:up2 transform:uptransform2];
            [down1 linkTo:node transform:downtransform1];
            [down2 linkTo:node transform:downtransform2];
            ERTransform *cycletransform = [ERTransform new];
            [up1 linkTo:down1 transform:cycletransform];
            NSArray<ERNode *> *nodes = @[up1, up2, node, down1, down2];
            NSArray<ERTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, cycletransform];
           
            expect(node.graph).to(matchDotDSL(nodes, transforms));
        });
    });
});

QuickSpecEnd
