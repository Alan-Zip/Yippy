//
//  SearchEngine.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

struct SearchQuery: Hashable, Equatable, Sendable {
    
    var query: String
    let searchableText: SearchableText
    
    // Enforce the data invariant
    private init(query: String) {
        self.query = query
        self.searchableText = SearchableText(query)
    }
    
    static func fromRawText(_ str: String) -> SearchQuery {
        return SearchQuery(query: SearchableText(str).normalized)
    }

    static func == (lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        return lhs.query == rhs.query
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(query)
    }
}

struct SearchDocument: Sendable {
    let index: Int
    let searchableText: SearchableText

    init(index: Int, text: String) {
        self.index = index
        self.searchableText = SearchableText(text)
    }
}

private struct SearchMatch {
    let index: Int
    let score: Int
}

public class SearchResult: @unchecked Sendable {
    
    var query: SearchQuery
    var results: [Int] = []
    var items: Int
    var completed: Int = 0
    
    var isFinished: Bool {
        return completed == items
    }
    
    init(query: SearchQuery, items: Int) {
        self.query = query
        self.items = items
    }
    
    func addResult(_ i: Int) {
        results.append(i)
        completed += 1
    }
    
    func recordFailure() {
        completed += 1
    }

    func finish(with results: [Int]) {
        self.results = results
        self.completed = items
    }
}

private struct SearchCompletion: @unchecked Sendable {
    let handler: (SearchResult) -> Void

    func callAsFunction(_ result: SearchResult) {
        handler(result)
    }
}

public class SearchEngine: @unchecked Sendable {
    
    var results = [SearchQuery: SearchResult]()
    
    var inProgress = [SearchQuery]()
    
    private let stateQueue = DispatchQueue(label: "SearchEngine.state", qos: .userInitiated)

    private let searchQueue = DispatchQueue(label: "SearchEngine.search", qos: .userInitiated, attributes: .concurrent)
    
    let documents: [SearchDocument]
    
    init(data: [String]) {
        self.documents = data.enumerated().map { index, text in
            SearchDocument(index: index, text: text)
        }
    }

    init(indexedData: [SearchDocument]) {
        self.documents = indexedData
    }
    
    public func search(query: String, completion: @escaping (SearchResult) -> Void) {
        let searchQuery = SearchQuery.fromRawText(query)
        let completionHandler = SearchCompletion(handler: completion)
        
        if let result = findResult(forQuery: searchQuery) {
            return completion(result)
        }
        
        stateQueue.async {
            self.inProgress.append(searchQuery)
        }

        let documents = self.documents
        searchQueue.async {
            let searchResult = SearchResult(query: searchQuery, items: documents.count)
            var matches = [SearchMatch]()
            
            for document in documents {
                if searchQuery.query.isEmpty {
                    matches.append(SearchMatch(index: document.index, score: 0))
                }
                else if let score = SearchScorer.score(query: searchQuery.searchableText, candidate: document.searchableText) {
                    matches.append(SearchMatch(index: document.index, score: score))
                }
                else {
                    searchResult.recordFailure()
                }
            }

            let orderedResults = matches
                .sorted { lhs, rhs in
                    if lhs.score == rhs.score {
                        return lhs.index < rhs.index
                    }
                    return lhs.score > rhs.score
                }
                .map(\.index)
            searchResult.finish(with: orderedResults)
            
            self.stateQueue.async {
                self.inProgress.removeAll(where: {$0 == searchQuery})
                self.results[searchQuery] = searchResult

                DispatchQueue.main.async {
                    completionHandler(searchResult)
                }
            }
        }
    }
    
    private func findResult(forQuery query: SearchQuery) -> SearchResult? {
        return stateQueue.sync {
            return results[query]
        }
    }
}
