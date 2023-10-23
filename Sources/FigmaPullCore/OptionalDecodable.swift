
import Foundation

// MARK: - OptionalDecodable

public enum OptionalDecodable {
//    public typealias True = Defaultable<Sources.True>
//    public typealias False = Defaultable<Sources.False>

//    public typealias Zero<T: AdditiveArithmetic & Codable> = Defaultable<Sources.Zero<T>>
//    public typealias EmptyArray<T: ExpressibleByArrayLiteral & Codable> = _Defaultable<Sources.EmptyArray<T>>
}

// MARK: - DefaultableSource

public protocol DefaultableSource {
    associatedtype Value
    static var `default`: Value { get }
}

// MARK: - CodableDefault

@propertyWrapper
public struct CodableDefault<Source: DefaultableSource>: Codable where Source.Value: Codable {
    private var value: Source.Value?

    public var wrappedValue: Source.Value { get { value ?? Source.default } set { value = newValue } }

    public init() {
        self.init(wrappedValue: Source.default)
    }

    public init(wrappedValue: Source.Value) {
        self.value = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        value = try .init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        if let value {
            try value.encode(to: encoder)
        }
    }
}

// MARK: - CodableDefaultSources

public enum CodableDefaultSources {
    public enum True: DefaultableSource {
        public static let `default` = true
    }

    public enum False: DefaultableSource {
        public static let `default` = false
    }

    public enum Zero<T: AdditiveArithmetic & Codable>: DefaultableSource {
        public static var `default`: T { T.zero }
    }

    public enum EmptyArray<T: ExpressibleByArrayLiteral & Codable>: DefaultableSource {
        public static var `default`: T { [] }
    }

    public enum EmptyDictionary<T: ExpressibleByDictionaryLiteral & Codable>: DefaultableSource {
        public static var `default`: T { [:] }
    }
}

extension KeyedDecodingContainer {
    public func decode<T>(
        _ type: CodableDefault<T>.Type,
        forKey key: Key
    ) throws -> CodableDefault<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}

// MARK: - Default

public enum Default<T> {}

extension Default where T: ExpressibleByBooleanLiteral {
    public enum True: DefaultableSource {
        public static var `default`: T { true }
    }

    public enum False: DefaultableSource {
        public static var `default`: T { false }
    }
}

// MARK: Default.Zero

extension Default where T: AdditiveArithmetic {
    public enum Zero: DefaultableSource {
        public static var `default`: T { T.zero }
    }
}

// MARK: Default.One

extension Default where T: ExpressibleByIntegerLiteral {
    public enum One: DefaultableSource {
        public static var `default`: T { 1 }
    }
}

// MARK: Default._20_89

extension Default where T: ExpressibleByFloatLiteral {
    public enum _20_89: DefaultableSource {
        public static var `default`: T { 20.89 }
    }
}

// MARK: Default.NoItems

extension Default where T: ExpressibleByArrayLiteral {
    public enum NoItems: DefaultableSource {
        public static var `default`: T { [] }
    }
}

// MARK: Default.NoPairs

extension Default where T: ExpressibleByDictionaryLiteral {
    public enum NoPairs: DefaultableSource {
        public static var `default`: T { [:] }
    }
}
