import Apodini
import Collector
import AsyncHTTPClient


protocol ConnectionService {
    func add(_ coordinate: Coordinate, userID: Int) throws -> EventLoopFuture<Coordinate>
    func hotspots(userID: Int) throws -> EventLoopFuture<[Coordinate]>
}


class RemoteConnectionService: ConnectionService {
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
        let data = try JSONEncoder().encode(coordinate)
        var request = try HTTPClient.Request(
            url: databaseURL.appendingPathComponent("/v1/user/\(userID)/location"),
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: .data(data)
        )
        let span = tracer.span(name: "/v1/user/{id}/location")
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
                return try JSONDecoder().decode(Coordinate.self, from: body)
            }
            .always { _ in
                span.finish()
            }
    }
    
    func hotspots(userID: Int) throws -> EventLoopFuture<[Coordinate]> {
        var request = try HTTPClient.Request(
            url: processingURL.appendingPathComponent("/v1/user/\(userID)/hotspots"),
            method: .GET,
            headers: ["Content-Type": "application/json"]
        )

        let span = tracer.span(name: "/v1/user/{id}/hotspots")
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
                return try JSONDecoder().decode([Coordinate].self, from: body)
            }
            .always { _ in
                span.finish()
            }
    }
}


fileprivate struct ConnectionServiceStorageKey: StorageKey {
    typealias Value = ConnectionService
}


extension Apodini.Application {
    var connectionService: ConnectionService {
        get {
            guard let connectionService = self.storage[ConnectionServiceStorageKey.self] else {
                fatalError("You need to add a RemoveConnectionServiceConfiguration to the WebService configuration to use the connectionService in the Environment")
            }
            return connectionService
        }
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
