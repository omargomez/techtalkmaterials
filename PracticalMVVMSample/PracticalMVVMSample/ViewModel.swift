//
//  ViewModel.swift
//  PracticalMVVMSample
//
//  Created by Omar Eduardo Gomez Padilla on 22/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import Foundation
import Combine
import CombineExt


protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    var input: Input { get }
    var output: Output! { get }
}

class ViewModel: ViewModelType {
    
    // PassthroughRelay: Subscriber & Publisher at the same time ...
    typealias Input = PassthroughRelay<String>
    typealias Output = AnyPublisher<String, Never>
    
    var input: Input = PassthroughRelay<String>()
    var output: Output!
    
    init() {
        
        // ViewModel should have been created first!
        output = self.getOutput()
        
    }
    
    private func toHEX(_ val: String) -> String? {
        
        guard let asNum = Int(val) else {
            return nil
        }
        
        return String(format: "%02X", asNum)
    }
    
    private func getOutput() -> AnyPublisher<String, Never> {
        input
            .filter({
                $0 != ""
            })
            .map { self.toHEX($0) ?? "" }
            .eraseToAnyPublisher()
    }
}


