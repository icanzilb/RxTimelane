//
//  ViewController.swift
//  RxTimelaneTestApp
//
//  Created by Marin Todorov on 1/25/20.
//

import UIKit
import TimelaneCore
import RxSwift
import RxTimelane

class ViewController: UITableViewController {
    enum MyError: Error {
        case test
    }
    
    private var bag = DisposeBag()
    
    @IBOutlet var failingSpinner: UIActivityIndicatorView!
    @IBAction func doFailingSubscription(_ sender: Any) {
        failingSpinner.isHidden = false
        
        Observable<String>.worker(duration: 3.0, error: MyError.test)
            .lane("Will Fail", filter: [.subscription], logger: Timelane.defaultLogger)
            .subscribe(onNext: { value in
                NSLog("output: \(value)")
            }, onError: { [weak self] error in
                NSLog("\(error)")
                self?.failingSpinner.isHidden = true
                }, onCompleted: { [weak self] in
                    NSLog("completed")
                    self?.failingSpinner.isHidden = true
            })
            .disposed(by: bag)
    }
    
    @IBOutlet var completingSpinner: UIActivityIndicatorView!
    @IBAction func doCompletingSubscription(_ sender: Any) {
        completingSpinner.isHidden = false
        
        Observable<String>.worker(duration: 2.0)
            .lane("Will Complete", filter: [.subscription], logger: Timelane.defaultLogger)
            .subscribe(onNext: { value in
                NSLog("output: \(value)")
            }, onError: { [weak self] error in
                NSLog("\(error)")
                self?.completingSpinner.isHidden = true
                }, onCompleted: { [weak self] in
                    NSLog("completed")
                    self?.completingSpinner.isHidden = true
            })
            .disposed(by: bag)
    }
    
    @IBOutlet var cancellingSpinner: UIActivityIndicatorView!
    @IBAction func doCancellingSubscription(_ sender: Any) {
        cancellingSpinner.isHidden = false
        
        var willCancel: Disposable? = Observable<String>.worker(duration: 5.0)
            .lane("Will Cancel", filter: [.subscription], logger: Timelane.defaultLogger)
            .subscribe(onNext: { value in
                NSLog("output: \(value)")
            }, onError: { [weak self] error in
                NSLog("\(error)")
                self?.cancellingSpinner.isHidden = true
                }, onCompleted: { [weak self] in
                    NSLog("completed")
                    self?.cancellingSpinner.isHidden = true
            })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            willCancel?.dispose()
            willCancel = nil
            self?.cancellingSpinner.isHidden = true
        }
    }
    
    let countdownSubject = BehaviorSubject(value: 3)
    @IBOutlet var countdownButton: UIButton!
    var sub: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sub = countdownSubject
            .lane("Countdown", filter: [.event], logger: Timelane.defaultLogger)
        .map { "Tap me \($0) more times" }
        .subscribe(onNext: {
            [weak self] in self?.countdownButton.setTitle($0, for: .normal)
            }, onCompleted: {
                [weak self] in self?.countdownButton.setTitle("Finished", for: .normal)
        })
    }
    
    @IBAction func doEvent(_ sender: Any) {
        guard try! countdownSubject.value() > 0 else { return }
        guard try! countdownSubject.value() > 1 else {
            countdownSubject.onCompleted()
            return
        }
        countdownSubject.onNext(try! countdownSubject.value() - 1)
    }
}
