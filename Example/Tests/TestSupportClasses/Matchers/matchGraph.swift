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
import EasyReact
import Nimble

private func dotlanguageFrom(node: EZRNode<AnyObject>) -> String {
    return NSString(format: "  er_%p[label=\"%@\"]", node, node.name ?? "") as String
}

private func dotlanguageFrom(transform: EZRTransformEdge) -> String {
    let fromAddress = transform.from != nil ? String(format: "%p", transform.from ?? "") : "0x0"
    let toAddress = transform.to != nil ? String(format: "%p", transform.to ?? "") : "0x0"
    return "  er_\(fromAddress) -> er_\(toAddress)[label=\"\(transform.name ?? "")\"]"
}

private func extractNodeAndEdgeDSLFromDigraph(graph: String) -> Set<String> {
    let result = graph.replacingOccurrences(of: "digraph G {\n  node [peripheries=2 style=filled color=\"#eecc80\"]\n  edge [color=\"sienna\" fontcolor=\"black\"] \n",
                                            with: "").replacingOccurrences(of: "\n}", with: "")
    
    return Set(result.components(separatedBy: "\n"))
}

public func canLink(to nodes: [EZRNode<AnyObject>], use transform: [EZRTransformEdge]) -> Predicate<String> {
    return Predicate.define("canLink nodes") {(actualExpress, msg) -> PredicateResult in
        let actual = try actualExpress.evaluate()
        guard let graph = actual else {
            return PredicateResult(bool: false,
                                   message: msg.appended(message: "the actual value is not an EZRNode<NSObject>"))
        }
        
        let nodeGraphs = nodes.map(dotlanguageFrom)
        let transformGraph = transform.map(dotlanguageFrom)
        let dotSet = Set<String>(nodeGraphs + transformGraph)
        let actualDotSet = extractNodeAndEdgeDSLFromDigraph(graph: graph)
        return PredicateResult(bool: actualDotSet == dotSet, message: msg)
    }
}

@objc public extension NMBObjCMatcher {
    
    public class func matchDotDSL(_ nodes: [EZRNode<AnyObject>], transforms: [EZRTransformEdge]) -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { (actualExpression, failureMessage) -> Bool in
            let expr = actualExpression.cast { $0 as? String }
            return try! canLink(to: nodes, use: transforms).matches(expr, failureMessage: failureMessage)
        }
    }
    
}
