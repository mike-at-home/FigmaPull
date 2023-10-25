import ArgumentParser
import FigmaAPI
import Foundation
import QueryPath

// MARK: - Images

struct Images: AsyncParsableCommand {
    // 0.01 and 4
    @Option(help: "A number between 0.01 and 4, the image scaling factor")
    var scale: Double?

    @Option(help: "jpg, png, svg, or pdf")
    var format: FigmaV1.GetFileImages.Query.Format = .svg

    @Option(
        name: .customLong("svg_outline_text"),
        help: "Whether text elements are rendered as outlines (vector paths) or as <text> elements in SVGs. Default: true."
    )
    var svgOutlineText: Bool?

    @Option(
        name: .customLong("svg_include_id"),
        help: "Whether to include id attributes for all SVG elements. Adds the layer name to the id attribute of an svg element. Default: false."
    )
    var svgIncludeID: Bool?

    @Option(
        name: .customLong("svg_include_node_id"),
        help: "Whether to include node id attributes for all SVG elements. Adds the node id to a data-node-id attribute of an svg element. Default: false."
    )
    var svgIncludeNodeID: Bool?

    @Option(
        name: .customLong("svg_simplify_stroke"),
        help: "Whether to simplify inside/outside strokes and use stroke attribute if possible instead of <mask>. Default: true."
    )
    var svgSimplifyStroke: Bool?

    @Option(
        name: .customLong("use_absolute_bounds"),
        help: "Use the full dimensions of the node regardless of whether or not it is cropped or the space around it is empty. Use this to export text nodes without cropping. Default: false."
    )
    var useAbsoluteBounds: Bool?

    @Flag(help: "Will output the node IDs to be downloaded")
    var test: Bool = false

    @Option(help: "api token")
    var token: FigmaV1.SessionToken

    @Argument(
        help:
        """
        QueryPath to identify nodes to export. Mimics simplistic XPath.

        Valid steps are:
            nodetype[<int>] or nodetype[position()=<int>]
                Match the node with the index in the result set (index starts at 1 like XPath)

            nodetype['<id>'] or nodetype[id()='<id>']
                For root nodes, will match the key. For other nodes, will match the node ID in the document.

            nodetype or child::*[name()='nodetype']
                Valid node types are available in Figma API documentation by removing underscores. Case insensitive.
                Special-case roots are: Document, ComponentSet, and Component.

            nodetype[@name='<name>']
                Matches the name attribute within figma

        Examples:
            Document['<key>']/*[@name='Icons page']/*[@name='Icons']/componentSet/component
               1. Query lookup document with <key>
               2. Filter all child nodes of Document by looking at the name attribute
               3. Filter all child nodes (of pages) by looking at the name attribute
               4. Filter all child nodes based on type (component set)
               5. Filter all child nodes based on type (component)

            ComponentSet['<key>']/components[1]
               1. Query component set with key
               2. Filter all child nodes by type, and take the first

            Document['<key>']//*[@name='Special']/*
               1. Retrieve document with key
               2. find any node with the name 'Special'
               3. Take all of its child nodes
        """
    )
    var path: QueryPath

    func run() async throws {
        var compiler = FigmaQueryCompiler()
        let exec = try path.compile(&compiler)
        let session = FigmaSession(token: token)
        let nodes = try await exec(session)

        let buckets = Dictionary(grouping: nodes, by: { $0.file })

        if test {
            for (file, nodes) in buckets {
                print("Nodes in file \(file.rawValue):")
                for node in nodes {
                    print("Node")
                    print("  id: \(node.id)")
                    print("  type: \(node.nodeType.typeName)")
                    print("  name: \(node.name)")
                    print("  parent name: \(node.parent?.name ?? "<none>")")
                }
            }
            return
        }

        let urlSession = URLSession(configuration: .default)
        let outputPath = URL(filePath: FileManager.default.currentDirectoryPath)

        for (file, nodes) in buckets {
            let nodesByID = Dictionary(grouping: nodes, by: \.id).mapValues { $0[0] }
            let images = try await session.session.getFileImages(
                file,
                .init(
                    scale: scale,
                    ids: nodes.map { $0.location.node },
                    format: format,
                    svg_include_id: svgIncludeID,
                    svg_include_node_id: svgIncludeNodeID,
                    svg_simplify_stroke: svgSimplifyStroke,
                    use_absolute_bounds: useAbsoluteBounds
                )
            ).images

            for (id, url) in images {
                let node = nodesByID[id.rawValue]!
                let name = node.name
                let parentName = node.parent?.name ?? ""

                let path = "\(parentName)_\(name)".replacingOccurrences(of: "/", with: "_")

                let saveToURL = outputPath.appending(component: path).appendingPathExtension(format.rawValue)

                let (localURL, response) = try await urlSession.download(from: url)
                try FileManager.default.moveItem(at: localURL, to: saveToURL)
            }
        }
    }
}

// MARK: - QueryPath + ExpressibleByArgument

extension QueryPath: ExpressibleByArgument {
    public init?(argument: String) {
        try? self.init(argument)
    }
}

// MARK: - FigmaV1.SessionToken + ExpressibleByArgument

extension FigmaV1.SessionToken: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
}

// MARK: - FigmaV1.GetFileImages.Query.Format + ExpressibleByArgument

extension FigmaV1.GetFileImages.Query.Format: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}
