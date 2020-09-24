//
//  ViewModelTest.swift
//  RichMVVMSampleTests
//
//  Created by Omar Eduardo Gomez Padilla on 24/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import XCTest
import Combine
@testable import RichMVVMSample

class ViewModelTest: XCTestCase {

    let dynamicStubs = HTTPDynamicStubs()
    var sut: ViewModel!
    var cancellables: Set<AnyCancellable> = []
    var didLoadSubject: PassthroughSubject<Void, Never>!
    var amountSubject: PassthroughSubject<String, Never>!
    var convertSubject: PassthroughSubject< (from: Bool, symbol: String), Never>!
    

    override func setUpWithError() throws {
        dynamicStubs.setUp()
        
        let service = ExchangeRateServiceImpl(HTTPDynamicStubs.urlProvider)
        sut = ViewModel(exchangeService: service)
        didLoadSubject = PassthroughSubject<Void, Never>()
        amountSubject = PassthroughSubject<String, Never>()
        convertSubject = PassthroughSubject< (from: Bool, symbol: String), Never>()
        
    }

    override func tearDownWithError() throws {
        dynamicStubs.tearDown()
        cancellables.removeAll()
        didLoadSubject = nil
        amountSubject = nil
        convertSubject = nil
    }

    func testLoadOK() throws {
        
        dynamicStubs.setupStub(url: "/symbols", filename: "symbols")
        
        let input = ViewModel.Input(loadEvent: didLoadSubject.eraseToAnyPublisher(),
            amount: amountSubject.eraseToAnyPublisher(),
            convertEvent: convertSubject.eraseToAnyPublisher())
        
        let output = sut.transform(input: input)
        
        let expectation = self.expectation(description: "Symbol response")
        var symbols: [SymbolDescription]?
        
        var loadedCount = 0
        var lastLoadedValue = true
        output.isLoading
            .sink(receiveValue: { value in
                loadedCount += 1
                lastLoadedValue = value
            })
            .store(in: &cancellables)
        
        output.symbols
            .sink(receiveValue: { value in
                symbols = value
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        didLoadSubject.send()

        self.waitForExpectations(timeout: 100, handler: nil)
        XCTAssertFalse(lastLoadedValue, "Loaded should be false")
        XCTAssertTrue(loadedCount == 2, "Loaded count should be 2")
        XCTAssertNotNil(symbols, "Symbols shouldn't be nil")
    }
    
    func testLoadFail() throws {
        dynamicStubs.setupStub(url: "/wrong_url", filename: "symbols")
        
        let input = ViewModel.Input(loadEvent: didLoadSubject.eraseToAnyPublisher(),
                                    amount: amountSubject.eraseToAnyPublisher(),
                                    convertEvent: convertSubject.eraseToAnyPublisher())
        
        let output = sut.transform(input: input)
        
        let expectation = self.expectation(description: "Symbol response")

        var loadedCount = 0
        var lastLoadedValue = true
        output.isLoading
            .sink(receiveValue: { value in
                loadedCount += 1
                lastLoadedValue = value
            })
            .store(in: &cancellables)
        
        var error: ErrorViewModel?
        output.error
            .sink(receiveValue: { value in
                error = value
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        didLoadSubject.send()
        
        self.waitForExpectations(timeout: 100, handler: nil)
        XCTAssertFalse(lastLoadedValue, "Loaded should be false")
        XCTAssertTrue(loadedCount == 2, "Loaded count should be 2")
        XCTAssertNotNil(error, "Errors shouldn't be nil")
        XCTAssertNotNil(error!.title == "Get Symbols Error", "Must be a Symbols Error")
    }

    func testLoadDefultConversion() throws {
        dynamicStubs.setupStub(url: "/symbols", filename: "symbols")
        dynamicStubs.setupStub(url: "/convert", filename: "convert")
        
        let input = ViewModel.Input(loadEvent: didLoadSubject.eraseToAnyPublisher(),
                                    amount: amountSubject.eraseToAnyPublisher(),
                                    convertEvent: convertSubject.eraseToAnyPublisher())
        
        let output = sut.transform(input: input)
        
        let expectation = self.expectation(description: "Symbol response")
        
        output.symbols
            .sink(receiveValue: { value in
                expectation.fulfill()
            })
            .store(in: &cancellables)

        didLoadSubject.send()
        self.wait(for: [expectation], timeout: 100)
        
        // default rate should be loaded
        let convertedExp = self.expectation(description: "converted response")
        var convertedVal: (amount: Double, symbol: String)?
        output.converted
            .sink(receiveValue: { value in
                convertedVal = value
                convertedExp.fulfill()
            })
            .store(in: &cancellables)
        
        let amount = 200
        amountSubject.send("\(amount)")
        self.wait(for: [convertedExp], timeout: 100)

        XCTAssertNotNil(convertedVal, "The converted value shouldn't be nil")
        XCTAssertTrue(convertedVal?.symbol == "COP", "COP should be the default symbol")
        XCTAssertTrue(Int(convertedVal!.amount) == amount, "\(amount) should be the default amount")

    }
    
    func testCustomCoversion() throws {
        dynamicStubs.setupStub(url: "/symbols", filename: "symbols")
        dynamicStubs.setupStub(url: "/convert", filename: "convert")
        
        let input = ViewModel.Input(loadEvent: didLoadSubject.eraseToAnyPublisher(),
                                    amount: amountSubject.eraseToAnyPublisher(),
                                    convertEvent: convertSubject.eraseToAnyPublisher())
        
        let output = sut.transform(input: input)
        
        let expectation = self.expectation(description: "Symbol response")
        
        output.symbols
            .sink(receiveValue: { value in
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        didLoadSubject.send()
        self.wait(for: [expectation], timeout: 100)
        
        // let's load a new Symbol
        let convertedExp = self.expectation(description: "converted response")
        var convertedVal: (amount: Double, symbol: String)?
        
        let amount = 200
        output.converted
            .sink(receiveValue: { value in
                convertedVal = value
                if Int(convertedVal!.amount) != amount {
                    convertedExp.fulfill()
                }
            })
            .store(in: &cancellables)
        
        amountSubject.send("\(amount)")
        convertSubject.send( (from: false, symbol: "USD") )
        self.wait(for: [convertedExp], timeout: 100)
        
        let converted = convertedVal!.amount
        print("converted: \(converted), \(converted/3729)")
        
        XCTAssertNotNil(convertedVal, "The converted value shouldn't be nil")
        XCTAssertTrue(convertedVal?.symbol == "USD", "COP should be the default symbol")
        XCTAssertTrue(Int(convertedVal!.amount / 3729.602739) == amount, "Converted value should match rate")
        
    }
}
