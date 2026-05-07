//
//  AlerterMock.swift
//  YippyTests
//
//  Created by Matthew Davidson on 20/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import XCTest
@testable import Yippy

class AlerterMock: Alerter, @unchecked Sendable {
    
    var expectation: XCTestExpectation!
    
    override func show(_ alertable: any Alertable) {
        expectation.fulfill()
    }
}
