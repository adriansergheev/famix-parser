//
//  ParserCombinators.swift
//  
//
//  Created by Adrian Sergheev on 2021-04-27.
//

/*
 inspired from pointfree.co
 */

import Foundation

public struct Parser<Output> {
    let run: (inout Substring) -> Output?
}

public extension Parser {
    func run(_ input: String) -> (match: Output?, rest: Substring) {
        var input = input[...]
        let match = self.run(&input)
        return (match, input)
    }
}

public extension Parser {
    func map<NewOutput>(_ f: @escaping (Output) -> NewOutput) -> Parser<NewOutput> {
        .init { input in
            self.run(&input).map(f)
        }
    }
}

// MARK: - Sequencing (several parsers, applied in the given order, and all must succeed)
public func zip<Output1, Output2>(
    _ p1: Parser<Output1>,
    _ p2: Parser<Output2>
) -> Parser<(Output1, Output2)> {

    .init { input -> (Output1, Output2)? in
        let old = input
        guard let output1 = p1.run(&input) else { return nil }
        guard let output2 = p2.run(&input) else {
            input = old
            return nil
        }
        return (output1, output2)
    }
}

public func zip<A, B, C>(
    _ a: Parser<A>,
    _ b: Parser<B>,
    _ c: Parser<C>
) -> Parser<(A, B, C)> {
    zip(a, zip(b, c))
        .map { a, bc in (a, bc.0, bc.1) }
}
public func zip<A, B, C, D>(
    _ a: Parser<A>,
    _ b: Parser<B>,
    _ c: Parser<C>,
    _ d: Parser<D>
) -> Parser<(A, B, C, D)> {
    zip(a, zip(b, c, d))
        .map { a, bcd in (a, bcd.0, bcd.1, bcd.2) }
}
public func zip<A, B, C, D, E>(
    _ a: Parser<A>,
    _ b: Parser<B>,
    _ c: Parser<C>,
    _ d: Parser<D>,
    _ e: Parser<E>
) -> Parser<(A, B, C, D, E)> {
    zip(a, zip(b, c, d, e))
        .map { a, bcde in (a, bcde.0, bcde.1, bcde.2, bcde.3) }
}

public extension Parser where Output == Void {
    static func prefix(_ p: String) -> Self {
        Self { input in
            guard input.hasPrefix(p) else { return nil }
            input.removeFirst(p.count)
            return ()
        }
    }
}

public extension Parser where Output == Int {
    static let int = Self { input in
        let intPrefix = input.prefix(while: \.isNumber)
        guard let match = Int(intPrefix) else { return nil }
        input.removeFirst(intPrefix.count)
        return match
    }
}

public extension Parser {
    func skip<B>(_ p: Parser<B>) -> Self {
        zip(self, p).map { a, _ in a }
    }
}

public extension Parser {
    func take<NewOutput>(
        _ p: Parser<NewOutput>
    ) -> Parser<(Output, NewOutput)> {
        zip(self, p)
    }
}

public extension Parser {
    static func skip(_ p: Self) -> Parser<Void> {
        p.map { _ in () }
    }
}

public extension Parser {
    static func optional<A>(_ parser: Parser<A>) -> Self where Output == A? {
        .init { input in
            .some(parser.run(&input))
        }
    }
}

// MARK: - Alternation (one of the given must succeed)
public extension Parser {
    static func oneOf(_ parsers: [Self]) -> Self {
        .init { input in
            for parser in parsers {
                if let match = parser.run(&input) {
                    return match
                }
            }
            return nil
        }
    }

    static func oneOf(_ parsers: Self...) -> Self {
        self.oneOf(parsers)
    }
}

public extension Parser {
    func zeroOrMore(
        separatedBy separator: Parser<Void> = .prefix("")
    ) -> Parser<[Output]> {
        Parser<[Output]> { input in
            var rest = input
            var matches: [Output] = []
            while let match = self.run(&input) {
                rest = input
                matches.append(match)
                if separator.run(&input) == nil {
                    return matches
                }
            }
            input = rest
            return matches
        }
    }
}

// MARK: - Repetitions (repeated application of the same parser to the input)

public extension Parser where Output == Substring {
    static func prefix(while predicate: @escaping (Character) -> Bool) -> Self {
        Self { input in
            let output = input.prefix(while: predicate)
            input.removeFirst(output.count)
            return output
        }
    }

    static func prefix(through substring: Substring) -> Self {
        Self { input in
            guard let endIndex = input.range(of: substring)?
                    .upperBound else { return nil }

            let match = input[..<endIndex]
            input = input[endIndex...]
            return match
        }
    }
}
