import Foundation
import FigmaPullCore

// MARK: - FigmaSession

public class FigmaSession {
    public let session: APISession<FigmaV1>
    public let token: FigmaV1.SessionToken

    public init(token: FigmaV1.SessionToken) {
        self.token = token
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["X-FIGMA-TOKEN": token.rawValue]
        config.timeoutIntervalForRequest = .greatestFiniteMagnitude
        config.timeoutIntervalForResource = .greatestFiniteMagnitude

        session = .init(session: URLSession(configuration: config))
    }

    public func getProjects(_ team: FigmaV1.TeamID) async throws -> FigmaV1.GetTeamProjects.Response {
        let response = try await session.getTeamProjects(team)
        return response
    }

    public func getFileComponentSets(_ file: FigmaV1.FileKey) async throws -> FigmaV1.GetFileComponentSets.Response {
        let response = try await session.getFileComponentSets(file)
        return response
    }

    public func getComponentSet(_ key: FigmaV1.ComponentSetKey) async throws -> FigmaV1.GetComponentSet.Response {
        try await session.getComponentSet(key)
    }

    public func getFileNodes(_ key: FigmaV1.FileKey, nodes: [FigmaV1.NodeID], depth: Int? = nil) async throws -> FigmaV1
        .GetFileNodes.Response {
        try await session
            .getFileNodes(.init(pathValues: key, queryValues: .init(ids: nodes, depth: depth, geometry: "paths")))
    }

    public func getStyle(_ key: FigmaV1.StyleKey) async throws -> FigmaV1.Style {
        try await session.getStyle(.init(pathValues: key, queryValues: .init())).result
    }

    public func getFileImages<S: Sequence>(
        _ key: FigmaV1.FileKey,
        nodes: S,
        settings: ImageExportSettings
    ) async throws -> [FigmaV1.NodeID: URL] where S.Element == FigmaV1.NodeID {
        let result = try await session.getFileImages(
            key,
            settings.toQuery(ids: .init(nodes))
        )
        return result.images
    }

    public func getFileStyles(_ key: FigmaV1.FileKey) async throws -> [FigmaV1.Style] {
        try await session.getFileStyles(.init(pathValues: key, queryValues: .init())).result.elements
    }

    public struct ImageExportSettings {
        public var format: Format = .png
        public var scale: Double = 1
        public var useAbsoluteBounds: Bool = false

        public init(scale: Double = 1, format: Format = .png, useAbsoluteBounds: Bool = false) {
            self.scale = scale
            self.format = format
            self.useAbsoluteBounds = useAbsoluteBounds
        }

        public enum Format {
            case jpg
            case png
            case svg(
                simplifyStroke: Bool = true,
                includeGroupNamesAsIDs: Bool = false,
                includeDataNodeIDs: Bool = false
            )
            case pdf
        }

        func toQuery(ids: [FigmaV1.NodeID]) -> FigmaV1.GetFileImages.Query {
            var result = FigmaV1.GetFileImages.Query(ids: ids)
            if scale != 1 {
                result.scale = scale
            }
            if useAbsoluteBounds {
                result.use_absolute_bounds = true
            }

            switch format {
            case .jpg:
                result.format = .jpg
            case .png:
                result.format = .png
            case .pdf:
                result.format = .pdf
            case let .svg(
                simplifyStroke: simplify,
                includeGroupNamesAsIDs: includeNames,
                includeDataNodeIDs: includeNodeIDs
            ):
                result.format = .svg
                if !simplify {
                    result.svg_simplify_stroke = simplify
                }
                if includeNames {
                    result.svg_include_id = includeNames
                }
                if includeNodeIDs {
                    result.svg_include_node_id = includeNodeIDs
                }
            }
            return result
        }
    }
}

extension FigmaSession {
    private static let baseURL: URL = .init(string: "https://api.figma.com/v1")!
}

extension FigmaSession {
    public func getComponentImages(
        componentSet key: FigmaV1.ComponentSetKey,
        settings: ImageExportSettings
    ) async throws -> [(FigmaV1.Component, URL)] {
        let componentSet = try await session.getComponentSet(key)

        guard
            let fileKey = componentSet.result.fileKey,
            let nodeID = componentSet.result.nodeID else {
            preconditionFailure()
        }

        let fileNodes = try await getFileNodes(fileKey, nodes: [nodeID])
        
        let componentSetNode = fileNodes.nodes.values.first!

        let children = (componentSetNode.document as! FigmaV1.Nodes.ComponentSet).children
        let componentSets = componentSetNode.componentSets

        let ids = children.map { FigmaV1.NodeID(rawValue: $0.id) }

        let fileImages = try await getFileImages(fileKey, nodes: ids, settings: settings)

        var result: [(FigmaV1.Component, URL)] = []

        for (key, value) in fileImages {
            guard let component = componentSetNode.components[key] else {
                preconditionFailure()
            }
            result.append((component, value))
        }

        return result
    }
}

extension FigmaV1.Nodes.FrameBase {}
