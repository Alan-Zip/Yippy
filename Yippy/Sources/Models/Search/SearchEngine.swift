//
//  SearchEngine.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

struct SearchQuery: Hashable, Equatable {
    
    var query: String
    
    // Enfore the data invariant
    private init(query: String) {
        self.query = query
    }
    
    static func fromRawText(_ str: String) -> SearchQuery {
        return SearchQuery(query: str)
    }
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
        results.sort()
        completed += 1
    }
    
    func recordFailure() {
        completed += 1
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
    
    var data: [String]
    
    init(data: [String]) {
        self.data = data
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

        let data = self.data
        searchQueue.async {
            let searchResult = SearchResult(query: searchQuery, items: data.count)
            
            for (i, d) in data.enumerated() {
                if performSearch(needle: searchQuery.query, haystack: d) {
                    searchResult.addResult(i)
                }
                else {
                    searchResult.recordFailure()
                }
            }
            
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
