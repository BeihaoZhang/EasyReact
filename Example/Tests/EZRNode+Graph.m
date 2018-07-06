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

describe(@"EZRNode Graph test", ^{
    context(@"dot language", ^{
        it(@"should match node array and transform array use no cycle link", ^{
            EZRNode *up1 = [[EZRNode value:@"up1"] named:@"up1"];
            EZRNode *up2 = [[EZRNode value:@"up2"] named:@"up2"];
            EZRNode *up1AnotherDown = [[EZRNode value:@"up1AnotherDown"] named:@"up1AnotherDown"];;
            EZRNode *node = [EZRNode.new named:@"currentNode"];
            EZRNode *down1 = [[EZRNode value:@"down1"] named:@"down1"];
            EZRNode *down2 = [[EZRNode value:@"down2"] named:@"down2"];
            
            EZRNodeTransform *uptransform1 = [EZRNodeTransform new];
            EZRNodeTransform *uptransform2 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform1 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform2 = [EZRNodeTransform new];
            EZRNodeTransform *up1AnotherDownTransform = [EZRNodeTransform new];
            [node linkTo:up1 transform:uptransform1];
            [node linkTo:up2 transform:uptransform2];
            [down1 linkTo:node transform:downtransform1];
            [down2 linkTo:node transform:downtransform2];
            [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
            NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
            NSArray<EZRNodeTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform];
            
            expect(node.graph).to(matchDotDSL(nodes, transforms));
        });
        
        it(@"should match node array and transform array use cycle link", ^{
            EZRNode *up1 = [[EZRNode value:@"up1"] named:@"up1"];
            EZRNode *up2 = [[EZRNode value:@"up2"] named:@"up2"];
            EZRNode *node = [EZRNode.new named:@"currentNode"];
            EZRNode *down1 = [[EZRNode value:@"down1"] named:@"down1"];
            EZRNode *down2 = [[EZRNode value:@"down2"] named:@"down2"];
            
            EZRNodeTransform *uptransform1 = [EZRNodeTransform new];
            EZRNodeTransform *uptransform2 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform1 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform2 = [EZRNodeTransform new];
            [node linkTo:up1 transform:uptransform1];
            [node linkTo:up2 transform:uptransform2];
            [down1 linkTo:node transform:downtransform1];
            [down2 linkTo:node transform:downtransform2];
            EZRNodeTransform *cycletransform = [EZRNodeTransform new];
            [up1 linkTo:down1 transform:cycletransform];
            NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2];
            NSArray<EZRNodeTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, cycletransform];
           
            expect(node.graph).to(matchDotDSL(nodes, transforms));
        });
        
        it(@"should match node array and transform array use incomplete link which has no downstream node", ^{
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
            
            EZRNodeTransform *uptransform1 = [EZRNodeTransform new];
            EZRNodeTransform *uptransform2 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform1 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform2 = [EZRNodeTransform new];
            EZRNodeTransform *up1AnotherDownTransform = [EZRNodeTransform new];
            EZRNodeTransform *tailTransform = [EZRNodeTransform new];

            [node linkTo:up1 transform:uptransform1];
            [node linkTo:up2 transform:uptransform2];
            [down1 linkTo:node transform:downtransform1];
            [down2 linkTo:node transform:downtransform2];
            [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
            tailTransform.from = down2;
            
            NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
            NSArray<EZRNodeTransform *> *transforms = @[uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform, tailTransform];
            
            expect(node.graph).to(matchDotDSL(nodes, transforms));
        });

        it(@"should match node array and transform array use incomplete link which has no upstream node", ^{
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
            
            EZRNodeTransform *uptransform1 = [EZRNodeTransform new];
            EZRNodeTransform *uptransform2 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform1 = [EZRNodeTransform new];
            EZRNodeTransform *downtransform2 = [EZRNodeTransform new];
            EZRNodeTransform *up1AnotherDownTransform = [EZRNodeTransform new];
            EZRNodeTransform *headTransform = [EZRNodeTransform new];
            
            headTransform.to = up1;
            [node linkTo:up1 transform:uptransform1];
            [node linkTo:up2 transform:uptransform2];
            [down1 linkTo:node transform:downtransform1];
            [down2 linkTo:node transform:downtransform2];
            [up1AnotherDown linkTo:up1 transform:up1AnotherDownTransform];
            NSArray<EZRNode *> *nodes = @[up1, up2, node, down1, down2, up1AnotherDown];
            NSArray<EZRNodeTransform *> *transforms = @[headTransform, uptransform1, uptransform2, downtransform1, downtransform2, up1AnotherDownTransform];
            
            expect(node.graph).to(matchDotDSL(nodes, transforms));
        });
    });
});

QuickSpecEnd
