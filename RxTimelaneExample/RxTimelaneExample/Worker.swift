//
//  Worker.swift
//  TimelaneTestApp
//
//  Created by Marin Todorov on 1/25/20.
//  Copyright © 2020 Underplot ltd. All rights reserved.
//

import Foundation
import Combine
import RxSwift

extension Observable {
    
    static func worker(duration: TimeInterval, error: Error? = nil) -> Observable<String> {
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
