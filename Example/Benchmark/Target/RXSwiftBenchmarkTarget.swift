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

import UIKit
import RxSwift

class RXSwiftBenchmarkTarget: NSObject, BenchmarkTargetProtocol {
    var name: String {
        return "RxSwift"
    }
    
    func listenerBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        for _ in 0...listenerCount {
            subject.subscribe(onNext: { (any) in
                subjectSum += 1
            }).dispose()
        }
        for i in 0...times {
            subject.onNext(Int(i))
        }
    }
    
    func mapBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        for _ in 0...listenerCount {
            subject.map { "\($0)" }.subscribe(onNext: { (any) in
                subjectSum += 1
            }).dispose()
        }
        for i in 0...times {
            subject.onNext(Int(i))
        }
    }
    
    func filterBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        for _ in 0...listenerCount {
            subject.filter { $0 % 2 == 0 }.subscribe(onNext: { (any) in
                subjectSum += 1
            }).dispose()
        }
        for i in 0...times {
            subject.onNext(Int(i))
        }
    }
    
    func sync(withBenchmarkChangeTimes times: UInt) {
        
    }
    
    func flattenMapBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        for _ in 0...listenerCount {
            subject.flatMap{ ReplaySubject<Int>.just($0) }.subscribe(onNext: { (any) in
                subjectSum += 1
            }).dispose()
        }
        for i in 0...times {
            subject.onNext(Int(i))
        }
    }
    
    func combineBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject1 = ReplaySubject<Int>.create(bufferSize: 1)
        let subject2 = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        Observable.combineLatest([subject1, subject2]).subscribe(onNext: { (iArr) in
            subjectSum += 1
        }).dispose()
        
        for i in 0...times {
            subject1.onNext(Int(i))
            subject1.onNext(Int(times - i))
        }
    }
    
    func zipBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject1 = ReplaySubject<Int>.create(bufferSize: 1)
        let subject2 = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        
        Observable.zip([subject1, subject2]).subscribe(onNext: { (iArr) in
            subjectSum += 1
        }).dispose()
        
        for i in 0...times {
            subject1.onNext(Int(i))
            subject1.onNext(Int(times - i))
        }
    }
    
    func mergeBenchmarkListenerCount(_ listenerCount: UInt, changeTimes times: UInt) {
        let subject1 = ReplaySubject<Int>.create(bufferSize: 1)
        let subject2 = ReplaySubject<Int>.create(bufferSize: 1)
        var subjectSum = 0
        
        Observable.merge([subject1, subject2]).subscribe(onNext: { (iArr) in
            subjectSum += 1
        }).dispose()
        
        for i in 0...times {
            subject1.onNext(Int(i))
            subject1.onNext(Int(times - i))
        }
    }
    
}

