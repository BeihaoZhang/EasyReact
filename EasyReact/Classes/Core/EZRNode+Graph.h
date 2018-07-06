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

#import <EasyReact/EZRNode.h>

@interface EZRNode (Graph)

/**
 这个方法可以计算出描绘当前节点的连接状态的图的DSL字符串。
 此字符串可以通过 graphviz 工具生成一张静态的图片，可用于追溯节点的拓扑图。
 使用方法
 1. Mac OS 下 需要安装 graphviz 命令行工具
 
 <pre>@textblock
 
 brew install graphviz
 
 @/textblock</pre>

 2. 调用 当前方法会放回一个字符串，将字符串存在于文本文件中，如 test.dot
 
 3. 生成图片
 
 <pre>@textblock
 
 circo -Tpdf test.dot -o test.pdf && open test.pdf
 
 @/textblock</pre>

 @return 适配GraphViz的DSL
 */
- (NSString *)graph;

@end
