import Foundation
import RegexBuilder

extension QueryPath {
    public enum ParseError: Error {
        case unexpected(String)
        case expectedExpression(String)
        case expectedOperand(String)
        case expected(String, String)
    }

    public init?(_ input: String) throws {
        var steps = [Step]()
        var input = input
        guard let firstStep = try QueryPath.Step.tryTakeFirst(&input) else {
            return nil
        }

        steps.append(firstStep)

        while let step = try QueryPath.Step.tryTakeSubsequent(&input) {
            steps.append(step)
        }

        if !input.isEmpty {
            throw ParseError.unexpected(input)
        }

        self.init(steps: steps)
    }
}

extension QueryPath.Step {
    private static let axisRegex = Regex {
        TryCapture {
            nameStartChar
            ZeroOrMore { nameChar }
        } transform: {
            QueryPath.Axis(rawValue: .init($0))
        }
    }

    private static let identifierRegex = Regex {
        Capture {
            nameStartChar
            ZeroOrMore { nameChar }
        } transform: {
            String($0)
        }
    }

    static func tryTakeFirst(_ input: inout String) throws -> Self? {
        if !input.hasPrefix("/") {
            return try tryTakeStep(axis: .descendantOrSelf, &input)
        }

        return try tryTakeSubsequent(&input)
    }

    static func tryTakeSubsequent(_ input: inout String) throws -> Self? {
        var axis: QueryPath.Axis = .child

        guard input.tryTake("/") else { return nil }

        if input.hasPrefix("/") {
            axis = .descendantOrSelf
        }

        return try tryTakeStep(axis: axis, &input)
    }

    static func tryTakeStep(axis: QueryPath.Axis, _ input: inout String) throws -> Self? {
        var axis = axis
        var tests: [QueryPath.BooleanExpression] = []

        if let aSpec = try input.tryTake(axisRegex)?.1 {
            axis = aSpec
        }

        if let id = try input.tryTake(identifierRegex) {
            tests.append(.equals(.function("name", []), .basic(.string(id.1))))
        } else if !input.tryTake("*") {
            throw QueryPath.ParseError.expected("node name", input)
        }

        while let pred = try tryTakePredicate(&input) {
            tests.append(pred)
        }

        return .init(axis: axis, conditions: tests)
    }

    static func tryTakePredicate(_ input: inout String) throws -> QueryPath.BooleanExpression? {
        guard input.tryTake("[") else { return nil }

        guard let expr = try QueryPath.BasicExpression.tryTake(&input) else {
            throw QueryPath.ParseError.expectedExpression(input)
        }

        if input.tryTake("=") {
            guard let expr2 = try QueryPath.BasicExpression.tryTake(&input) else {
                throw QueryPath.ParseError.expectedOperand(input)
            }

            guard input.tryTake("]") else {
                throw QueryPath.ParseError.expected("]", input)
            }

            return .equals(.basic(expr), .basic(expr2))
        } else {
            guard input.tryTake("]") else {
                throw QueryPath.ParseError.expected("]", input)
            }

            if expr.isNumeric {
                return .equals(.function("position", []), .basic(expr))
            } else {
                return .equals(.function("id", []), .basic(expr))
            }
        }
    }
}

extension String {
    mutating func tryTake(_ p: String) -> Bool {
        guard self.hasPrefix(p) else { return false }
        self.removeFirst(p.count)
        return true
    }

    mutating func tryTake<O>(_ r: Regex<O>) throws -> O? {
        if let match = try r.prefixMatch(in: self) {
            self.removeSubrange(match.range)
            return match.output
        }
        return nil
    }
}

// MARK: - Primitive

extension QueryPath.BasicExpression {
    public var isNumeric: Bool {
        switch self {
        case .integer(_): return true
        default: return false
        }
    }

    private static let identifierRegex = Regex {
        Capture {
            nameStartChar
            ZeroOrMore { nameChar }
        } transform: { String($0) }
    }

    private static let integerRegex = Regex {
        Capture {
            OneOrMore { CharacterClass.generalCategory(.decimalNumber) }
        } transform: {
            QueryPath.BasicExpression.integer(.init($0, radix: 10)!)
        }
    }

    static let singleQuoteString = Regex {
        CharacterClass.singleQuote
        Capture {
            ZeroOrMore {
                CharacterClass.singleQuote.inverted
            }
        } transform: { QueryPath.BasicExpression.string(.init($0)) }
        CharacterClass.singleQuote
    }

    static let doubleQuoteString = Regex {
        CharacterClass.doubleQuote
        Capture {
            ZeroOrMore {
                CharacterClass.doubleQuote.inverted
            }
        } transform: { QueryPath.BasicExpression.string(.init($0)) }
        CharacterClass.doubleQuote
    }

    static func tryTake(_ input: inout String) throws -> Self? {
        if input.tryTake("@") {
            let match = try input.tryTake(identifierRegex)!
            return .attribute(match.1)
        }

        if let match = try input.tryTake(identifierRegex) {
            if input.tryTake("()") {
                return .function(match.1, [])
            } else {
                return .identifier(match.1)
            }
        }

        if let match = try input.tryTake(integerRegex) {
            return match.1
        }

        if let match = try input.tryTake(singleQuoteString) {
            return match.1
        }

        if let match = try input.tryTake(doubleQuoteString) {
            return match.1
        }

        return nil
    }
}

let nameStartChar = Regex {
    ChoiceOf {
        ":" as Unicode.Scalar
        CharacterClass.generalCategory(.uppercaseLetter)
        "_" as Unicode.Scalar
        CharacterClass.generalCategory(.lowercaseLetter)
    }
}

let nameChar = Regex {
    ChoiceOf {
        nameStartChar
        "-" as Unicode.Scalar
        "." as Unicode.Scalar
        CharacterClass.generalCategory(.decimalNumber)
    }
}

extension CharacterClass {
    static let singleQuote = CharacterClass.anyOf("'")
    static let doubleQuote = CharacterClass.anyOf("\"")
}
