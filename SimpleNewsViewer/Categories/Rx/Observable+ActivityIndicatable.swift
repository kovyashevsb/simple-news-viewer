//
//  Observable+ActivityIndicatable.swift
//  SimpleNewsViewer
//
//  Created by Sergey on 28.11.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

import Foundation
import RxSwift

extension Observable {
    func trackActivity(_ observer: @escaping (Bool) -> Void) -> Observable {
        self.do(
            onError: { _ in
                observer(false)
        },
            onCompleted: {
                observer(false)
        },
            onSubscribed: {
                observer(true)
        },
            onDispose: {
                observer(false)
        })
    }
}

extension Single where Trait == SingleTrait {
    func trackActivity(_ observer: @escaping (Bool) -> Void) -> Single<Element> {
        asObservable()
            .trackActivity(observer)
            .asSingle()
    }
}

extension Completable {
    func trackActivity(_ observer: @escaping (Bool) -> Void) -> Completable {
        asObservable()
            .trackActivity(observer)
            .asCompletable()
    }
}
