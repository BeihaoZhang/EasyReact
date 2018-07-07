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

QuickSpecBegin(EZRTransformSpec)

describe(@"EZRTransformSpec", ^{
    it(@"can set an upstream", ^{
        EZRTransform *transfrom = [EZRTransform new];
        EZRNode *node = [EZRNode new];
        transfrom.from = node;
        expect(transfrom.from).to(equal(node));
        expect(node.downstreamTransforms).to(equal(@[transfrom]));
        expect(node.downstreamNodes.count).to(equal(0));
        expect(node.hasDownstreamNode).to(beFalse());
    });
    
    it(@"can set a downstream", ^{
        EZRTransform *transfrom = [EZRTransform new];
        EZRNode *node = [EZRNode new];
        transfrom.to = node;
        expect(transfrom.to).to(equal(node));
        expect(node.upstreamTransforms).to(equal(@[transfrom]));
        expect(node.upstreamNodes.count).to(equal(0));
        expect(node.hasUpstreamNode).to(beFalse());
    });
    
    it(@"can link two nodes", ^{
        EZRTransform *transfrom = [EZRTransform new];
        EZRNode *from = [EZRNode new];
        EZRNode *to = [EZRNode new];
        transfrom.from = from;
        transfrom.to = to;
        expect(transfrom.from).to(equal(from));
        expect(transfrom.to).to(equal(to));
        expect(from.downstreamTransforms).to(equal(@[transfrom]));
        expect(to.upstreamTransforms).to(equal(@[transfrom]));
        expect(from.downstreamNodes).to(equal(@[to]));
        expect(to.upstreamNodes).to(equal(@[from]));
    });
});
describe(@"EZRNode", ^{
    context(@"with transfrom links to upstream node", ^{
        it(@"can get vaLue from upstream", ^{
            EZRMutableNode *from = [EZRMutableNode value:@1];
            EZRTransform *transfrom = [EZRTransform new];
            EZRNode *to = [EZRNode new];
            expect(to.value).to(equal([EZREmpty empty]));
            transfrom.from = from;
            transfrom.to = to;
            expect(to.value).to(equal(@1));
            
            from.value = @2;
            expect(to.value).to(equal(@2));
        });
        
        it(@"should not receive new values when link breaks", ^{
            EZRMutableNode *from = [EZRMutableNode value:@1];
            EZRTransform *transfrom = [EZRTransform new];
            EZRNode *to = [EZRNode new];
            transfrom.from = from;
            transfrom.to = to;
            expect(to.value).to(equal(@1));
            from.value = @2;
            expect(to.value).to(equal(@2));
            
            transfrom.to = nil;
            from.value = @3;
            expect(to.value).notTo(equal(@3));
        });
    });
});

describe(@"Transform", ^{
    it(@"should retain the from node", ^{
        EZRTransform *transform = [EZRTransform new];
        __weak EZRNode *node;
        @autoreleasepool {
            EZRNode *strongNode = [EZRNode new];
            node = strongNode;
            transform.from = node;
            expect(node).notTo(beNil());
        }
        expect(node).notTo(beNil());
    });
    
    it(@"should not retain the to node", ^{
        EZRTransform *transform = [EZRTransform new];
        __weak EZRNode *node;
        @autoreleasepool {
            EZRNode *strongNode = [EZRNode new];
            node = strongNode;
            transform.to = node;
            expect(node).notTo(beNil());
        }
        expect(node).to(beNil());
    });
});

QuickSpecEnd
