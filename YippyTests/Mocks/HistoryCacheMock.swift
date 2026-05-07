//
//  HistoryCacheMock.swift
//  YippyTests
//
//  Created by Matthew Davidson on 21/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import XCTest
@testable import Yippy

class HistoryCacheMock: HistoryCache, @unchecked Sendable {
    
    var data: Data?
    
    var dataCallCount = 0
    
    override func data(withId id: UUID, forType type: NSPasteboard.PasteboardType) -> Data? {
        dataCallCount += 1
        return data
    }
}
