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

#import <EasyReact/EZRTransformEdge.h>

NS_ASSUME_NONNULL_BEGIN

@class EZRNode, EZRSenderList;

/**
 代表节点到节点的一种变换。默认实现的为直接传递值到下游，后续可根据需求扩展子类
 */
@interface EZRTransform : NSObject <EZRTransformEdge>

/**
 上游值发生变化时流动到下游的方法
 子类自定义数据处理方式需要显示调用 super 的实现
 
 当你的子类实现中，不需要闭包捕获 super 的时候显示调用 super 即可，例如 EZRMapTransform。代码如下：
 
 <pre>@textblock
 
 - (void)next:(id)value from:(ERSenderList *)senderList {
        if (_block) {
        [super next:_block(value) from:senderList];
    }
 }
 
 @/textblock</pre>
 
 当你的子类实现中，需要闭包捕获 super 的时候，由于会隐式捕获 self 需要间接调用，例如 EZRFlattenTransform。代码如下：
 
 <pre>@textblock
 
 
 - (void)next:(id)value from:(ERSenderList *)senderList {
    EZRNode *node = _block(value);
    [self.cancelable cancel];
 
    @ezr_weakify(self)
    self.cancelable = [node listen:^(id  _Nullable next) {
        @ezr_strongify(self)
        [self _superNext:next from:senderList];
    }];
 }
 
 - (void)_superNext:(id)value from:(ERSenderList *)senderList {
    [super next:value from:senderList];
 }
 
 @/textblock</pre>
 
 @param value 最新值
 @param senderList 发送值的节点的链表， 用于判断是否出现回环
 @param context 上游节点传递的上下问变量
 */
- (void)next:(nullable id)value from:(EZRSenderList *)senderList context:(nullable id)context;

@end

NS_ASSUME_NONNULL_END
