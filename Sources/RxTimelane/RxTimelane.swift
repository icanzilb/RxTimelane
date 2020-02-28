//
// Copyright(c) Marin Todorov 2020
// For the license agreement for this code check the LICENSE file.
//

import Foundation
import RxSwift
import TimelaneCore

public struct RxTimelane {
    public enum LaneType: Int, CaseIterable {
      case subscription, event
    }
}

fileprivate let lock = NSLock()

public extension ObservableType {
    func lane(_ name: String, filter: Set<RxTimelane.LaneType> = Set(RxTimelane.LaneType.allCases), file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> Observable<Element> {
      
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        let subscription = Timelane.Subscription(name: name)
        
        var terminated = false
        
        return self.do(onNext: { element in
            if filter.contains(.event) {
              subscription.event(value: .value(String(describing: element)), source: source)
            }
        },
        onError: { error in
            if filter.contains(.subscription) {
                subscription.end(state: .error(error.localizedDescription))
            }
            
            if filter.contains(.event) {
                subscription.event(value: .error(error.localizedDescription), source: source)
            }
        },
        onCompleted: {
            lock.lock()
            defer { lock.unlock() }
            guard !terminated else { return }
            terminated = true
            
            if filter.contains(.subscription) {
                subscription.end(state: .completed)
            }
            
            if filter.contains(.event) {
                subscription.event(value: .completion, source: source)
            }
        },
        onSubscribe: {
            if filter.contains(.subscription) {
              subscription.begin(source: source)
            }
        },
        onDispose: {
            lock.lock()
            defer { lock.unlock() }
            guard !terminated else { return }
            terminated = true
    
            if filter.contains(.subscription) {
                subscription.end(state: .cancelled)
            }
            
            if filter.contains(.event) {
                subscription.event(value: .cancelled, source: source)
            }
        })
    }
}
