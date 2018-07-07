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

QuickSpecBegin(EZRNodeGraph)

describe(@"EZRNode graph dot language", ^{
    it(@"should match node array and transform array when there is no cycle in nodes's edges", ^{
        EZRNode *up1 = [[EZRNode value:@"up1"] named:@"up1"];
        EZRNode *up2 = [[EZRNode value:@"up2"] named:@"up2"];
        EZRNode *up1AnotherDown = [[EZRNode value:@"up1AnotherDown"] named:@"up1AnotherDown"];;
        EZRNode *node = [EZRNode.new named:@"currentNode"];
        EZRNode *down1 = [[EZRNode value:@"down1"] named:@"down1"];
        EZRNode *down2 = [[EZRNode value:@"down2"] named:@"down2"];
        
        EZRTransform *uptransform1 = [EZRTransform new];
        EZRTransform *uptransform2 = [EZRTransform new];
        EZRTransform *downtransform1 = [EZRTransform new];
        EZRTransform *downtransform2 = [EZRTransform new];
        EZRTransform *up1AnotherDownTransform = [EZRTransform new];
        [node linkTo:up1 transform:uptransform1];
        [node linkTo:up2 transform:uptransform2];
        [down1 linkTo:node transform:downtransform1];
        [down2 linkTo:node transform:downtransform2];
        [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
        NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
        NSArray<EZRTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform];
        
        expect(node.graph).to(matchDotDSL(nodes, transforms));
    });
    
    it(@"should match node array and transform array when there is a cycle in nodes's edges", ^{
        EZRNode *up1 = [[EZRNode value:@"up1"] named:@"up1"];
        EZRNode *up2 = [[EZRNode value:@"up2"] named:@"up2"];
        EZRNode *node = [EZRNode.new named:@"currentNode"];
        EZRNode *down1 = [[EZRNode value:@"down1"] named:@"down1"];
        EZRNode *down2 = [[EZRNode value:@"down2"] named:@"down2"];
        
        EZRTransform *uptransform1 = [EZRTransform new];
        EZRTransform *uptransform2 = [EZRTransform new];
        EZRTransform *downtransform1 = [EZRTransform new];
        EZRTransform *downtransform2 = [EZRTransform new];
        [node linkTo:up1 transform:uptransform1];
        [node linkTo:up2 transform:uptransform2];
        [down1 linkTo:node transform:downtransform1];
        [down2 linkTo:node transform:downtransform2];
        EZRTransform *cycletransform = [EZRTransform new];
        [up1 linkTo:down1 transform:cycletransform];
        NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2];
        NSArray<EZRTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, cycletransform];
        
        expect(node.graph).to(matchDotDSL(nodes, transforms));
    });
    
    it(@"should match node array and transform array when there are incomplete edges with no downstream node", ^{
        /*
         up1AnotherDown
         ^                 down1
         /                   ^
         up1 \                 /
         > current node
         up2 /                 |>  down2 ---(tailtransform)--->
         */
        
        EZRNode *up1 = [[EZRNode value:@"up1"] named:@"up1"];
        EZRNode *up2 = [[EZRNode value:@"up2"] named:@"up2"];
        EZRNode *up1AnotherDown = [[EZRNode value:@"up1AnotherDown"] named:@"up1AnotherDown"];;
        EZRNode *node = [EZRNode.new named:@"currentNode"];
        EZRNode *down1 = [[EZRNode value:@"down1"] named:@"down1"];
        EZRNode *down2 = [[EZRNode value:@"down2"] named:@"down2"];
        
        EZRTransform *uptransform1 = [EZRTransform new];
        EZRTransform *uptransform2 = [EZRTransform new];
        EZRTransform *downtransform1 = [EZRTransform new];
        EZRTransform *downtransform2 = [EZRTransform new];
        EZRTransform *up1AnotherDownTransform = [EZRTransform new];
        EZRTransform *tailTransform = [EZRTransform new];
        
        [node linkTo:up1 transform:uptransform1];
        [node linkTo:up2 transform:uptransform2];
        [down1 linkTo:node transform:downtransform1];
        [down2 linkTo:node transform:downtransform2];
        [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
        tailTransform.from = down2;
        
        NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
        NSArray<EZRTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform, tailTransform];
        
        expect(node.graph).to(matchDotDSL(nodes, transforms));
    });
    
    it(@"should match node array and transform array when there are incomplete edges with no upstream node", ^{
        /*
         up1AnotherDown
         ^                 down1
         /                   ^
         ------> up1  \                 /
         > current node
         up2 /                |> down2
         
         
         */
        EZRNode *up1 = [[EZRNode value:@"up1"] named:@"up1"];
        EZRNode *up2 = [[EZRNode value:@"up2"] named:@"up2"];
        EZRNode *up1AnotherDown = [[EZRNode value:@"up1AnotherDown"] named:@"up1AnotherDown"];;
        EZRNode *node = [EZRNode.new named:@"currentNode"];
        EZRNode *down1 = [[EZRNode value:@"down1"] named:@"down1"];
        EZRNode *down2 = [[EZRNode value:@"down2"] named:@"down2"];
        
        EZRTransform *uptransform1 = [EZRTransform new];
        EZRTransform *uptransform2 = [EZRTransform new];
        EZRTransform *downtransform1 = [EZRTransform new];
        EZRTransform *downtransform2 = [EZRTransform new];
        EZRTransform *up1AnotherDownTransform = [EZRTransform new];
        EZRTransform *headTransform = [EZRTransform new];
        
        headTransform.to = up1;
        [node linkTo:up1 transform:uptransform1];
        [node linkTo:up2 transform:uptransform2];
        [down1 linkTo:node transform:downtransform1];
        [down2 linkTo:node transform:downtransform2];
        [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
        NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
        NSArray<EZRTransform *> *transforms = @[headTransform, uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform];
        
        expect(node.graph).to(matchDotDSL(nodes, transforms));
    });
});

QuickSpecEnd
