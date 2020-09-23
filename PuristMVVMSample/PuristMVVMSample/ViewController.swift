//
//  ViewController.swift
//  PuristMVVMSample
//
//  Created by Omar Eduardo Gomez Padilla on 22/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {

    @IBOutlet weak var outLabel: UILabel!
    
    let inputSubject = PassthroughSubject<String, Never>()
    var cancellables: Set<AnyCancellable> = []
    
    let viewModel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Binding logic
        viewModel.transform(input:  inputSubject.eraseToAnyPublisher())
            .sink(receiveValue: { value in
                self.outLabel.text = value
            })
            .store(in: &cancellables)
        
    }
    
    @IBAction func onChanged(_ sender: UITextField) {
        inputSubject.send(sender.text ?? "")
    }
}

