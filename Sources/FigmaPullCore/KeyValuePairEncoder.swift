import Foundation

// MARK: - KeyValuePairEncoder

public class KeyValuePairEncoder {
    public enum BoolEncodingStrategy {
        case int
        case string
    }

    public enum ArrayEncodingStrategy {
        case join(separator: String = ",")
        case duplicate(suffix: StringTemplate<Int> = "")
    }

    public var boolEncodingStrategy: BoolEncodingStrategy = .string

    public var arrayEncodingStrategy: ArrayEncodingStrategy = .join(separator: ",")

    public func encode<T>(_ value: T) throws -> [(key: String, value: String)] where T: Encodable {
        let builder = KeyValuePairResultBuilder(
            boolEncodingStrategy: boolEncodingStrategy,
            arrayEncodingStrategy: arrayEncodingStrategy
        )

        let enc = RootEncoder(builder: builder)
        try value.encode(to: enc)

        builder.flush()
        return builder.output
    }

    public init(
        boolEncodingStrategy: BoolEncodingStrategy = .string,
        arrayEncodingStrategy: ArrayEncodingStrategy = .join(separator: ",")
    ) {
        self.boolEncodingStrategy = boolEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }
}

// MARK: - KeyValuePairResultBuilder

private class KeyValuePairResultBuilder {
    public var output: [(key: String, value: String)] = []

    private var current: (key: String, value: String)? = nil
    public var currentCount: Int = 0

    public var boolEncodingStrategy: KeyValuePairEncoder.BoolEncodingStrategy

    public var arrayEncodingStrategy: KeyValuePairEncoder.ArrayEncodingStrategy

    init(
        boolEncodingStrategy: KeyValuePairEncoder.BoolEncodingStrategy,
        arrayEncodingStrategy: KeyValuePairEncoder.ArrayEncodingStrategy
    ) {
        self.boolEncodingStrategy = boolEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }

    public func flush() {
        if let current {
            output.append(current)
        }
        current = nil
        currentCount = 0
    }

    public func put(_ value: String, forKey key: String) {
        flush()

        output.append((key, value))
    }

    public func putNil(forKey key: String) {
        put("", forKey: key)
    }

    public func put<I: SignedInteger>(_ value: I, forKey key: String) {
        put("\(value)", forKey: key)
    }

    public func put<I: UnsignedInteger>(_ value: I, forKey key: String) {
        put("\(value)", forKey: key)
    }

    public func put(_ value: Bool, forKey key: String) {
        put(value ? "true" : "false", forKey: key)
    }

    public func put<F: FloatingPoint>(_ value: F, forKey key: String) {
        put("\(value)", forKey: key)
    }

    public func putElement(_ value: String, forKey key: String) {
        switch arrayEncodingStrategy {
        case .duplicate(let suffix):
            let newKey = key + suffix.render(currentCount)
            put(value, forKey: newKey)

        case .join(let separator):
            if current?.key != key {
                flush()
                current = (key: key, value: value)
            } else {
                current?.value += separator + value
            }
        }
        currentCount += 1
    }

    public func putNilElement(forKey key: String) {
        putElement("", forKey: key)
    }

    public func putElement<I: SignedInteger>(_ value: I, forKey key: String) {
        putElement("\(value)", forKey: key)
    }

    public func putElement<I: UnsignedInteger>(_ value: I, forKey key: String) {
        putElement("\(value)", forKey: key)
    }

    public func putElement(_ value: Bool, forKey key: String) {
        putElement(value ? "1" : "0", forKey: key)
    }

    public func putElement<F: FloatingPoint>(_ value: F, forKey key: String) {
        putElement("\(value)", forKey: key)
    }
}

// MARK: - RootEncoder

private struct RootEncoder: Encoder {
    private let builder: KeyValuePairResultBuilder
    public var codingPath: [CodingKey] { [] }
    public var userInfo: [CodingUserInfoKey: Any] { [:] }

    public init(builder: KeyValuePairResultBuilder) {
        self.builder = builder
    }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        .init(KeyedContainer(builder: builder))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer { preconditionFailure() }

    public func singleValueContainer() -> SingleValueEncodingContainer { preconditionFailure() }
}

// MARK: - NodeEncoder

private struct NodeEncoder: Encoder {
    private let builder: KeyValuePairResultBuilder
    private let codingKey: CodingKey

    public var codingPath: [CodingKey] { [codingKey] }
    public var userInfo: [CodingUserInfoKey: Any] { [:] }

    public init(builder: KeyValuePairResultBuilder, codingKey: CodingKey) {
        self.builder = builder
        self.codingKey = codingKey
    }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        preconditionFailure()
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        ArrayContainer(builder: builder, codingKey: codingKey)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        SingleValueContainer(builder: builder, codingKey: codingKey)
    }
}

// MARK: - KeyedContainer

private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    public let builder: KeyValuePairResultBuilder

    init(builder: KeyValuePairResultBuilder) {
        self.builder = builder
    }

    public var codingPath: [CodingKey] { [] }

    mutating func encodeNil(forKey key: Key) throws {
        builder.putNil(forKey: key.stringValue)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        let superEnc = superEncoder(forKey: key)
        try value.encode(to: superEnc)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        preconditionFailure()
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        preconditionFailure()
    }

    mutating func superEncoder() -> Encoder {
        RootEncoder(builder: builder)
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        NodeEncoder(builder: builder, codingKey: key)
    }
}

// MARK: - SingleValueContainer

private struct SingleValueContainer: SingleValueEncodingContainer {
    public let builder: KeyValuePairResultBuilder
    private let codingKey: CodingKey

    private var key: String { codingKey.stringValue }

    public init(builder: KeyValuePairResultBuilder, codingKey: CodingKey) {
        self.builder = builder
        self.codingKey = codingKey
    }

    public var codingPath: [CodingKey] { [codingKey] }

    mutating func encodeNil() throws {
        builder.putNil(forKey: key)
    }

    mutating func encode(_ value: Bool) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: String) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Double) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Float) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Int) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Int8) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Int16) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Int32) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: Int64) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: UInt) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: UInt8) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: UInt16) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: UInt32) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode(_ value: UInt64) throws {
        builder.put(value, forKey: key)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        try value.encode(to: RootEncoder(builder: builder))
    }
}

// MARK: - ArrayEncoder

private struct ArrayEncoder: Encoder {
    public let builder: KeyValuePairResultBuilder
    private let codingKey: CodingKey

    private var key: String { codingKey.stringValue }

    public init(builder: KeyValuePairResultBuilder, codingKey: CodingKey) {
        self.builder = builder
        self.codingKey = codingKey
    }

    public var codingPath: [CodingKey] { [codingKey] }
    public var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        preconditionFailure()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        ArrayContainer(builder: builder, codingKey: codingKey)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        preconditionFailure()
    }
}

// MARK: - ArrayContainer

private struct ArrayContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
    public let builder: KeyValuePairResultBuilder
    private let codingKey: CodingKey

    private var key: String { codingKey.stringValue }

    public init(builder: KeyValuePairResultBuilder, codingKey: CodingKey) {
        self.builder = builder
        self.codingKey = codingKey
    }

    public var codingPath: [CodingKey] { [codingKey] }

    public var count: Int { builder.currentCount }

    mutating func encodeNil() throws {
        builder.putNil(forKey: key)
    }

    mutating func encode(_ value: Bool) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: String) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Double) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Float) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Int) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Int8) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Int16) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Int32) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: Int64) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: UInt) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: UInt8) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: UInt16) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: UInt32) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode(_ value: UInt64) throws {
        builder.putElement(value, forKey: key)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        let enc = superEncoder()
        try value.encode(to: enc)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey {
        preconditionFailure()
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        preconditionFailure()
    }

    mutating func superEncoder() -> Encoder {
        ArrayEncoder(builder: builder, codingKey: codingKey)
    }
}
