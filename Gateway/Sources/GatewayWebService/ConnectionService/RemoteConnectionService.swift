//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import AsyncHTTPClient
import Collector
import NIOHTTP1


protocol ConnectionService {
    func add(_ coordinate: Coordinate, userID: Int) throws -> EventLoopFuture<Coordinate>
    func hotspots(userID: Int) throws -> EventLoopFuture<[Coordinate]>
}


class RemoteConnectionService: ConnectionService {
    struct ResponseWrapper<D: Decodable>: Decodable {
        enum CodingKeys: String, CodingKey {
            case data
            case links = "_links"
        }
        
        let data: D
        let links: [String: String]
    }
    
    
    static let sendInterval = 10.0
    
    
    let client: HTTPClient
    let tracer: Tracer
    let databaseURL: URL
    let processingURL: URL

    
    init(client: HTTPClient, tracer: Tracer, databaseURL: URL, processingURL: URL) {
        self.client = client
        self.tracer = tracer
        self.databaseURL = databaseURL
        self.processingURL = processingURL
    }
    
    
    func add(_ coordinate: Coordinate, userID: Int) throws -> EventLoopFuture<Coordinate> {
        try makeNetworkCall(to: databaseURL.appendingPathComponent("v1/user/\(userID)/locations"), method: .POST, requestContent: coordinate)
    }
    
    func hotspots(userID: Int) throws -> EventLoopFuture<[Coordinate]> {
        try makeNetworkCall(to: processingURL.appendingPathComponent("v1/user/\(userID)/hotspots"), requestContentType: Empty.self)
    }
    
    private func makeNetworkCall<E: Encodable, D: Decodable>(
        to url: URL,
        method: HTTPMethod = .GET,
        requestContent: E? = nil,
        requestContentType: E.Type = E.self
    ) throws -> EventLoopFuture<D> {
        let body: HTTPClient.Body?
        if let requestContent = requestContent, method != .GET, let data = try? JSONEncoder().encode(requestContent) {
            body = .data(data)
        } else {
            body = nil
        }
        
        var request = try HTTPClient.Request(
            url: url,
            method: method,
            headers: body != nil ? ["Content-Type": "application/json"] : [:],
            body: body
        )
        
        let span = tracer.span(name: url.pathComponents.joined(separator: "/"))
        span.propagate(in: &request)

        return client
            .execute(request: request)
            .flatMapThrowing { response in
                span.set(Int(response.status.code), forKey: "status-code")
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(type: .notFound, reason: "\(response.status)")
                }
                guard let body = response.body else {
                    throw ApodiniError(type: .notFound, reason: "Response was empty")
                }
                span.set(Data(buffer: body), forKey: "body")
                return try JSONDecoder().decode(ResponseWrapper<D>.self, from: body).data
            }
            .always { _ in
                span.finish()
            }
    }
}


private struct ConnectionServiceStorageKey: StorageKey {
    typealias Value = ConnectionService
}


extension Apodini.Application {
    var connectionService: ConnectionService {
        guard let connectionService = self.storage[ConnectionServiceStorageKey.self] else {
            fatalError("You need to add a RemoveConnectionServiceConfiguration to use the connectionService in the Environment")
        }
        return connectionService
    }
}


struct RemoveConnectionServiceConfiguration: Configuration {
    let databaseURL: URL
    let processingURL: URL
    
    
    func configure(_ app: Application) {
        app.storage[ConnectionServiceStorageKey.self] = RemoteConnectionService(
            client: app.httpClient,
            tracer: app.tracer,
            databaseURL: databaseURL,
            processingURL: processingURL
        )
    }
}
