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

@objc public class CheckReleaseTool: NSObject {
    
    @objc var checkTable = NSHashTable<NSObject>.weakObjects()
    
    @objc public func checkObj(_ obj: NSObject?) {
        checkTable.add(obj)
    }
    
}

@objc public class CheckReleaseToolBlockContainer: NSObject {
    @objc public var checkReleaseTool: ((CheckReleaseTool) -> Void)?
}


public func beReleasedCorrectly() -> Predicate<CheckReleaseToolBlockContainer> {
    return Predicate.define("") { actualExpress, msg in
        
        let actual = try actualExpress.evaluate()
        let checkTool = CheckReleaseTool()
        
        guard let container = actual, let closure = container.checkReleaseTool else {
            return PredicateResult(bool:false, message:msg.appended(message: "the expected block is not given"))
        }
        
        autoreleasepool {
            autoreleasepool {
                closure(checkTool)
            }
        }
        return PredicateResult(bool: checkTool.checkTable.allObjects.count == 0 ,
                               message: .fail("expected: all check object to be released, got: \(checkTool.checkTable.allObjects) still exists"))
    }
}

@objc extension NMBObjCMatcher {
    public class func beReleasedCorrectlyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { (actualExpression, failureMessage) -> Bool in
            let expr = actualExpression.cast {
                $0 as? CheckReleaseToolBlockContainer
            }
            return try! beReleasedCorrectly().matches(expr , failureMessage: failureMessage)
        }
    }
}


