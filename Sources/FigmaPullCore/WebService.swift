//
//  WebService.swift
//  HonorFigmaPull
//
//  Created by Michael Kasianowicz on 11/21/22.
//

import Foundation

// MARK: - APISession

@dynamicMemberLookup
public struct APISession<API: URLSessionAPI> {
    public var session: URLSession
    public init(session: URLSession) {
        self.session = session
    }

    public subscript<Service: URLSessionService>(dynamicMember keyPath: KeyPath<API, Service>)
        -> URLSessionMethod<Service> {
        .init(session: session)
    }
}

// MARK: - URLSessionAPI

public protocol URLSessionAPI {}

// MARK: - URLSessionMethod

public struct URLSessionMethod<Service: URLSessionService> {
    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    public func callAsFunction(_ request: Service.Request) async throws -> Service.Response {
        let urlRequest = try await Task { try Service.urlRequest(for: request) }.value

        let (data, resp) = try await session.data(for: urlRequest)

        let response = try await Task { try Service.response(from: (data, resp)) }.value
        return response
    }

    public func callAsFunction<P, Q>(_ path: P, _ query: Q) async throws -> Service.Response where Service.Request == URLParameters<P, Q>{
        try await callAsFunction(.init(pathValues: path, queryValues: query))
    }

    public func callAsFunction<P>(_ path: P) async throws -> Service.Response where Service.Request == URLParameters<P, _EmptyQuery>{
        try await callAsFunction(.init(pathValues: path, queryValues: .init()))
    }
}

// MARK: - URLSessionService

public protocol URLSessionService {
    associatedtype Request
    associatedtype Response

    static func urlRequest(for request: Request) throws -> URLRequest
    static func response(from response: (Data, URLResponse)) throws -> Response
}

// MARK: - URLParameters

@dynamicMemberLookup
public struct URLParameters<PathValues, QueryValues: Codable> {
    public var pathValues: PathValues
    public var queryValues: QueryValues

    public init(pathValues: PathValues, queryValues: QueryValues) {
        self.pathValues = pathValues
        self.queryValues = queryValues
    }

    public subscript<V>(dynamicMember keyPath: WritableKeyPath<PathValues, V>) -> V {
        get {
            pathValues[keyPath: keyPath]
        }
        set {
            pathValues[keyPath: keyPath] = newValue
        }
    }

    public subscript<V>(dynamicMember keyPath: WritableKeyPath<QueryValues, V>) -> V {
        get {
            queryValues[keyPath: keyPath]
        }
        set {
            queryValues[keyPath: keyPath] = newValue
        }
    }
}

extension URLParameters where QueryValues == _EmptyQuery {
    public init(_ path: PathValues) {
        self.pathValues = path
        self.queryValues = .init()
    }
}

// MARK: - _EmptyQuery

public struct _EmptyQuery: Codable {
    public init() {}
}

