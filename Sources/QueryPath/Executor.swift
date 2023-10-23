import Foundation

extension QueryPath {
    public func compile<C: QueryPathCompiler>(_ compiler: inout C) throws -> (C.Input) async throws -> [C.Node] {
        for s in steps {
            try compiler.append(axis: s.axis, conditions: s.conditions)
        }

        return try compiler.finalize()
    }
}

// MARK: - QueryPathCompiler

public protocol QueryPathCompiler<Input, Node> {
    associatedtype Input
    associatedtype Node

    mutating func append(axis: QueryPath.Axis, conditions: [QueryPath.BooleanExpression]) throws

    mutating func finalize() throws -> (Input) async throws -> [Node]
}
