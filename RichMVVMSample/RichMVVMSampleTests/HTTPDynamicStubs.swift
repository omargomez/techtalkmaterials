//
//  HTTPDynamicStubs.swift
//
//  Created by Omar Eduardo Gomez Padilla on 17/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import Foundation
//import Swifter

enum HTTPMethod {
    case POST
    case GET
    case PUT
}

class HTTPDynamicStubs {
    
    class TestURLProvider: URLProvider {
        func symbols() -> URL { URL(string: "http://localhost:9999/symbols")! }
        
        func convert(from: String, to: String) -> URL { URL(string: "http://localhost:9999/convert")! }
    }

    var server = HttpServer()
    let port: UInt16 = 9999
    static let urlProvider: URLProvider = TestURLProvider()

    func setUp() {
        try! server.start(port)
    }
    
    func tearDown() {
        server.stop()
    }
    
    func setupInitialStubs() {
        for stub in initialStubs {
            setupStub(url: stub.url, filename: stub.jsonFilename, method: stub.method)
        }
    }
    
    public func setupStub(url: String, filename: String, method: HTTPMethod = .GET) {
        let testBundle = Bundle(for: Swift.type(of: self))
        let filePath = testBundle.path(forResource: filename, ofType: "txt")
        let fileUrl = URL(fileURLWithPath: filePath!)
        let data = try! Data(contentsOf: fileUrl, options: .uncached)
        let text = String(data: data, encoding: .ascii)
        
        let response: ((HttpRequest) -> HttpResponse) = { _ in
            return HttpResponse.ok(.text(text!))
        }
        
        switch method {
        case .GET : server.GET[url] = response
        case .POST: server.POST[url] = response
        case .PUT: server.PUT[url] = response
        }
    }

}

struct HTTPStubInfo {
    let url: String
    let jsonFilename: String
    let method: HTTPMethod
}

let initialStubs = [
    HTTPStubInfo(url: "/integers", jsonFilename: "oneResponse", method: .GET),
]
