//
//  Search.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

public func performSearch(needle: String, haystack: String) -> Bool {
    return searchScore(needle: needle, haystack: haystack) != nil
}

func searchScore(needle: String, haystack: String) -> Int? {
    return SearchScorer.score(
        query: SearchableText(needle),
        candidate: SearchableText(haystack)
    )
}

struct SearchableText: Sendable {
    let normalized: String
    let tokens: [SearchToken]
    let acronym: String

    init(_ rawValue: String) {
        normalized = Self.normalize(rawValue)
        tokens = Self.tokenize(normalized)
        acronym = tokens.reduce(into: "") { result, token in
            if let first = token.text.first {
                result.append(first)
            }
        }
    }

    private static func normalize(_ value: String) -> String {
        let folded = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
        let collapsedWhitespace = folded.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return collapsedWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokenize(_ value: String) -> [SearchToken] {
        var tokens = [SearchToken]()
        var current = ""

        func flushCurrentToken() {
            guard !current.isEmpty else { return }
            tokens.append(SearchToken(text: current, ordinal: tokens.count))
            current = ""
        }

        for scalar in value.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.unicodeScalars.append(scalar)
            }
            else {
                flushCurrentToken()
            }
        }

        flushCurrentToken()
        return tokens
    }
}

struct SearchToken: Sendable {
    let text: String
    let ordinal: Int
}

enum SearchScorer {
    static func score(query: SearchableText, candidate: SearchableText) -> Int? {
        guard !query.normalized.isEmpty else { return 0 }
        guard !candidate.normalized.isEmpty else { return nil }

        var totalScore = 0
        var hasMatch = false

        if query.normalized == candidate.normalized {
            totalScore += 200_000
            hasMatch = true
        }

        if let phraseScore = phraseMatchScore(query: query.normalized, candidate: candidate.normalized) {
            totalScore += phraseScore
            hasMatch = true
        }

        if !query.tokens.isEmpty {
            var tokenScore = 0
            for queryToken in query.tokens {
                guard let bestScore = bestTokenScore(for: queryToken.text, in: candidate) else {
                    return hasMatch ? totalScore : nil
                }
                tokenScore += bestScore
            }
            totalScore += tokenScore
            totalScore += orderedTokenBonus(queryTokens: query.tokens, candidateTokens: candidate.tokens)
            hasMatch = true
        }

        return hasMatch ? totalScore : nil
    }

    private static func phraseMatchScore(query: String, candidate: String) -> Int? {
        guard let range = candidate.range(of: query) else { return nil }

        let start = candidate.distance(from: candidate.startIndex, to: range.lowerBound)
        let startBonus = max(0, 20_000 - (start * 50))
        let lengthBonus = min(10_000, query.count * 150)
        return 100_000 + startBonus + lengthBonus
    }

    private static func bestTokenScore(for queryToken: String, in candidate: SearchableText) -> Int? {
        var bestScore: Int?

        for candidateToken in candidate.tokens {
            if let score = tokenScore(queryToken: queryToken, candidateToken: candidateToken) {
                bestScore = max(bestScore ?? score, score)
            }
        }

        if let acronymScore = acronymScore(queryToken: queryToken, acronym: candidate.acronym) {
            bestScore = max(bestScore ?? acronymScore, acronymScore)
        }

        return bestScore
    }

    private static func tokenScore(queryToken: String, candidateToken: SearchToken) -> Int? {
        let ordinalPenalty = candidateToken.ordinal * 200

        if candidateToken.text == queryToken {
            return 60_000 - ordinalPenalty + min(5_000, queryToken.count * 200)
        }

        if candidateToken.text.hasPrefix(queryToken) {
            return 45_000 - ordinalPenalty + min(4_000, queryToken.count * 150)
        }

        if let range = candidateToken.text.range(of: queryToken) {
            let start = candidateToken.text.distance(from: candidateToken.text.startIndex, to: range.lowerBound)
            return 30_000 - ordinalPenalty - (start * 500) + min(3_000, queryToken.count * 120)
        }

        if let fuzzyScore = tightSubsequenceScore(needle: queryToken, haystack: candidateToken.text) {
            return fuzzyScore - ordinalPenalty
        }

        return nil
    }

    private static func acronymScore(queryToken: String, acronym: String) -> Int? {
        guard !acronym.isEmpty else { return nil }

        if acronym == queryToken {
            return 40_000 + min(3_000, queryToken.count * 200)
        }

        if acronym.hasPrefix(queryToken) {
            return 35_000 + min(2_000, queryToken.count * 150)
        }

        if let range = acronym.range(of: queryToken) {
            let start = acronym.distance(from: acronym.startIndex, to: range.lowerBound)
            return 25_000 - (start * 400) + min(1_500, queryToken.count * 100)
        }

        return nil
    }

    private static func tightSubsequenceScore(needle: String, haystack: String) -> Int? {
        guard needle.count >= 2, needle.count <= haystack.count else { return nil }

        var positions = [Int]()
        var searchStart = haystack.startIndex

        for needleCharacter in needle {
            guard let match = haystack[searchStart...].firstIndex(of: needleCharacter) else {
                return nil
            }
            positions.append(haystack.distance(from: haystack.startIndex, to: match))
            searchStart = haystack.index(after: match)
        }

        guard let first = positions.first, let last = positions.last else { return nil }

        let spread = last - first + 1
        let gaps = spread - needle.count
        guard gaps <= max(2, needle.count) else { return nil }

        let score = 15_000
            + (needle.count * 500)
            - (gaps * 700)
            - (first * 200)
            + (first == 0 ? 2_000 : 0)

        return score > 0 ? score : nil
    }

    private static func orderedTokenBonus(queryTokens: [SearchToken], candidateTokens: [SearchToken]) -> Int {
        guard queryTokens.count > 1, !candidateTokens.isEmpty else { return 0 }

        var searchStart = 0
        var matchedOrdinals = [Int]()

        for queryToken in queryTokens {
            guard let matchedIndex = candidateTokens[searchStart...].firstIndex(where: {
                tokenContains($0.text, queryToken: queryToken.text)
            }) else {
                return 0
            }

            matchedOrdinals.append(candidateTokens[matchedIndex].ordinal)
            searchStart = matchedIndex + 1
        }

        guard let first = matchedOrdinals.first, let last = matchedOrdinals.last else { return 0 }
        let span = last - first + 1
        let gapCount = span - queryTokens.count
        return max(0, 8_000 - (gapCount * 1_000))
    }

    private static func tokenContains(_ candidateToken: String, queryToken: String) -> Bool {
        return candidateToken == queryToken
            || candidateToken.hasPrefix(queryToken)
            || candidateToken.contains(queryToken)
    }
}
