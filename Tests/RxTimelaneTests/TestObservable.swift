//
//  TestObservable.swift
//
//  Created by Marin Todorov on 5/25/20.
//

import Foundation
import RxSwift

extension Observable {
    
    static func testObservable(duration: TimeInterval, error: Error? = nil) -> Observable<String> {
        return Observable<String>.create { observer in
            observer.onNext("Hello")
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
