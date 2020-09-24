//
//  ExchangeRateService.swift
//  MoneyConverterMVVM
//
//  Created by Omar Eduardo Gomez Padilla on 12/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import Foundation
import Combine

struct SymbolDescription: Decodable {
    let description: String
    let code: String
}

struct SymbolResponse: Decodable {
    let success: Bool
    let symbols: [String: SymbolDescription]
}

struct ConvertResponse: Decodable {
    let result: Double
}

enum ExchangeRateServiceError: Error {
    
    case error(String)

    var localizedDescription: String {
        switch self {
        case .error(let msg):
            return msg
        }
    }
}

protocol URLProvider {
    func symbols() -> URL
    func convert(from: String, to: String) -> URL
}

protocol ExchangeRateService {
    func getSymbols() -> AnyPublisher<SymbolResponse, Error>
    func convert(from: String, to: String) -> AnyPublisher<Double, Error>
}

class ExchangeRateServiceImpl: ExchangeRateService {
    
    private class ReleaseURLProvider: URLProvider {
        func symbols() -> URL { URL(string: "https://api.exchangerate.host/symbols")! }
        
        func convert(from: String, to: String) -> URL {
            URL(string: "https://api.exchangerate.host/convert?from=\(from)&to=\(to)")!
        }
    }
    
    let urlProvider: URLProvider
    
    static func getDefaultProvider() -> URLProvider {
        #if HTTPSTUBS
            return HTTPDynamicStubs.urlProvider
        #else
            return ReleaseURLProvider()
        #endif
    }
    
    init(_ urlProvider: URLProvider = ExchangeRateServiceImpl.getDefaultProvider()) {
        self.urlProvider = urlProvider
    }
    
    func getSymbols() -> AnyPublisher<SymbolResponse, Error> {
        Future<SymbolResponse, Error> { promise in
            var cancellable: AnyCancellable?
            cancellable = URLSession.shared.dataTaskPublisher(for: self.urlProvider.symbols())
                .map { $0.data }
                .decode(type: SymbolResponse.self, decoder: JSONDecoder())
                .sink(receiveCompletion: { completion in
                    cancellable?.cancel()
                    switch completion {
                    case .finished:
                        break
                    case .failure(let anError):
                        promise(.failure(anError))
                    }
                }, receiveValue: { value in
                    promise(.success(value))
                })
            
        }
        .eraseToAnyPublisher()
    }
     
    func convert(from: String, to: String) -> AnyPublisher<Double, Error> {
        Future<Double, Error> { promise in
            var cancellable: AnyCancellable?
            cancellable = URLSession.shared.dataTaskPublisher(for: self.urlProvider.convert(from: from, to: to))
                .map { $0.data }
                .decode(type: ConvertResponse.self, decoder: JSONDecoder())
                .sink(receiveCompletion: { completion in
                    cancellable?.cancel()
                    switch completion {
                    case .finished:
                        break
                    case .failure(let anError):
                        promise(.failure(anError))
                    }
                }, receiveValue: { value in
                    promise(.success(value.result))
                })
        }
        .eraseToAnyPublisher()

    }
    
}
