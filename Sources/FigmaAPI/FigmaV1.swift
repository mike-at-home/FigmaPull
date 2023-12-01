import FigmaPullCore
import Foundation

// MARK: - FigmaV1

public struct FigmaV1: URLSessionAPI {
    public var getTeamProjects: GetTeamProjects
//    public var getFile: GetFile
    public var getFileNodes: GetFileNodes
    public var getFileImages: GetFileImages
    public var getFileComponentSets: GetFileComponentSets
    public var getComponentSet: GetComponentSet
    public var getStyle: GetStyle
    public var getFileStyles: GetFileStyles

    public enum GetTeamProjects: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "teams/\(\.self)/projects"

        public typealias Path = TeamID

        public struct Response: Codable {
            public var name: String
            public var projects: [Project]
        }
    }

    public enum GetProjectFiles: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "projects/\(\.self)/files"

        public typealias Path = ProjectID

        public struct Response: Codable {
            public var name: String
            public var files: [File]
        }
    }

    public enum GetComponentSet: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "component_sets/\(\.self)"
        public typealias Path = ComponentSetKey

        public typealias Response = GeneralResponse<ComponentSet>
    }

    public enum GetDevToken: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "user/dev_tokens"
        public typealias Path = Never

        public typealias Response = GeneralResponse<DevTokenPayload>

        public struct DevTokenPayload: Codable {
            var id: String
            var description: String
            var token: SessionToken
        }
    }

    public enum GetStyle: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "styles/\(\.self)"
        public typealias Path = StyleKey

        public typealias Response = GeneralResponse<Style>
    }

//    public enum GetFile: FigmaV1Service {
//        public static let pathTemplate: StringTemplate<Path> = "files/\(\.key)"
//
//        public struct Path: Codable {
//            public var key: String
//        }
//
//        public struct Query: Codable {
//            public var version: String?
//            public var ids: [String]?
//            public var depth: Int?
//            public var geometry: String?
//            public var plugin_data: [String]?
//            public var branch_data: Bool?
//        }
//
    ////        public struct Response: Codable {
    ////            public var document: Document
    ////            public var components: Components
    ////            public var componentSets: ComponentSets
    ////            public var schemaVersion: Int
    ////            public var styles: FigmaStyles
    ////            public var name: String
    ////            public var lastModified: Date
    ////            public var thumbnailUrl: String
    ////            public var version: String
    ////            public var role: String
    ////            public var editorType: String
    ////            public var linkAccess: String
    ////        }
//    }

    public enum GetFileNodes: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "files/\(\.self)/nodes"

        public typealias Path = FileKey

        public struct Query: Codable {
            public var version: String?
            public var ids: [NodeID]
            public var depth: Int?
            public var geometry: String?
            public var plugin_data: [String]?
            public var branch_data: Bool?
        }

        public struct Response: Codable {
            public var name: String
            public var lastModified: Date
            public var thumbnailURL: URL
            public var version: String
            public var role: String
            public var editorType: String
            public var linkAccess: String
            @DictionaryCodable public var nodes: [NodeID: QueriedNode]

            enum CodingKeys: String, CodingKey {
                case name = "name"
                case lastModified = "lastModified"
                case thumbnailURL = "thumbnailUrl"
                case version = "version"
                case role = "role"
                case editorType = "editorType"
                case linkAccess = "linkAccess"
                case nodes = "nodes"
            }
        }
    }

    public enum GetFileImages: FigmaV1Service {
        public static let pathTemplate: StringTemplate<Path> = "images/\(\.self)"

        public typealias Path = FileKey

        public struct Query: Codable {
            public var scale: Double?
            public var ids: [NodeID]
            public var format: Format?
            public var svg_include_id: Bool?
            public var svg_include_node_id: Bool?
            public var svg_simplify_stroke: Bool?
            public var use_absolute_bounds: Bool?

            public enum Format: String, Codable {
                case jpg
                case png
                case svg
                case pdf
            }

            public init(
                scale: Double? = nil,
                ids: [NodeID],
                format: Format? = nil,
                svg_include_id: Bool? = nil,
                svg_include_node_id: Bool? = nil,
                svg_simplify_stroke: Bool? = nil,
                use_absolute_bounds: Bool? = nil
            ) {
                self.scale = scale
                self.ids = ids
                self.format = format
                self.svg_include_id = svg_include_id
                self.svg_include_node_id = svg_include_node_id
                self.svg_simplify_stroke = svg_simplify_stroke
                self.use_absolute_bounds = use_absolute_bounds
            }
        }

        public struct Response: Codable {
            public var status: Int?
            public var err: String?
            @CustomKeys public var images: [NodeID: URL]
        }
    }

    public enum GetFileComponentSets: FigmaV1ArrayService {
        public typealias ResultElementType = ComponentSet
        public static var elementNodeKey: String = "component_sets"

        public static let pathTemplate: StringTemplate<Path> = "files/\(\.self)/component_sets"

        public typealias Path = FileKey
        public typealias Response = GeneralResponse<UnpagedArrayResult<Self>>
    }

    public enum GetFileStyles: FigmaV1ArrayService {
        public typealias ResultElementType = Style
        public static var elementNodeKey: String = "styles"

        public static let pathTemplate: StringTemplate<Path> = "files/\(\.self)/styles"

        public typealias Path = FileKey
        public typealias Response = GeneralResponse<UnpagedArrayResult<Self>>
    }

    public struct QueriedNode: Codable {
        @Node public var document: Nodes.Node
        @CustomKeys public var components: [ComponentID: Component]
        @CustomKeys public var componentSets: [ComponentSetID: ComponentSet]
        public var schemaVersion: Int
        @CustomKeys public var styles: [StyleID: Style]
    }

    public struct Project: Codable {
        public var id: ProjectID
        public var name: String
    }

    public struct File: Codable {
        public var key: FileKey
        public var name: String
        public var thumbnailURL: URL?
        public var lastModified: Date

        enum CodingKeys: String, CodingKey {
            case key
            case name
            case thumbnailURL = "thumbnail_url"
            case lastModified = "last_modified"
        }
    }

    public struct GeneralResponse<ObjectType: Codable>: Codable {
        public var status: Int
        public var error: Bool
        public var result: ObjectType

        enum CodingKeys: String, CodingKey {
            case status
            case error
            case result = "meta"
        }
    }

    public struct UnpagedArrayResult<Service: FigmaV1ArrayService>: Codable {
        public var elements: [Service.ResultElementType]

        enum CodingKeys: RawRepresentable, CodingKey {
            case elements

            public init?(rawValue: String) {
                if rawValue == Service.elementNodeKey {
                    self = .elements
                }
                return nil
            }

            public var rawValue: String {
                Service.elementNodeKey
            }
        }
    }

    public struct Cursor<Service>: Codable {
        public var before: CursorID<Service>?
        public var after: CursorID<Service>?
    }

    public struct CursorID<Service>: RawRepresentable, Codable {
        public var rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public struct PagedArrayResult<Service: FigmaV1ArrayService>: Codable {
        public var elements: [Service.ResultElementType]
        public var cursor: Cursor<Service>

        enum CodingKeys: RawRepresentable, CodingKey {
            case elements
            case cursor

            public init?(rawValue: String) {
                switch rawValue {
                case Service.elementNodeKey: self = .elements
                case "cursor": self = .cursor
                default: return nil
                }
            }

            public var rawValue: String {
                switch self {
                case .cursor: return "cursor"
                case .elements: return Service.elementNodeKey
                }
            }
        }
    }

    public struct UnpagedResponse<Service: FigmaV1ArrayService>: Codable {
        public var status: Int
        public var error: Bool
        public var results: [Service.ResultElementType]

        enum CodingKeys: String, CodingKey {
            case status
            case error
            case results = "meta"
        }
    }

    public struct ComponentKey: RawRepresentable, Codable, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct ComponentSetKey: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: value)
        }
    }

    public struct FileKey: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: value)
        }
    }

    public struct StyleKey: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: value)
        }
    }

    public struct FrameInfo: Codable {
        public var name: String
        public var nodeID: NodeID
        public var pageName: String
        public var pageID: PageID
        public var backgroundColor: HTMLColor

        enum CodingKeys: String, CodingKey {
            case name = "name"
            case nodeID = "nodeId"
            case pageID = "pageId"
            case pageName = "pageName"
            case backgroundColor = "backgroundColor"
        }
    }

    public struct TeamID: RawRepresentable, Codable, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct ProjectID: RawRepresentable, Codable, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct NodeID: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: value)
        }
    }

    public typealias ComponentID = NodeID

    public typealias ComponentSetID = NodeID

    public typealias PageID = NodeID

    public struct HTMLColor: RawRepresentable, Codable, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct StyleID: RawRepresentable, Codable, Hashable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public struct User: Codable {
        public var id: UserID
        public var handle: String
        public var imgURL: String
        public var email: String?

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case handle = "handle"
            case imgURL = "img_url"
            case email
        }
    }

    public struct UserID: RawRepresentable, Codable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    // MARK: - BackgroundColor

    fileprivate static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withoutFractionalSeconds = ISO8601DateFormatter()
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions.insert(.withFractionalSeconds)

        decoder.dateDecodingStrategy = .custom {
            let c = try $0.singleValueContainer()
            let str = try c.decode(String.self)

            if let date = withoutFractionalSeconds.date(from: str) {
                return date
            }

            if let date = withFractionalSeconds.date(from: str) {
                return date
            }

            preconditionFailure()
        }
        return decoder
    }()
}

// MARK: - FigmaV1Service

public protocol FigmaV1Service: URLSessionService where Request == URLParameters<Path, Query>, Response: Codable {
    associatedtype Path
    associatedtype Query: Codable

    static var pathTemplate: StringTemplate<Path> { get }
}

extension FigmaV1Service {
    public static func urlRequest(for request: Request) throws -> URLRequest {
        var url = URLComponents(string: "https://api.figma.com/v1/")!
        url.path += Self.pathTemplate.render(request.pathValues)

        let enc = KeyValuePairEncoder()
        let items = try enc.encode(request.queryValues)

        url.queryItems = items.isEmpty ? nil : items.map { .init(name: $0, value: $1) }

        return URLRequest(url: url.url!)
    }

    public static func response(from response: (Data, URLResponse)) throws -> Response {
        let (data, resp) = response

        do {
            return try FigmaV1.decoder.decode(Response.self, from: data)
        } catch {
            if let str = String(data: data, encoding: .utf8) {
                print("here")
            }
            throw error
        }
    }

    public typealias Query = _EmptyQuery
}

extension CodingKey where Self: RawRepresentable, Self.RawValue == String {
    public var stringValue: String { rawValue }
    public init?(stringValue: String) { self.init(rawValue: stringValue) }
    public var intValue: Int? { nil }
    public init?(intValue: Int) { return nil }
}

// MARK: - FigmaV1ArrayService

public protocol FigmaV1ArrayService: FigmaV1Service {
    static var elementNodeKey: String { get }
    associatedtype ResultElementType: Codable
}

// MARK: - CustomKeys

//
// struct FigmaAPI {
//    var v1: V1
//
//    struct V1 {
//        var teams: Teams
//        var projects: Projects
//        var componentSets: ComponentSets
//    }
//
//    struct Teams {
//        subscript(_ id:
//    }
// }
@propertyWrapper
public struct CustomKeys<Key: RawRepresentable & Hashable, Value: Codable>: Codable where Key.RawValue == String {
    public var wrappedValue: [Key: Value]

    public init(wrappedValue: [Key: Value]) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        var result: [Key: Value] = [:]

        let container = try decoder.container(keyedBy: RawRepresentableCodingKey<Key>.self)
        let keys = container.allKeys

        for k in keys {
            let v = try container.decode(Value.self, forKey: k)
            result[k.wrapped] = v
        }
        self.init(wrappedValue: result)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawRepresentableCodingKey<Key>.self)

        for (k, v) in wrappedValue {
            try container.encode(v, forKey: .init(k))
        }
    }
}

// MARK: - RawRepresentableCodingKey

struct RawRepresentableCodingKey<R: RawRepresentable>: CodingKey {
    var stringValue: String {
        wrapped.rawValue as! String
    }

    init?(stringValue: String) {
        guard let value = R(rawValue: stringValue as! R.RawValue) else {
            return nil
        }
        wrapped = value
    }

    var intValue: Int? {
        wrapped.rawValue as? Int
    }

    init?(intValue: Int) {
        guard let value = R(rawValue: intValue as! R.RawValue) else {
            return nil
        }
        wrapped = value
    }

    public init(_ wrapped: R) {
        self.wrapped = wrapped
    }

    public var wrapped: R
}

// MARK: - PassthroughCodable

@dynamicMemberLookup
public class PassthroughCodable<Values: Codable> {
    private var values: Values

    required init(from decoder: Decoder) throws {
        values = try .init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try values.encode(to: encoder)
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Values, T>) -> T {
        get { values[keyPath: keyPath] }
        set { values[keyPath: keyPath] = newValue }
    }
}

// MARK: - PassthroughCodable2

@dynamicMemberLookup
public class PassthroughCodable2<Values1: Codable, Values2: Codable> {
    private var values1: Values1
    private var values2: Values2

    required init(from decoder: Decoder) throws {
        values1 = try .init(from: decoder)
        values2 = try .init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try values1.encode(to: encoder)
        try values2.encode(to: encoder)
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Values1, T>) -> T {
        get { values1[keyPath: keyPath] }
        set { values1[keyPath: keyPath] = newValue }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Values2, T>) -> T {
        get { values2[keyPath: keyPath] }
        set { values2[keyPath: keyPath] = newValue }
    }
}

extension KeyedDecodingContainer {
    public func decode(
        _ type: FigmaV1.CornerRadii.Type,
        forKey key: Key
    ) throws -> FigmaV1.CornerRadii {
        try decodeIfPresent(type, forKey: key) ?? .init(topLeft: 0, topRight: 0, bottomRight: 0, bottomLeft: 0)
    }
}

// MARK: - DictionaryCodable

@propertyWrapper
public struct DictionaryCodable<Key: Hashable & RawRepresentable, Value: Codable>: Codable
    where Key.RawValue == String {
    public var wrappedValue: [Key: Value]

    public init(from decoder: Decoder) throws {
        let dict = try [String: Value](from: decoder)
        let dec = Dictionary(uniqueKeysWithValues: dict.map { (Key(rawValue: $0)!, $1) })

        self.wrappedValue = dec
    }

    public func encode(to encoder: Encoder) throws {
        let enc = Dictionary(uniqueKeysWithValues: wrappedValue.map { ($0.rawValue, $1) })
        try enc.encode(to: encoder)
    }
}
