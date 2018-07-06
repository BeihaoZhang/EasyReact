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

import Nimble
import EasyReact

public func beEmptyValueTo() -> Predicate<EZRNode<NSObject>> {
    return Predicate.define("is Empty Value") { (actualExpress, msg) -> PredicateResult in
        let actual = try actualExpress.evaluate()
        guard let node = actual else {
            return PredicateResult(bool: false,
                                   message: msg.appended(message: "the actual value is not an EZRNode<NSObject>"))
        }
        guard node.isEmpty else {
            return PredicateResult(bool: false,
                                   message: msg.appended(message: "expected: got  empty but actual Value is \(node.value?.description ?? "")"))
        }
        return PredicateResult(bool: true, message: msg)
    }
}

@objc public extension NMBObjCMatcher {
    public class func beEmptyValueMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { (actualExpression, failureMessage) -> Bool in
            let expr = actualExpression.cast { $0 as? EZRNode<NSObject> }
            return try! beEmptyValueTo().matches(expr , failureMessage: failureMessage)
        }
    }
}



