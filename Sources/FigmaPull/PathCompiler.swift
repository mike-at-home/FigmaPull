import FigmaAPI
import Foundation
import QueryPath

// MARK: - FigmaQueryCompiler

struct FigmaQueryCompiler: QueryPathCompiler {
    public typealias Input = FigmaSession
    public typealias Node = QueryableNode

    var totalDepth: Int = 0
    var rootFetch: ((Input) async throws -> [NodeLocation])? = nil

    var steps: [(inout [Node]) -> Void] = []
    var currentTests: [(Node) -> Bool] = []

    static let nodeTypeMap: [String: FigmaV1.Nodes.Node.Type] = FigmaV1.Nodes.nodeTypes.reduce(into: [:]) {
        $0[$1.typeName.replacingOccurrences(of: "_", with: "").uppercased()] = $1
    }

    static func typeNameForName(_ name: String) throws -> String {
        let node = try nodeForName(name)
        return node.typeName
    }

    static func nodeForName(_ name: String) throws -> FigmaV1.Nodes.Node.Type {
        nodeTypeMap[name.uppercased()]!
    }

    mutating func append(axis: QueryPath.Axis, conditions: [QueryPath.BooleanExpression]) throws {
        if rootFetch == nil {
            try appendFirst(axis: axis, conditions: conditions)
            return
        }

        try appendNext(axis: axis, conditions: conditions)
    }

    mutating func finalize() throws -> (FigmaSession) async throws -> [QueryableNode] {
        flushConditions()
        let rootFetch = rootFetch!
        let totalDepth = self.totalDepth > 10 ? nil : self.totalDepth
        let steps = self.steps

        return {
            let rootNodeIDs = try await rootFetch($0)
            guard !rootNodeIDs.isEmpty else { return [] }
            var nodes = try await $0.getNodes(rootNodeIDs, depth: totalDepth)

            for step in steps {
                step(&nodes)
                if nodes.isEmpty { return [] }
            }

            return nodes
        }
    }

    mutating func appendFirst(axis: QueryPath.Axis, conditions: [QueryPath.BooleanExpression]) throws {
        guard conditions.count >= 2 else { preconditionFailure() }

        switch (axis, conditions[0], conditions[1]) {
        case (
            .descendantOrSelf,
            .equals(.function("name"), .basic(.string(let name))),
            .equals(.function("id"), .basic(.string(let id)))
        ):
            let nodeType = try Self.nodeForName(name)

            guard let nodeType = nodeType as? FigmaRootPathNode.Type else {
                preconditionFailure()
            }

            rootFetch = { try await nodeType.rootIDs(session: $0, id: id) }

        default:
            preconditionFailure()
        }

        try addConditions(conditions.dropFirst(2))
    }

    mutating func appendNext(axis: QueryPath.Axis, conditions: [QueryPath.BooleanExpression]) throws {
        flushConditions()

        switch axis {
        case .child:
            steps.append {
                $0 = $0.flatMap { $0.children() }
            }
            totalDepth += 1

        case .descendant:
            steps.append {
                $0 = $0.flatMap { $0.descendants() }
            }
            totalDepth += 9000

        case .descendantOrSelf:
            steps.append {
                $0 = $0.flatMap { $0.descendantsAndSelf() }
            }

            totalDepth += 9000
        case .self_:
            break

        default:
            preconditionFailure()
        }

        try addConditions(conditions)
    }

    mutating func addConditions<S: Sequence>(_ conditions: S) throws where S.Element == QueryPath.BooleanExpression {
        for c in conditions {
            try addCondition(c)
        }
    }

    mutating func addCondition(_ condition: QueryPath.BooleanExpression) throws {
        switch condition {
        case .equals(.function("name"), .basic(.string(let name))):
            currentTests.append { (try? $0.nodeType === Self.nodeForName(name)) ?? false }

        case .equals(.function("id"), .basic(.string(let id))):
            currentTests.append { $0.id == id }

        case .equals(.attribute("name"), .basic(.string(let name))):
            currentTests.append { $0.name == name }

        case .equals(.function("position", []), .basic(.integer(let position))):
            flushConditions()
            steps.append {
                if $0.count >= position {
                    $0 = [$0[position - 1]]
                } else {
                    $0.removeAll()
                }
            }

        default:
            preconditionFailure()
        }
    }

    mutating func flushConditions() {
        guard !currentTests.isEmpty else { return }
        let tests = currentTests
        currentTests.removeAll()
        steps.append {
            $0.removeAll(where: { node in
                !tests.allSatisfy { $0(node) }
            })
        }
    }
}

// MARK: - FigmaRootPathNode

protocol FigmaRootPathNode: FigmaV1.Nodes.Node {
    static func rootIDs(session: FigmaSession, id: String) async throws -> [NodeLocation]
}

// MARK: - FigmaV1.Component + FigmaRootPathNode

extension FigmaV1.Nodes.Component: FigmaRootPathNode {
    static func rootIDs(session: FigmaSession, id: String) async throws -> [NodeLocation] {
        preconditionFailure()
    }
}

// MARK: - FigmaV1.ComponentSet + FigmaRootPathNode

extension FigmaV1.Nodes.ComponentSet: FigmaRootPathNode {
    static func rootIDs(session: FigmaSession, id: String) async throws -> [NodeLocation] {
        let componentSet = try await session.getComponentSet(.init(rawValue: id))

        guard
            let fileKey = componentSet.result.fileKey,
            let nodeID = componentSet.result.nodeID else {
            preconditionFailure()
        }

        return [.init(file: fileKey, node: nodeID)]
    }
}

// MARK: - FigmaV1.Nodes.Document + FigmaRootPathNode

extension FigmaV1.Nodes.Document: FigmaRootPathNode {
    static func rootIDs(session: FigmaSession, id: String) async throws -> [NodeLocation] {
        return [.init(file: .init(rawValue: id), node: "0:0")]
    }
}

// MARK: - NodeLocation

struct NodeLocation: CustomStringConvertible {
    var file: FigmaV1.FileKey
    var node: FigmaV1.NodeID

    var description: String {
        return "document['\(file.rawValue)']//*['\(node.rawValue)']"
    }
}

extension FigmaSession {
    func getNodes(_ nodes: [NodeLocation], depth: Int?) async throws -> [QueryableNode] {
        let buckets = Dictionary(grouping: nodes, by: { $0.file })

        var result: [QueryableNode] = []
        for (key, nodes) in buckets {
            try result
                .append(
                    contentsOf: await self.getFileNodes(key, nodes: nodes.map { $0.node }, depth: depth).nodes
                        .values.map { .init(file: key, parent: nil, wrapped: $0.document) }
                )
        }

        return result
    }
}

// MARK: - QueryableNode

struct QueryableNode {
    var file: FigmaV1.FileKey
    var wrapped: FigmaV1.Nodes.Node
    var parent: FigmaV1.Nodes.Node?

    public var location: NodeLocation {
        .init(file: file, node: .init(rawValue: id))
    }

    public var id: String { wrapped.id }

    public var name: String { wrapped.name }

    public var nodeType: FigmaV1.Nodes.Node.Type {
        type(of: wrapped)
    }

    init(file: FigmaV1.FileKey, parent: FigmaV1.Nodes.Node?, wrapped: FigmaV1.Nodes.Node) {
        self.file = file
        self.parent = parent
        self.wrapped = wrapped
    }

    func children() -> [QueryableNode] {
        wrapped._children.map {
            .init(file: file, parent: self.wrapped, wrapped: $0)
        }
    }

    func descendants() -> [QueryableNode] {
        let children = self.children()

        var result: [QueryableNode] = children

        for child in children {
            result.append(contentsOf: child.descendants())
        }
        return result
    }

    func descendantsAndSelf() -> [QueryableNode] {
        return descendants() + [self]
    }
}
