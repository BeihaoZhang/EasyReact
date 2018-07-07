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
 Returns a string to describe the topology associated with the receiver. The string is dot language code used for generating a static image via *graphiz* tool while debugging. See also [The dot language](https://www.graphviz.org/doc/info/lang.html) .
 
 Usage
 1. Install 'graphviz' command line tool in Mac OS system
 
 <pre>@textblock
 
 brew install graphviz
 
 @/textblock</pre>

 2. Put the string returned from this method into a text file, such as test.dot
 
 3. Generate image
 
 <pre>@textblock
 
 circo -Tpdf test.dot -o test.pdf && open test.pdf
 
 @/textblock</pre>

 @return    dot language string corresponding to GraphViz
 */
- (NSString *)graph;

@end
