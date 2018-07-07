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

@protocol EZRNextReceiver

@required
/**
 Transfers value object to downstream node by a given sender list and a context. The sender list contains all the nodes that had been transferred the value object. The given context is used for taking an external object.
 
 @param value       Latest value
 @param senderList  List of node value senders, used for retrospecting the sources of values
 @param context     Context passed by user
 */
- (void)next:(nullable id)value from:(nonnull EZRSenderList *)senderList context:(nullable id)context;

@end
