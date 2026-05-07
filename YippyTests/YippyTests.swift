//
//  YippyTests.swift
//  YippyTests
//
//  Created by Matthew Davidson on 26/7/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import XCTest
@testable import Yippy

class YippyTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

final class SearchTests: XCTestCase {
    func testSearchRejectsLooseCrossWordSubsequence() {
        XCTAssertFalse(performSearch(needle: "abc", haystack: "a very boring clip"))
    }

    func testSearchMatchesCaseAndDiacriticInsensitivePhrase() {
        XCTAssertTrue(performSearch(needle: "resume", haystack: "Résumé tips"))
    }

    func testSearchRanksExactPhraseAheadOfAcronymMatches() {
        let engine = SearchEngine(data: [
            "Alpha Beta Cache",
            "abc",
            "Another Basic Clipboard"
        ])

        let results = runSearch(engine, query: "abc")

        XCTAssertEqual(results.first, 1)
        XCTAssertEqual(Set(results), Set([0, 1, 2]))
    }

    func testSearchAllowsMultiTokenMatchesInAnyOrder() {
        let engine = SearchEngine(data: [
            "copy browser url",
            "paste selected item",
            "browser copy settings"
        ])

        XCTAssertEqual(runSearch(engine, query: "browser copy"), [2, 0])
        XCTAssertEqual(runSearch(engine, query: "copy browser"), [0, 2])
    }

    func testSearchEngineReturnsOriginalDocumentIndices() {
        let engine = SearchEngine(indexedData: [
            SearchDocument(index: 0, text: "plain text"),
            SearchDocument(index: 3, text: "needle text")
        ])

        XCTAssertEqual(runSearch(engine, query: "needle"), [3])
    }

    private func runSearch(_ engine: SearchEngine, query: String) -> [Int] {
        let expectation = expectation(description: "Search completes")
        var results = [Int]()

        engine.search(query: query) { result in
            results = result.results
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        return results
    }
}
