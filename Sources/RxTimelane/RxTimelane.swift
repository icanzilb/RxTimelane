//
// Copyright(c) Marin Todorov 2020
// For the license agreement for this code check the LICENSE file.
//

import Foundation
import RxSwift
import TimelaneCore

fileprivate let lock = NSLock()

/// The `lane` operator logs the subscription and its events to the Timelane Instrument.
///
///  - Note: You can download the Timelane Instrument from http://timelane.tools
/// - Parameters:
///   - name: A name for the lane when visualized in Instruments
///   - filter: Which events to log subscriptions or data events.
///             For example for a subscription on a subject you might be interested only in data events.
///   - transformValue: An optional closure to format the subscription values for displaying in Instruments.
///                     You can not only prettify the values but also change them completely, e.g. for arrays you can
///                     it might be more useful to report the count of elements if there are a lot of them.
///   - value: The value emitted by the subscription
public extension ObservableType {
    
    @available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
    func lane(_ name: String,
              filter: Timelane.LaneTypeOptions = .all,
              file: StaticString = #file,
              function: StaticString = #function, line: UInt = #line,
              transformValue transform: @escaping (_ value: Element) -> String = { String(describing: $0) },
              logger: @escaping Timelane.Logger = Timelane.defaultLogger) -> Observable<Element> {
        
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        
        return Observable<Element>.create { observer in
            let subscription = Timelane.Subscription(name: name, logger: logger)
            var terminated = false
            
            let disposable = self.do(onNext: { element in
                if filter.contains(.event) {
                    subscription.event(value: .value(transform(element)), source: source)
                }
            },
            onError: { error in
                lock.lock()
                defer { lock.unlock() }
                
                terminated = true
                
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
            .subscribe(observer.on)
            
            return Disposables.create([disposable])
        }
    }
}

public extension PrimitiveSequence where Trait == SingleTrait {
    
    @available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
    func lane(_ name: String,
              filter: Timelane.LaneTypeOptions = .all,
              file: StaticString = #file,
              function: StaticString = #function, line: UInt = #line,
              transformValue transform: @escaping (_ value: Element) -> String = { String(describing: $0) },
              logger: @escaping Timelane.Logger = Timelane.defaultLogger) -> Single<Element> {
        
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        
        return Single.create { subscribe -> Disposable in
            let subscription = Timelane.Subscription(name: name, logger: logger)
            var terminated = false

            let disposable = self.do(onSuccess: { element in
                lock.lock()
                defer { lock.unlock() }
                guard !terminated else { return }
                terminated = true
                
                if filter.contains(.event) {
                    subscription.event(value: .value(transform(element)), source: source)
                }
                
                if filter.contains(.subscription) {
                    subscription.end(state: .completed)
                }
                
                if filter.contains(.event) {
                    subscription.event(value: .completion, source: source)
                }
            }, onError: { error in
                lock.lock()
                defer { lock.unlock() }
                
                terminated = true
                
                if filter.contains(.subscription) {
                    subscription.end(state: .error(error.localizedDescription))
                }
                
                if filter.contains(.event) {
                    subscription.event(value: .error(error.localizedDescription), source: source)
                }
            }, onSubscribe: {
                if filter.contains(.subscription) {
                    subscription.begin(source: source)
                }
            }) {
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
            }
            .subscribe(subscribe)
            
            return Disposables.create([disposable])
        }
    }
}

public extension PrimitiveSequence where Trait == CompletableTrait, Element == Never {
    
    @available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
    func lane(_ name: String,
              filter: Timelane.LaneTypeOptions = .all,
              file: StaticString = #file,
              function: StaticString = #function, line: UInt = #line,
              transformValue transform: @escaping (_ value: Element) -> String = { String(describing: $0) },
              logger: @escaping Timelane.Logger = Timelane.defaultLogger) -> Completable {
        
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        
        return Completable.create { subscribe -> Disposable in
            let subscription = Timelane.Subscription(name: name, logger: logger)
            var terminated = false
            
            let disposable = self.do(onError: { error in
                lock.lock()
                defer { lock.unlock() }
                
                terminated = true
                
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
            .subscribe(subscribe)
            
            return Disposables.create([disposable])
        }
    }
}

public extension PrimitiveSequence where Trait == MaybeTrait {
    
    @available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
    func lane(_ name: String,
              filter: Timelane.LaneTypeOptions = .all,
              file: StaticString = #file,
              function: StaticString = #function, line: UInt = #line,
              transformValue transform: @escaping (_ value: Element) -> String = { String(describing: $0) },
              logger: @escaping Timelane.Logger = Timelane.defaultLogger) -> Maybe<Element> {
      
        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"
        
        return Maybe.create { subscribe -> Disposable in
            let subscription = Timelane.Subscription(name: name, logger: logger)
            var terminated = false
            
            let disposable = self.do(onNext: { element in
                if filter.contains(.event) {
                    subscription.event(value: .value(transform(element)), source: source)
                }
            },
            onError: { error in
                lock.lock()
                defer { lock.unlock() }
                
                terminated = true
                
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
            .subscribe(subscribe)

            return Disposables.create([disposable])
        }
    }
}
