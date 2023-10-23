import Foundation

// MARK: - QueryPath

public struct QueryPath: Codable {
    var totalDepth: Int?
    var steps: [Step]

    init(steps: [Step]) {
        self.steps = steps

        var totalDepth = 0

        for s in steps {
            switch s.axis {
            case .descendantOrSelf:
                self.totalDepth = nil
                return

            case .child:
                totalDepth += 1

            case .parent:
                totalDepth -= 1

            case .self_:
                break

            default:
                break
            }
        }
        self.totalDepth = totalDepth
    }

    public struct Step: Codable, Equatable {
        public var axis: Axis
        public var conditions: [BooleanExpression]
    }

    public enum Axis: String, Codable {
        case ancestor = "ancestor"
        case ancestorOrSelf = "ancestor-or-self"
        case attrobite = "attribute"
        case child = "child"
        case descendant = "descendant"
        case descendantOrSelf = "descendant-or-self"
        case following = "following"
        case followingSibling = "following-sibling"
        case namespace = "namespace"
        case parent = "parent"
        case preceeding = "preceeding"
        case preceedingSibling = "preceedingSibling"
        case self_ = "self"
    }

    public indirect enum Expression: Codable, Equatable {
        case basic(BasicExpression)
        case boolean(BooleanExpression)

        public static func attribute(_ name: String) -> Self {
            .basic(.attribute(name))
        }

        public static func integer(_ value: Int) -> Self {
            .basic(.integer(value))
        }

        public static func string(_ name: String) -> Self {
            .basic(.string(name))
        }

        public static func function(_ name: String, _ arguments: [Expression] = []) -> Self {
            .basic(.function(name, arguments))
        }

        public static func equals(_ lhs: Expression, _ rhs: Expression) -> Self {
            .boolean(.equals(lhs, rhs))
        }
    }

    public indirect enum BooleanExpression: Codable, Equatable {
        case equals(Expression, Expression)
    }

    public indirect enum BasicExpression: Codable, Equatable {
        case attribute(String)
        case identifier(String)
        case integer(Int)
        case string(String)
        case function(String, [Expression])
    }
}
