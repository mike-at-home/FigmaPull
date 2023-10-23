//
//  StringTemplate.swift
//  HonorFigmaPull
//
//  Created by Michael Kasianowicz on 11/23/22.
//

import Foundation

// MARK: - StringTemplate

public struct StringTemplate<Parameters>: ExpressibleByStringInterpolation {
    public init(stringInterpolation: StringInterpolation) {
        self = stringInterpolation.result
    }

    private var segments: [Segment] = []
    fileprivate init() {}

    public init(stringLiteral value: String) {
        self.segments = [.string(value)]
    }

    private enum Segment {
        case string(String)
        case parameter(KeyPath<Parameters, String>)
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var result: StringTemplate = .init()

        public init(literalCapacity: Int, interpolationCount: Int) {}

        public mutating func appendLiteral(_ literal: String) {
            result.segments.append(.string(literal))
        }

        public mutating func appendInterpolation(_ keyPath: KeyPath<Parameters, String>) {
            result.segments.append(.parameter(keyPath))
        }

        public mutating func appendInterpolation<C: CustomStringConvertible>(_ keyPath: KeyPath<Parameters, C>) {
            result.segments.append(.parameter(keyPath.appending(path: \.description)))
        }

        public mutating func appendInterpolation<R: RawRepresentable>(_ keyPath: KeyPath<Parameters, R>)
            where R.RawValue == String {
            result.segments.append(.parameter(keyPath.appending(path: \.rawValue)))
        }

        public mutating func appendInterpolation<R: RawRepresentable>(_ keyPath: KeyPath<Parameters, R>)
            where R.RawValue: CustomStringConvertible {
            result.segments.append(.parameter(keyPath.appending(path: \.rawValue.description)))
        }
    }

    public func render(_ argument: Parameters) -> String {
        var result = ""

        for s in segments {
            switch s {
            case .string(let string): result.append(string)
            case .parameter(let kp): result.append(argument[keyPath: kp])
            }
        }
        return result
    }
}
