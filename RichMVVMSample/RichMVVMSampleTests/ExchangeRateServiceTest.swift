//
//  ExchangeRateServiceTest.swift
//  MoneyConverterMVVMTests
//
//  Created by Omar Eduardo Gomez Padilla on 17/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import XCTest
import Combine
@testable import RichMVVMSample

class ExchangeRateServiceTest: XCTestCase {
    
    let dynamicStubs = HTTPDynamicStubs()
    var sut: ExchangeRateService!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUpWithError() throws {
        dynamicStubs.setUp()
        sut = ExchangeRateServiceImpl(HTTPDynamicStubs.urlProvider)
    }

    override func tearDownWithError() throws {
        dynamicStubs.tearDown()
        cancellables.removeAll()
    }

    func testSymbols() {
        dynamicStubs.setupStub(url: "/symbols", filename: "symbols")
        
        let expectation = self.expectation(description: "service response")
        var response: SymbolResponse?
        sut.getSymbols()
            .sink(receiveCompletion: { completion in
                print("completion: \(completion)")
                expectation.fulfill()
            }, receiveValue: { value in
                response = value
            })
            .store(in: &cancellables)
        
        self.waitForExpectations(timeout: 100, handler: nil)
        XCTAssertNotNil(response, "Response shouldn't be empty")
    }
    
    func testSymbolsFailing() {
        dynamicStubs.setupStub(url: "/wrong_url", filename: "symbols")
        
        let expectation = self.expectation(description: "service response")
        var error: Error?
        
        sut.getSymbols()
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let someError):
                error = someError
            }
            expectation.fulfill()
        }, receiveValue: { value in
        })
        .store(in: &cancellables)

        self.waitForExpectations(timeout: 100, handler: nil)
        XCTAssertNotNil(error, "Response should de empty")
    }

    func testConvert() {
        dynamicStubs.setupStub(url: "/convert", filename: "convert")
        
        let expectation = self.expectation(description: "service response")
        var response: Double?
        sut.convert(from: "USD", to: "COP")
            .sink(receiveCompletion: { completion in
                expectation.fulfill()
            }, receiveValue: { value in
                response = value
            })
            .store(in: &cancellables)
        
        self.waitForExpectations(timeout: 100, handler: nil)
        XCTAssertNotNil(response, "Response shouldn't be empty")
    }
    
}
