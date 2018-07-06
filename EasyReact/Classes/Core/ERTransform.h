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


NS_ASSUME_NONNULL_BEGIN

@class ERNode, ERSenderList;

/**
 代表一种变换
 */
@interface ERTransform : NSObject

/**
 变换的名字，用于调试的数据可视化
 */
@property (nonatomic, readwrite, copy, nullable) NSString *name;

/**
 变换的上游节点，只能通过 `- (void)linkNode:(ERNode *)fromNode to:(ERNode *)toNode` 和 `- (void)breakLinking` 修改
 */
@property (atomic, readonly, unsafe_unretained, nullable) ERNode *from;

/**
 变换的下游节点，只能通过 `- (void)linkNode:(ERNode *)fromNode to:(ERNode *)toNode` 和 `- (void)breakLinking` 修改
 */
@property (atomic, readonly, unsafe_unretained, nullable) ERNode *to;

/**
 上游值发生变化时流动到下游的方法
 子类自定义数据处理方式需要显示调用 super 的实现
 
 当你的子类实现中，不需要闭包捕获 super 的时候显示调用 super 即可，例如 ERMapTransform。代码如下：
 
 ```ObjC
 - (void)next:(id)value from:(ERSenderList *)senderList {
        if (_block) {
        [super next:_block(value) from:senderList];
    }
 }
 ```
 
 当你的子类实现中，需要闭包捕获 super 的时候，由于会隐式捕获 self 需要间接调用，例如 ERFlattenTransform。代码如下：
 
 ```ObjC
 - (void)next:(id)value from:(ERSenderList *)senderList {
    ERNode *node = _block(value);
    [self.cancelable cancel];
 
    @er_weakify(self)
    self.cancelable = [node listen:^(id  _Nullable next) {
        @er_strongify(self)
        [self _superNext:next from:senderList];
    }];
 }
 
 - (void)_superNext:(id)value from:(ERSenderList *)senderList {
    [super next:value from:senderList];
 }
 ```
 @param value 最新值
 @param senderList 发送值的节点的链表， 用于判断是否出现回环
 */
- (void)next:(nullable id)value from:(ERSenderList *)senderList;

/**
 链接下游节点到上游节点

 @param fromNode 上游节点
 @param toNode 下游节点
 */
- (void)linkNode:(ERNode *)fromNode to:(ERNode *)toNode;

/**
 断开节点和变换
 */
- (void)breakLinking;

@end

NS_ASSUME_NONNULL_END
