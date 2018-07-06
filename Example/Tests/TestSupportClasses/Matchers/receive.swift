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

import Foundation
import Nimble
import Quick
import EasyReact

@objc public class TestListenTransform: EZRListen {
    
    @objc public private(set) var receiveValues:[NSObject] = []
    
    @objc public override func next(_ value: Any?, from senderList: EZRSenderList, context: Any?) {
        if let next = value as? NSObject {
            receiveValues.append(next)
        } else {
            receiveValues.append(NSNull())
        }
    }
    
}

var privatetestListenerKey: Void?
@objc public extension EZRNode {
    
    public var testListenTransform: TestListenTransform? {
        set {
            objc_setAssociatedObject(self, &privatetestListenerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &privatetestListenerKey) as? TestListenTransform
        }
    }

    public func startListenForTest(obj: AnyObject) {
        let transform = TestListenTransform()
        testListenTransform = transform
        listened(by: obj).withListenTransform(transform)
    }
    
}

public func receive(_ expectedValues: [NSObject] ) -> Predicate<EZRNode<NSObject>> {
    return Predicate.define("receive expectValues") {(actualExpress, msg) -> PredicateResult in
        let actual = try actualExpress.evaluate()
        guard let node = actual else {
            return PredicateResult(bool: false,
                                   message: msg.appended(message: "the actual value is not an EZRNode<NSObject>"))
        }
        
        guard let listener = node.testListenTransform else {
            return PredicateResult(bool: false,
                                   message: msg.appended(message: "the actual value not be listened please use start listen before check"))
        }

        guard listener.receiveValues == expectedValues else {
            return PredicateResult(bool: false,
                                   message: msg.appended(message: "expected:\(expectedValues) got: %@ \(listener.receiveValues)"))
        }
        
        return PredicateResult(bool: true, message: msg)
    }
}

@objc extension NMBObjCMatcher {
    
    public class func receiveMatcher(_ expectedValues: [NSObject]) -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { (actualExpression, failureMessage) -> Bool in
            let expr = actualExpression.cast { $0 as? EZRNode<NSObject> }
            return try! receive(expectedValues).matches(expr, failureMessage: failureMessage)
        }
    }
    
}


