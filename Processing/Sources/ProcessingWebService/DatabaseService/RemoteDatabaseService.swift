//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniAsyncHTTPClient
import ApodiniCollector
import Foundation

protocol DatabaseService {
    func query(userID: Int, span: Span) throws -> EventLoopFuture<[Coordinate]>
}


class RemoteDatabaseService: DatabaseService {
    struct ResponseWrapper<D: Decodable>: Decodable {
        enum CodingKeys: String, CodingKey {
            case data
            case links = "_links"
        }
        
        let data: D
        let links: [String: String]
    }
    
    
    let databaseServiceURL: URL
    let decoder = JSONDecoder()
    let client: HTTPClient
    
    
    init(databaseServiceURL: URL, client: HTTPClient) {
        self.databaseServiceURL = databaseServiceURL
        self.client = client
    }
    
    
    func query(userID: Int, span: Span) throws -> EventLoopFuture<[Coordinate]> {
        var request = try HTTPClient.Request(url: databaseServiceURL.appendingPathComponent("v1/user/\(userID)/locations"))
        span.propagate(in: &request)
        
        return client
            .execute(request: request)
            .flatMapThrowing { response in
                span.set(Int(response.status.code), forKey: "status-code")
                guard (200..<300).contains(response.status.code) else {
                    throw ApodiniError(
                        type: .serverError,
                        reason: "Recieved a response from the database service with status code \(response.status.code)"
                    )
                }
                guard let body = response.body else {
                    throw ApodiniError(
                        type: .serverError,
                        reason: "Recieved a response with an empty body from the database service"
                    )
                }
                span.set(Data(buffer: body), forKey: "body")
                
                return try self.decoder.decode(ResponseWrapper<[Coordinate]>.self, from: body).data
            }
    }
}


private struct DatabaseServiceStorageKey: StorageKey {
    typealias Value = DatabaseService
}


struct RemoteDatabaseServiceConfiguration: Configuration {
    let databaseServiceURL: URL
    
    
    func configure(_ app: Application) {
        app.storage[DatabaseServiceStorageKey.self] = RemoteDatabaseService(
            databaseServiceURL: databaseServiceURL,
            client: app.httpClient
        )
    }
}


extension Apodini.Application {
    var databaseService: DatabaseService {
        guard let databaseService = self.storage[DatabaseServiceStorageKey.self] else {
            fatalError("You need to add a RemoteDatabaseServiceConfiguration to use the databaseService in the Environment")
        }
        
        return databaseService
    }
}
