//
//  ViewController.swift
//  RichMVVMSample
//
//  Created by Omar Eduardo Gomez Padilla on 23/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    //UI
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var amountLabel: UILabel!
    
    //MVVM
    let viewModel = ViewModel()
    
    //Combine
    let didLoadSubject = PassthroughSubject<Void, Never>()
    let amountSubject = PassthroughSubject<String, Never>()
    let convertSubject = PassthroughSubject< (from: Bool, symbol: String), Never>()
    var cancellables: Set<AnyCancellable> = []

    // cache
    var symbolArray: [SymbolDescription] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let input = ViewModel.Input(loadEvent: didLoadSubject.eraseToAnyPublisher(),
            amount: amountSubject.eraseToAnyPublisher(),
            convertEvent: convertSubject.eraseToAnyPublisher())

        let output = viewModel.transform(input: input)
        
        output.isLoading
            .sink(receiveValue: { value in
                if value {
                    self.waitStartAnimation()
                } else {
                    self.waitStopAnimation()
                }
            })
            .store(in: &cancellables)
        
        output.symbols
            .sink(receiveValue: { value in
                self.symbolArray = value
                self.fromButton.isEnabled = true
                self.toButton.isEnabled = true
            })
            .store(in: &cancellables)

        output.fromSymbol
            .sink(receiveValue: { value in
                self.fromButton.setTitle(value.description, for: .normal)
            })
            .store(in: &cancellables)
        
        output.toSymbol
            .sink(receiveValue: { value in
                self.toButton.setTitle(value.description, for: .normal)
            })
            .store(in: &cancellables)
        
        output.converted
            .sink(receiveValue: { value in
                self.amountLabel.text =  String(format: "%.2f", value.amount) + " " + value.symbol
            })
            .store(in: &cancellables)
        
        output.error
            .sink(receiveValue: { viewError in
                let alert = self.createErrorController(message: viewError.message, title: viewError.title)
                self.present(alert, animated: true, completion: nil)
            })
            .store(in: &cancellables)
        
        didLoadSubject.send()

    }
    
    @IBAction func onAmoutChanged(_ sender: UITextField) {
        self.amountSubject.send(sender.text ?? "")
    }
    
    @IBAction func onFromAction(_ sender: UIButton) {
        let descArray = symbolArray.map({ $0.description })
        let alert = self.createOptionListController(title: "Pick", options: descArray, okBlock: { selection in
            self.convertSubject.send( (from: true, symbol: self.symbolArray[selection].code) )
        })
        
        self.present(alert, animated: true)
    }
    
    @IBAction func onToAction(_ sender: Any) {
        let descArray = symbolArray.map({ $0.description })
        let alert = self.createOptionListController(title: "Pick", options: descArray, okBlock: { selection in
            self.convertSubject.send( (from: false, symbol: self.symbolArray[selection].code) )
        })
        
        self.present(alert, animated: true)
    }
    

}

