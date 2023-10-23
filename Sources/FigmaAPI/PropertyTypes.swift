import FigmaPullCore
import Foundation

extension FigmaV1 {
    public struct SessionToken: RawRepresentable, Codable {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct Color: Codable {
        public var r: Double
        public var g: Double
        public var b: Double
        public var a: Double
    }

    public struct ExportSetting: Codable {
        public var suffix: String
        public var format: ImageFormat
        public var constraint: Constraint
        public var svg_include_id: Bool?
        public var svg_simplify_stroke: Bool?
        public var use_absolute_bounds: Bool?

        public enum ImageFormat: String, Codable {
            case svg = "SVG"
            case jpg = "JPG"
            case png = "PNG"
        }
    }

    public struct Constraint: Codable {
        public var type: ConstraintType
        public var value: Double

        public enum ConstraintType: String, Codable {
            case scale = "SCALE"
            case width = "WIDTH"
            case height = "HEIGHT"
        }
    }

    public struct Rectangle: Codable {
        public var x: Double
        public var y: Double
        public var width: Double
        public var height: Double

        init(x: Double, y: Double, width: Double, height: Double) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<FigmaV1.Rectangle.CodingKeys> = try decoder
                .container(keyedBy: FigmaV1.Rectangle.CodingKeys.self)
            self.x = try container.decodeIfPresent(Double.self, forKey: FigmaV1.Rectangle.CodingKeys.x) ?? 0
            self.y = try container.decodeIfPresent(Double.self, forKey: FigmaV1.Rectangle.CodingKeys.y) ?? 0
            self.width = try container.decodeIfPresent(Double.self, forKey: FigmaV1.Rectangle.CodingKeys.width) ?? 0
            self.height = try container.decodeIfPresent(Double.self, forKey: FigmaV1.Rectangle.CodingKeys.height) ?? 0
        }
    }

    public struct ArcData: Codable {
        public var startingAngle: Double
        public var endingAngle: Double
        public var innerRadiius: Double
    }

    public enum BlendMode: String, Codable {
        case passThrough = "PASS_THROUGH"
        case normal = "NORMAL"
        case darken = "DARKEN"
        case multiply = "MULTIPLY"
        case linearBurn = "LINEAR_BURN"
        case colorBurn = "COLOR_BURN"
        case lighten = "LIGHTEN"
        case screen = "SCREEN"
        case linearDodge = "LINEAR_DODGE"
        case colorDodge = "COLOR_DODGE"
        case overlay = "OVERLAY"
        case softLight = "SOFT_LIGHT"
        case hardLight = "HARD_LIGHT"
        case difference = "DIFFERENCE"
        case exclusion = "EXCLUSION"
        case hue = "HUE"
        case saturation = "SATURATION"
        case color = "COLOR"
        case luminosity = "LUMINOSITY"
    }

    public enum EasingType: String, Codable {
        case easeIn = "EASE_IN"
        case easeOut = "EASE_OUT"
        case easeInAndOut = "EASE_IN_AND_OUT"
        case linear = "LINEAR"
        case gentleSpring = "GENTLE_SPRING"
    }

    public struct FlowStartingPoint: Codable {
        public var nodeID: String
        public var name: String

        enum CodingKeys: String, CodingKey {
            case nodeID = "nodeId"
            case name
        }
    }

    public struct LayoutConstraint: Codable {
        public var vertical: Vertical
        public var horizontal: Horizontal

        public enum Vertical: String, Codable {
            case top = "TOP"
            case bottom = "BOTTOM"
            case center = "CENTER"
            case topBottom = "TOP_BOTTOM"
            case scale = "SCALE"
        }

        public enum Horizontal: String, Codable {
            case left = "LEFT"
            case right = "RIGHT"
            case center = "CENTER"
            case leftRight = "LEFT_RIGHT"
            case scale = "SCALE"
        }
    }

    // LayoutGrid
    // Effect

    public enum Hyperlink: Codable {
        case url(String)
        case node(String)

        public init(from decoder: Decoder) throws {
            let raw = try RawHyperlink(from: decoder)
            switch raw.type {
            case "URL":
                self = .url(raw.url!)
            case "NODE":
                self = .node(raw.nodeID!)
            default:
                preconditionFailure()
            }
        }

        private struct RawHyperlink: Codable {
            public var type: String
            public var url: String?
            public var nodeID: String?
        }
    }

    public struct DocumentationLink: Codable {
        public var url: String
    }

    public struct Paint: Codable {
        public var type: PaintType
        @CodableDefault<Default.True> public var visible: Bool
        @CodableDefault<Default.One> public var opacity: Double
        public var color: Color?
        public var blendMode: BlendMode
//        gradientHandlePositionsVector[]
        // gradientStopsColorStop[]
//        public var scaleMode: ScaleMode
//        public var imageTransform: Transform
//        public var rotation: Double
//        public var imageRef: String
        // filters
//        public var gifRef: String
    }

    public enum PaintType: String, Codable, Hashable {
        case solid = "SOLID"
        case linearGradient = "GRADIENT_LINEAR"
        case radialGradient = "GRADIENT_RADIAL"
        case angularGradient = "GRADIENT_ANGULAR"
        case diamondGradient = "GRADIENT_DIAMOND"
        case image = "IMAGE"
        case emoji = "EMOJI"
        case video = "VIDEO"
    }

    public struct Vector: Codable {
        public var x: Double
        public var y: Double
    }

    public struct Size: Codable {
        public var width: Double
        public var height: Double
    }

    public struct Transform: Codable {
        public var rawValue: [[Double]]

        init(rawValue: [[Double]]) {
            self.rawValue = rawValue
        }

        public init(from decoder: Decoder) throws {
            try self.init(rawValue: .init(from: decoder))
        }

        public func encode(to encoder: Encoder) throws {
            try rawValue.encode(to: encoder)
        }
    }

    // ImageFilters

    // FrameOffset

    // ColorStop

    // PaintOverride

    // TypeStyle

    // MARK: - Component

    public struct Component: Codable {
        public var key: ComponentKey
        public var name: ComponentName
        public var componentDescription: String
        public var componentSetID: ComponentSetID?
        public var documentationLinks: [DocumentationLink]

        enum CodingKeys: String, CodingKey {
            case key = "key"
            case name = "name"
            case componentDescription = "description"
            case componentSetID = "componentSetId"
            case documentationLinks = "documentationLinks"
        }
    }

    public struct ComponentName {
        public var properties: [Substring: String]
    }

    public struct ComponentSet: Codable {
        public var key: ComponentSetKey
        public var fileKey: FileKey?
        public var nodeID: NodeID?
        public var thumbnailURL: URL?
        public var name: String
        public var description: String
        public var createdAt: Date?
        public var updatedAt: Date?
        public var containingFrame: FrameInfo?
        public var user: User?

        enum CodingKeys: String, CodingKey {
            case key = "key"
            case fileKey = "file_key"
            case nodeID = "node_id"
            case thumbnailURL = "thumbnail_url"
            case name = "name"
            case description = "description"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case containingFrame = "containing_frame"
            case user = "user"
        }
    }

    public struct Style: Codable {
        public var key: StyleKey
        public var name: String
        public var fileKey: FileKey?
        public var nodeID: NodeID?
        public var styleType: StyleType?
        public var thumbnailURL: URL?
        public var remote: Bool?
        public var styleDescription: String?

        enum CodingKeys: String, CodingKey {
            case key
            case name
            case fileKey = "file_key"
            case nodeID = "node_id"
            case styleType = "style_type"
            case thumbnailURL = "thumbnail_url"
            case remote
            case styleDescription = "description"
        }
    }

    public enum StyleType: String, Codable {
        case fill = "FILL"
        case text = "TEXT"
        case effect = "EFFECT"
        case grid = "GRID"
    }

    public enum ShapeType: String, Codable {
        case square = "SQUARE"
        case ellipse = "ELLIPSE"
        case roundedRectangle = "ROUNDED_RECTANGLE"
        case diamond = "DIAMOND"
        case triangleDown = "TRIANGLE_DOWN"
        case parallelogramRight = "PARALLELOGRAM_RIGHT"
        case parallelogramLeft = "PARALLELOGRAM_LEFT"
    }

    // ConnectorEndpoint
    // ConnectorLineType
    // ConnectorTextBackground

    public enum ComponentPropertyType: String, Codable {
        case boolean = "BOOLEAN"
        case instanceSwap = "INSTANCE_SWAP"
        case text = "TEXT"
        case variant = "VARIANT"
    }

    public enum ComponentValue: Codable {
        case string(String)
        case bool(Bool)

        public init(from decoder: Decoder) throws {
            if let value = try? Bool(from: decoder) {
                self = .bool(value)
            } else {
                self = try .string(String(from: decoder))
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .string(let value): try value.encode(to: encoder)
            case .bool(let value): try value.encode(to: encoder)
            }
        }
    }

    public struct InstanceSwapPreferredValue: Codable {
        public var type: PreferredType
        public var key: String

        public enum PreferredType: String, Codable {
            case component = "COMPONENT"
            case componentSet = "COMPONENT_SET"
        }
    }

    public struct ComponentPropertyDefinition: Codable {
        public var type: ComponentPropertyType
        public var defaultValue: ComponentValue
        public var variantOptions: [String]?
        public var preferredValues: [InstanceSwapPreferredValue]?
    }

    public struct ComponentProperty: Codable {
        public var type: ComponentPropertyType
        public var value: ComponentValue
        public var preferredValues: [InstanceSwapPreferredValue]?
    }

    // MARK: inferred

    public struct Path: Codable {
        public var operations: [Operation]
        public var windingRule: WindingRule

        public enum WindingRule: String, Codable {
            case nonZero = "NONZERO"
            case evenOdd = "EVENODD"
        }

        enum CodingKeys: String, CodingKey {
            case windingRule
            case path
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let path = try container.decode(String.self, forKey: .path)
            let windingRule = try container.decode(WindingRule.self, forKey: .windingRule)

            operations = Self.parse(path)
            self.windingRule = windingRule
        }

        public func encode(to encoder: Encoder) throws {
            preconditionFailure()
        }

        public enum Operation {
            case move(to: Vector)
            case line(to: Vector)
            case curve(to: Vector, controlPoint1: Vector, controlPoint2: Vector)
            case close

            public func suiCode(_ width: Double, _ height: Double) -> String {
                func vectorString(_ vector: Vector) -> String {
                    return ".init(x: \(vector.x / width) * proxy.size.width, y: \(vector.y / height) * proxy.size.height)"
                }

                switch self {
                case .move(to: let vector):
                    return "$0.move(to: \(vectorString(vector)))"

                case .line(to: let vector):
                    return "$0.addLine(to: \(vectorString(vector)))"

                case .curve(to: let pt, controlPoint1: let c1, controlPoint2: let c2):
                    return "$0.addCurve(to: \(vectorString(pt)), control1: \(vectorString(c1)), control2: \(vectorString(c2)))"

                case .close:
                    return "$0.closeSubpath()"
                }
            }
        }
    }

    public enum LineHeightUnit: String, Codable {
        case fontSize = "FONT_SIZE_%"
        case intrinsic = "INTRINSIC_%"
        case pixels = "PIXELS"
    }

    public enum TextAutoResize: String, Codable {
        case height = "HEIGHT"
        case widthAndHeight = "WIDTH_AND_HEIGHT"
    }

    public enum ScaleMode: String, Codable {
        case fill = "FILL"
        case fit = "FIT"
        case tile = "TILE"
        case stretch = "STRETCH"
    }

    public enum LayoutAlign: String, Codable {
        case center = "CENTER"
        case inherit = "INHERIT"
        case stretch = "STRETCH"
    }

    public enum Rotation: String, Codable {
        case none = "NONE"
        case ordered = "ORDERED"
        case unordered = "UNORDERED"
    }

    public enum StrokeAlign: String, Codable {
        case center = "CENTER"
        case inside = "INSIDE"
        case outside = "OUTSIDE"
    }

    public enum StrokeCap: String, Codable {
        case none = "NONE"
        case round = "ROUND"
        case square = "SQUARE"
        case lineArrow = "LINE_ARROW"
        case triangleArrow = "TRIANGLE_ARROW"
    }

    public enum StrokeJoin: String, Codable {
        case miter = "MITER"
        case bevel = "BEVEL"
        case round = "ROUND"
    }

    public enum SizingMode: String, Codable {
        case fixed = "FIXED"
        case auto = "AUTO"
    }

    public enum LayoutMode: String, Codable {
        case none = "NONE"
        case horizontal = "HORIZONTAL"
        case vertical = "VERTICAL"
    }

    public enum EffectType: String, Codable {
        case dropShadow = "DROP_SHADOW"
        case innerShadow = "INNER_SHADOW"
        case layerBlur = "LAYER_BLUR"
    }

    public enum PrimaryAxisAlignItems: String, Codable {
        case center = "CENTER"
        case leftRight = "LEFT_RIGHT"
        case primaryAxisAlignItemsLEFT = "LEFT"
        case primaryAxisAlignItemsRIGHT = "RIGHT"
        case scale = "SCALE"
    }

    public enum AxisAlignItems: String, Codable {
        case center = "CENTER"
        case max = "MAX"
        case spaceBetween = "SPACE_BETWEEN"
    }

    public enum ScrollBehavior: String, Codable {
        case fixed = "FIXED"
        case scrolls = "SCROLLS"
    }

    public struct CornerRadii: Codable {
        public var topLeft: Double
        public var topRight: Double
        public var bottomRight: Double
        public var bottomLeft: Double

        public init(topLeft: Double, topRight: Double, bottomRight: Double, bottomLeft: Double) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomRight = bottomRight
            self.bottomLeft = bottomLeft
        }

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.topLeft = try container.decode(Double.self)
            self.topRight = try container.decode(Double.self)
            self.bottomRight = try container.decode(Double.self)
            self.bottomLeft = try container.decode(Double.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(self.topLeft)
            try container.encode(self.topRight)
            try container.encode(self.bottomRight)
            try container.encode(self.bottomLeft)
        }
    }

    public struct Styles: Codable {
        public var fill: String?
        public var text: String?
        public var effect: String?
        public var grid: String?
    }
}

extension KeyedDecodingContainer {
    public func decode(
        _ type: FigmaV1.Styles.Type,
        forKey key: Key
    ) throws -> FigmaV1.Styles {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}

// MARK: - FigmaV1.ComponentName + Codable

extension FigmaV1.ComponentName: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        let keyValuePairStrings = rawValue.split(separator: ", ")
        let keyValuePairs = keyValuePairStrings.map {
            let pieces = $0.split(separator: "=", maxSplits: 1)
            if pieces.count == 1 {
                return (pieces[0], "")
            } else {
                return (pieces[0], String(pieces[1]))
            }
        }

        let props = Dictionary(uniqueKeysWithValues: keyValuePairs)
        self.init(properties: props)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let pieces = self.properties
            .map {
            "\($0)=\($1)"
        }.joined(separator: ", ")
    }
}
