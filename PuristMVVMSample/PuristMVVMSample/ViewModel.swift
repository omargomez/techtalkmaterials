//
//  ViewModel.swift
//  PuristMVVMSample
//
//  Created by Omar Eduardo Gomez Padilla on 22/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import Foundation
import Combine

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}

class ViewModel: ViewModelType {
    
    typealias Input = AnyPublisher<String, Never>
    typealias Output = AnyPublisher<String, Never>
    
    func transform(input: Input) -> Output {
        let hexOut = input
            .filter({
                $0 != ""
            })
            .map { self.toHEX($0) ?? "" }
            .eraseToAnyPublisher()
        
        return hexOut
    }
    
    private func toHEX(_ val: String) -> String? {
        
        guard let asNum = Int(val) else {
            return nil
        }
        
        return String(format: "%02X", asNum)
    }
}


