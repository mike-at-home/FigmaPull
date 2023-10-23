import Foundation
extension FigmaV1 {
    @propertyWrapper
    public struct Node: Codable {
        public var wrappedValue: Nodes.Node

        public init(wrappedValue: Nodes.Node) {
            self.wrappedValue = wrappedValue
        }

        public init(from decoder: Decoder) throws {
            try self.init(wrappedValue: WrappedNode(from: decoder).node)
        }

        public func encode(to encoder: Encoder) throws {
            try WrappedNode(node: wrappedValue).encode(to: encoder)
        }
    }

    @propertyWrapper
    public struct NodeArray: Codable {
        public var wrappedValue: [Nodes.Node]

        public init(wrappedValue: [Nodes.Node]) {
            self.wrappedValue = wrappedValue
        }

        public init(from decoder: Decoder) throws {
            var result: [Nodes.Node] = []
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                try result.append(container.decode(WrappedNode.self).node)
            }

            self.init(wrappedValue: result)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            for n in wrappedValue {
                try container.encode(WrappedNode(node: n))
            }
        }
    }

    public enum Nodes {
        fileprivate static let nodeTypeMap: [String: FigmaV1.Nodes.Node.Type] = FigmaV1.Nodes.nodeTypes.reduce(into: [:]) {
            $0[$1.typeName] = $1
        }

        public static let nodeTypes: [Node.Type] = [
            Nodes.Document.self,
            Nodes.Canvas.self,
            Nodes.Frame.self,
            Nodes.Group.self,
            Nodes.Vector.self,
            Nodes.BooleanOperation.self,
            Nodes.Star.self,
            Nodes.Line.self,
            Nodes.Ellipse.self,
            Nodes.RegularPolygon.self,
            Nodes.Rectangle.self,
            Nodes.Text.self,
            Nodes.Slice.self,
            Nodes.Component.self,
            Nodes.ComponentSet.self,
            Nodes.Instance.self
        ]

        public class Node: Codable {
            public class var typeName: String { preconditionFailure() }

            public var id: String
            public var name: String
            public var type: String
            public var visible: Bool

            public required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                id = properties.id
                name = properties.name
                type = properties.type
                visible = properties.visible ?? true
            }

            public func encode(to encoder: Encoder) throws {
                preconditionFailure()
            }

            public struct Properties: Codable {
                public var id: String
                public var name: String
                public var type: String
                public var visible: Bool?
                // pluginData
                // sharedPluginData
                // componentPropertyReferences
            }
        }

        public class Document: Node, FigmaContainerNode {
            override public class var typeName: String { "DOCUMENT" }
            public var children: [Node]

            public struct Properties: Codable {
                @NodeArray public var children: [Nodes.Node]
            }

            public required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.children = properties.children
                try super.init(from: decoder)
            }
        }

        public class Canvas: Node, FigmaContainerNode {
            override public class var typeName: String { "CANVAS" }
            public var children: [Node]
            public var backgroundColor: Color
            public var flowStartingPoints: [FlowStartingPoint]
            public var exportSettings: [ExportSetting]

            public required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.children = properties.children
                self.backgroundColor = properties.backgroundColor
                self.flowStartingPoints = properties.flowStartingPoints
                self.exportSettings = properties.exportSettings ?? []
                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                @NodeArray public var children: [Nodes.Node]
                public var backgroundColor: Color
                public var flowStartingPoints: [FlowStartingPoint]
                public var exportSettings: [ExportSetting]?
            }
        }

        public class FrameBase: Node, FigmaContainerNode {
            public var locked: Bool
            public var children: [Node]
            public var fills: [Paint]
            public var strokes: [Paint]
            public var strokeWeight: Double
            public var strokeAlign: StrokeAlign
            public var cornerRadius: Double
            public var rectangleCornerRadii: CornerRadii
            public var exportSettings: [ExportSetting]
            public var blendMode: BlendMode
            public var preserveRatio: Bool
            public var constraints: LayoutConstraint?
            public var layoutAlign: LayoutAlign?
            public var transitionNodeID: String?
            public var transitionDuration: Double?
            public var transitionEasining: EasingType?
            public var opacity: Double
            public var absoluteBoundingBox: FigmaV1.Rectangle
            public var absoluteRenderBounds: FigmaV1.Rectangle
            public var size: FigmaV1.Vector
            public var relativeTransform: Transform
            public var clipsContent: Bool
            public var layoutMode: LayoutMode?
            public var primaryAxisSizingMode: SizingMode?
            public var counterAxisSizingMode: SizingMode?
            public var primaryAxisAlignItems: PrimaryAxisAlignItems?
            public var counterAxisAlignItems: AxisAlignItems?
            public var paddingLeft: Double
            public var paddingRight: Double
            public var paddingTop: Double
            public var paddingBottom: Double
            public var horizontalPadding: Double
            public var verticalPadding: Double
            public var itemSpacing: Double
            //            public var layoutGrids: LayoutGrid
            //            public var overflowDirection: OverflowDirection
            //            public var effects: [Effect]
            public var isMask: Bool
            public var isMaskOutline: Bool

            public required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.children = properties.children
                self.locked = properties.locked ?? false
                self.fills = properties.fills
                self.strokes = properties.strokes
                self.strokeWeight = properties.strokeWeight
                self.strokeAlign = properties.strokeAlign
                self.cornerRadius = properties.cornerRadius ?? 0
                self.rectangleCornerRadii = properties.rectangleCornerRadii
                self.exportSettings = properties.exportSettings ?? []
                self.blendMode = properties.blendMode ?? .passThrough
                self.preserveRatio = properties.preserveRatio ?? false
                self.constraints = properties.constraints
                self.layoutAlign = properties.layoutAlign
                self.transitionNodeID = properties.transitionNodeID
                self.transitionDuration = properties.transitionDuration
                self.transitionEasining = properties.transitionEasining
                self.opacity = properties.opacity ?? 1
                self.absoluteBoundingBox = properties.absoluteBoundingBox
                self.absoluteRenderBounds = properties.absoluteRenderBounds
                self.size = properties.size
                self.relativeTransform = properties.relativeTransform
                self.clipsContent = properties.clipsContent
                self.layoutMode = properties.layoutMode
                self.primaryAxisSizingMode = properties.primaryAxisSizingMode
                self.counterAxisSizingMode = properties.counterAxisSizingMode
                self.primaryAxisAlignItems = properties.primaryAxisAlignItems
                self.counterAxisAlignItems = properties.counterAxisAlignItems
                self.paddingLeft = properties.paddingLeft ?? 0
                self.paddingRight = properties.paddingRight ?? 0
                self.paddingTop = properties.paddingTop ?? 0
                self.paddingBottom = properties.paddingBottom ?? 0
                self.horizontalPadding = properties.horizontalPadding ?? 0
                self.verticalPadding = properties.verticalPadding ?? 0
                self.itemSpacing = properties.itemSpacing ?? 0
                self.isMask = properties.isMask ?? false
                self.isMaskOutline = properties.isMaskOutline ?? false

                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                @NodeArray public var children: [Nodes.Node]
                public var locked: Bool?
                public var fills: [Paint]
                public var strokes: [Paint]
                public var strokeWeight: Double
                public var strokeAlign: StrokeAlign
                public var cornerRadius: Double?
                public var rectangleCornerRadii: CornerRadii
                public var exportSettings: [ExportSetting]?
                public var blendMode: BlendMode?
                public var preserveRatio: Bool?
                public var constraints: LayoutConstraint?
                public var layoutAlign: LayoutAlign?
                public var transitionNodeID: String?
                public var transitionDuration: Double?
                public var transitionEasining: EasingType?
                public var opacity: Double?
                public var absoluteBoundingBox: FigmaV1.Rectangle
                public var absoluteRenderBounds: FigmaV1.Rectangle
                public var size: FigmaV1.Vector
                public var relativeTransform: Transform
                public var clipsContent: Bool
                public var layoutMode: LayoutMode?
                public var primaryAxisSizingMode: SizingMode?
                public var counterAxisSizingMode: SizingMode?
                public var primaryAxisAlignItems: PrimaryAxisAlignItems?
                public var counterAxisAlignItems: AxisAlignItems?
                public var paddingLeft: Double?
                public var paddingRight: Double?
                public var paddingTop: Double?
                public var paddingBottom: Double?
                public var horizontalPadding: Double?
                public var verticalPadding: Double?
                public var itemSpacing: Double?
                //            public var layoutGrids: LayoutGrid
                //            public var overflowDirection: OverflowDirection
                //            public var effects: [Effect]
                public var isMask: Bool?
                public var isMaskOutline: Bool?
            }
        }

        public class Frame: FrameBase {
            override public class var typeName: String { "FRAME" }
        }

        public class Group: FrameBase {
            override public class var typeName: String { "GROUP" }
        }

        public class VectorBase: Node {
            public var locked: Bool
            public var exportSettings: [ExportSetting]
            public var blendMode: BlendMode
            public var preserveRatio: Bool
            // autolayout only
            public var layoutAlign: LayoutAlign?
            public var layoutGrow: Double

            public var constraints: LayoutConstraint?
            public var transitionNodeID: String?
            public var transitionDuration: Double?
            public var transitionEasing: EasingType?
            public var opacity: Double
            public var absoluteBoundingBox: FigmaV1.Rectangle
            public var absoluteRenderBounds: FigmaV1.Rectangle
//                public var effects: [Effect]
            public var size: FigmaV1.Vector
            public var relativeTransform: Transform
            public var isMask: Bool
            public var fills: [Paint]
            public var fillGeometry: [Path]
            //                public var fillOverrideTable: [Double: PaintOverride]?
            public var strokes: [Paint]
            public var strokeWeight: Double
            public var strokeCap: StrokeCap?
            public var strokeJoin: StrokeJoin
            public var strokeDashes: [Double]
            public var strokeMiterAngle: Double
            public var strokeGeometry: [Path]
            public var strokeAlign: StrokeAlign
            public var styles: Styles

            public required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.locked = properties.locked ?? false
                self.exportSettings = properties.exportSettings ?? []
                self.blendMode = properties.blendMode ?? .normal
                self.preserveRatio = properties.preserveRatio ?? false
                self.layoutAlign = properties.layoutAlign
                self.layoutGrow = properties.layoutGrow ?? 0
                self.constraints = properties.constraints
                self.transitionNodeID = properties.transitionNodeID
                self.transitionDuration = properties.transitionDuration
                self.transitionEasing = properties.transitionEasing
                self.opacity = properties.opacity ?? 1
                self.absoluteBoundingBox = properties.absoluteBoundingBox
                self.absoluteRenderBounds = properties.absoluteRenderBounds
                self.size = properties.size
                self.relativeTransform = properties.relativeTransform
                self.isMask = properties.isMask ?? false
                self.fills = properties.fills ?? []
                self.fillGeometry = properties.fillGeometry ?? []
                self.strokes = properties.strokes ?? []
                self.strokeWeight = properties.strokeWeight
                self.strokeCap = properties.strokeCap
                self.strokeJoin = properties.strokeJoin ?? .miter
                self.strokeDashes = properties.strokeDashes ?? []
                self.strokeMiterAngle = properties.strokeMiterAngle ?? 20.89
                self.strokeGeometry = properties.strokeGeometry ?? []
                self.strokeAlign = properties.strokeAlign
                self.styles = properties.styles
                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                public var locked: Bool?
                public var exportSettings: [ExportSetting]?
                public var blendMode: BlendMode?
                public var preserveRatio: Bool?
                // autolayout only
                public var layoutAlign: LayoutAlign?
                public var layoutGrow: Double?

                public var constraints: LayoutConstraint?
                public var transitionNodeID: String?
                public var transitionDuration: Double?
                public var transitionEasing: EasingType?
                public var opacity: Double?
                public var absoluteBoundingBox: FigmaV1.Rectangle
                public var absoluteRenderBounds: FigmaV1.Rectangle
//                public var effects: [Effect]
                public var size: FigmaV1.Vector
                public var relativeTransform: Transform
                public var isMask: Bool?
                public var fills: [Paint]?
                public var fillGeometry: [Path]?
                //                public var fillOverrideTable: [Double: PaintOverride]?
                public var strokes: [Paint]?
                public var strokeWeight: Double
                public var strokeCap: StrokeCap?
                public var strokeJoin: StrokeJoin?
                public var strokeDashes: [Double]?
                public var strokeMiterAngle: Double?
                public var strokeGeometry: [Path]?
                public var strokeAlign: StrokeAlign
                public var styles: Styles
            }
        }

        public class Vector: VectorBase {
            override public class var typeName: String { "VECTOR" }
        }

        public class BooleanOperation: VectorBase, FigmaContainerNode {
            override public class var typeName: String { "BOOLEAN_OPERATION" }

            public var children: [Nodes.Node]
            public var booleanOperation: Operation

            public required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.children = properties.children
                self.booleanOperation = properties.booleanOperation

                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                @NodeArray public var children: [Nodes.Node]
                public var booleanOperation: Operation
            }

            public enum Operation: String, Codable {
                case union = "UNION"
                case intersection = "INTERSECT"
                case subtract = "SUBTRACT"
                case exclude = "EXCLUDE"
            }
        }

        public class Star: VectorBase {
            override public class var typeName: String { "STAR" }
        }

        public class Line: VectorBase {
            override public class var typeName: String { "LINE" }
        }

        public class Ellipse: VectorBase {
            override public class var typeName: String { "ELLIPSE" }

            public struct Properties: Codable {}
        }

        public class RegularPolygon: VectorBase {
            override public class var typeName: String { "REGULAR_POLYGON" }
        }

        public class Rectangle: VectorBase {
            override public class var typeName: String { "RECTANGLE" }

            public struct Properties: Codable {}

            public required init(from decoder: Decoder) throws {
//                let properties = try Properties(from: decoder)
                try super.init(from: decoder)
            }
        }

        public class Text: VectorBase {
            override public class var typeName: String { "TEXT" }

            public struct Properties: Codable {}
        }

        public class Slice: Node {
            override public class var typeName: String { "SLICE" }

            public struct Properties: Codable {}
        }

        public class Component: FrameBase {
            override public class var typeName: String { "COMPONENT" }
            public var componentPropertyDefinitions: [String: FigmaV1.ComponentPropertyDefinition]

            required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.componentPropertyDefinitions = properties.componentPropertyDefinitions ?? [:]
                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                public var componentPropertyDefinitions: [String: FigmaV1.ComponentPropertyDefinition]?
            }
        }

        public class ComponentSet: FrameBase {
            override public class var typeName: String { "COMPONENT_SET" }
            public var componentPropertyDefinitions: [String: FigmaV1.ComponentPropertyDefinition]

            required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.componentPropertyDefinitions = properties.componentPropertyDefinitions ?? [:]
                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                public var componentPropertyDefinitions: [String: FigmaV1.ComponentPropertyDefinition]?
            }
        }

        public class Instance: FrameBase {
            override public class var typeName: String { "INSTANCE" }
            public var componentID: String
            public var isExposedInstance: Bool
            public var exposedInstances: [String]
            public var componentProperties: [String: FigmaV1.ComponentProperty]

            required init(from decoder: Decoder) throws {
                let properties = try Properties(from: decoder)
                self.componentID = properties.componentID
                self.isExposedInstance = properties.isExposedInstance ?? false
                self.exposedInstances = properties.exposedInstances ?? []
                self.componentProperties = properties.componentProperties ?? [:]
                try super.init(from: decoder)
            }

            public struct Properties: Codable {
                public var componentID: String
                public var isExposedInstance: Bool?
                public var exposedInstances: [String]?
                public var componentProperties: [String: FigmaV1.ComponentProperty]?

                enum CodingKeys: String, CodingKey {
                    case componentID = "componentId"
                    case isExposedInstance
                    case exposedInstances
                    case componentProperties
                }
            }
        }
    }
}

// MARK: - WrappedNode

private struct WrappedNode: Codable {
    public var node: FigmaV1.Nodes.Node

    private struct Peek: Codable {
        public var typeName: String

        enum CodingKeys: String, CodingKey {
            case typeName = "type"
        }
    }

    init(node: FigmaV1.Nodes.Node) {
        self.node = node
    }

    init(from decoder: Decoder) throws {
        let typeName = try Peek(from: decoder).typeName

        let nodeInstanceType: FigmaV1.Nodes.Node.Type
        if let nodeType = FigmaV1.Nodes.nodeTypeMap[typeName] {
            nodeInstanceType = nodeType

        } else {
            nodeInstanceType = FigmaV1.Nodes.Node.self
        }

        try self.init(node: nodeInstanceType.init(from: decoder))
    }

    func encode(to encoder: Encoder) throws {
        try node.encode(to: encoder)
    }


}

// MARK: - FigmaContainerNode

public protocol FigmaContainerNode: FigmaV1.Nodes.Node {
    var children: [FigmaV1.Nodes.Node] { get }
}

extension FigmaV1.Nodes.Node {
    public func lazyAncestorsBreadthFirst() -> AnySequence<FigmaV1.Nodes.Node> {
        let startIter = AnySequence(_children).makeIterator()

        return .init(sequence(state: (startIter, [AnySequence<FigmaV1.Nodes.Node>]()), next: { state in
            while true {
                if let next = state.0.next() {
                    return next
                }

                if state.1.isEmpty { return nil }

                state.0 = state.1.removeFirst().makeIterator()

                if let next = state.0.next() {
                    return next
                }
            }
        }))
    }

    public var _children: [FigmaV1.Nodes.Node] {
        (self as? FigmaContainerNode)?.children ?? []
    }

    public func descendants() -> [FigmaV1.Nodes.Node] {
        if let container = self as? FigmaContainerNode {
            return container.children.flatMap { $0.descendantsAndSelf() }
        } else {
            return []
        }
    }

    public func descendantsAndSelf() -> [FigmaV1.Nodes.Node] {
        if let container = self as? FigmaContainerNode {
            return container.children.flatMap { $0.descendantsAndSelf() } + [self]
        } else {
            return [self]
        }
    }

    public func allFillStyles() -> [String] {
        self.descendantsAndSelf().compactMap { $0 as? FigmaV1.Nodes.VectorBase }.compactMap { $0.styles.fill }
    }
}
