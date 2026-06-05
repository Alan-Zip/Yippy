//
//  YippyTests.swift
//  YippyTests
//
//  Created by Matthew Davidson on 26/7/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import XCTest
import Cocoa
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

final class HistoryRestoreTests: XCTestCase {

    private final class RecordingHistoryFileManager: HistoryFileManager, @unchecked Sendable {
        var deletedItems = [HistoryItem]()
        var insertedIndexes = [Int]()

        override func deleteItem(newHistory: [HistoryItem], deleted: HistoryItem, completionHandler handler: CompletionHandler? = nil) {
            deletedItems.append(deleted)
            handler?(true)
        }

        override func insertItem(newHistory: [HistoryItem], at i: Int, completionHandler handler: CompletionHandler? = nil) {
            insertedIndexes.append(i)
            handler?(true)
        }
    }

    func testRestoreReinsertsDeletedItemAtOriginalIndex() {
        let historyFM = RecordingHistoryFileManager()
        let history = makeHistory(["first", "second", "third"], historyFM: historyFM)

        history.deleteItem(at: 1)

        XCTAssertTrue(history.hasRestorableDeletedItems)
        XCTAssertEqual(history.items.map({ $0.getPlainString() }), ["first", "third"])

        let restoredIndex = history.restoreLastDeletedItem()

        XCTAssertEqual(restoredIndex, 1)
        XCTAssertEqual(history.items.map({ $0.getPlainString() }), ["first", "second", "third"])
        XCTAssertFalse(history.hasRestorableDeletedItems)
        XCTAssertEqual(historyFM.deletedItems.count, 1)
        XCTAssertEqual(historyFM.insertedIndexes, [1])
    }

    func testRestoreBufferKeepsMostRecentFiveDeletedItems() {
        let history = makeHistory((0..<6).map({ "\($0)" }))

        for _ in 0..<6 {
            history.deleteItem(at: 0)
        }

        var restoredValues = [String]()
        while let restoredIndex = history.restoreLastDeletedItem() {
            restoredValues.append(history.items[restoredIndex].getPlainString() ?? "")
        }

        XCTAssertEqual(restoredValues, ["5", "4", "3", "2", "1"])
        XCTAssertNil(history.restoreLastDeletedItem())
    }

    private func makeHistory(_ values: [String], historyFM: HistoryFileManager = RecordingHistoryFileManager()) -> History {
        let cache = HistoryCache(historyFM: historyFM)
        let items = values.map { value in
            HistoryItem(unsavedData: [.string: Data(value.utf8)], cache: cache)
        }

        return History(historyFM: historyFM, cache: cache, items: items)
    }
}
