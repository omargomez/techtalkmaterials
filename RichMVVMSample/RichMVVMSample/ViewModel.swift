//
//  ViewModel.swift
//  RichMVVMSample
//
//  Created by Omar Eduardo Gomez Padilla on 23/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import Foundation
import Combine

struct ErrorViewModel {
    let title: String
    let message: String
}

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}

class ViewModel: ViewModelType {
    
    struct Input {
        let loadEvent: AnyPublisher<Void, Never>
        let amount: AnyPublisher<String, Never>
        let convertEvent: AnyPublisher< (from: Bool, symbol: String), Never>
    }

    struct Output {
        let error: AnyPublisher<ErrorViewModel, Never>
        let symbols: AnyPublisher<[SymbolDescription], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let fromSymbol: AnyPublisher<SymbolDescription, Never>
        let toSymbol: AnyPublisher<SymbolDescription, Never>
        let converted: AnyPublisher<(amount: Double, symbol: String), Never>
    }

    var cancellables: Set<AnyCancellable> = []
    
    //services
    let exchangeService: ExchangeRateService
    
    init(exchangeService: ExchangeRateService = ExchangeRateServiceImpl()) {
        self.exchangeService = exchangeService
    }
    
    func transform(input: Input) -> Output {
        // cached data
        var cachedAmount: Double = 0
        var cachedRate: Double = 0
        var cachedSymbols: [String: SymbolDescription] = [:]

        // output
        let errorSubject = PassthroughSubject<ErrorViewModel, Never>()
        let symbols = PassthroughSubject<[SymbolDescription], Never>()
        let isLoading = PassthroughSubject<Bool, Never>()
        let fromSymbol = CurrentValueSubject<SymbolDescription?, Never>(nil)
        let toSymbol = CurrentValueSubject<SymbolDescription?, Never>(nil)
        let converted = PassthroughSubject<(amount: Double, symbol: String), Never>()

        input.loadEvent
            .sink(receiveValue: {
                isLoading.send(true)
                self.exchangeService.getSymbols()
                    .receive(on: DispatchQueue.main)
                    .map({ $0.symbols })
                    .sink(receiveCompletion: {completion in
                        isLoading.send(false)
                        switch completion {
                        case .failure(let error):
                            let viewError = ErrorViewModel(title: "Get Symbols Error", message: error.localizedDescription)
                            errorSubject.send(viewError)
                        default:
                            break
                        }
                    }, receiveValue: { value in
                        let first = value["COP"] ?? (value[value.keys.sorted().first!])!
                        fromSymbol.value = first
                        toSymbol.value = first

                        cachedSymbols = value
                        cachedRate = 1.0
                        let result = value.values.sorted {  $0.description < $1.description }
                        symbols.send(result)
                    })
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)
        
        input.amount
            .map({ Double($0) ?? 0 })
            .sink(receiveValue: { value in
                cachedAmount = value
                let convertedAmount = cachedAmount * cachedRate
                let result = ( convertedAmount, (toSymbol.value?.code)! )
                converted.send(result)
            })
            .store(in: &cancellables)
        
        input.convertEvent
            .sink(receiveValue: { convertParams in
                isLoading.send(true)
                let (from, to) = convertParams.from ? ( convertParams.symbol,  toSymbol.value?.code ?? "") : ( fromSymbol.value?.code ?? "", convertParams.symbol)
                self.exchangeService.convert(from: from, to: to)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: {completion in
                        isLoading.send(false)
                        switch completion {
                        case .failure(let error):
                            let viewError = ErrorViewModel(title: "Coverting Error", message: error.localizedDescription)
                            errorSubject.send(viewError)
                        default:
                            break
                        }
                    }, receiveValue: { value in
                        if convertParams.from {
                            fromSymbol.value = cachedSymbols[convertParams.symbol]!
                        } else {
                            toSymbol.value = cachedSymbols[convertParams.symbol]!
                        }
                        cachedRate = value
                        let convertedAmount = cachedAmount * cachedRate
                        let result = ( convertedAmount, (toSymbol.value?.code)! )
                        converted.send(result)
                    })
                    .store(in: &self.cancellables)
                
            })
            .store(in: &cancellables)
        
        return Output(error: errorSubject.eraseToAnyPublisher(),
                    symbols: symbols.eraseToAnyPublisher(),
                    isLoading: isLoading.eraseToAnyPublisher(),
                    fromSymbol: fromSymbol
                        .filter({ $0 != nil })
                        .map({ value -> SymbolDescription in
                            value!
                        })
                        .eraseToAnyPublisher(),
                    
                    toSymbol: toSymbol
                        .filter({ $0 != nil })
                        .map({ value -> SymbolDescription in
                            value!
                        })
                        .eraseToAnyPublisher(),
                    converted: converted.eraseToAnyPublisher())
    }
}
