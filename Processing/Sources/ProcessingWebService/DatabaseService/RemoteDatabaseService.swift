import Collector
import Apodini
import ApodiniAsyncHTTPClient


protocol DatabaseService {
    func query(userID: Int, span: Span) -> EventLoopFuture<[Coordinate]>
}


class RemoteDatabaseService: DatabaseService {
    let hostname: String
    let port: Int
    let decoder = JSONDecoder()
    let client: HTTPClient
    
    
    init(hostname: String, port: Int, client: HTTPClient) {
        self.hostname = hostname
        self.port = port
        self.client = client
    }
    
    
    func query(userID: Int, span: Span) -> EventLoopFuture<[Coordinate]> {
        do {
            var request = try HTTPClient.Request(url: "http://\(hostname):\(port)/user/\(userID)/location")
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
                    
                    return try self.decoder.decode([Coordinate].self, from: body)
                }
        } catch {
            return client.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}


fileprivate struct DatabaseServiceStorageKey: StorageKey {
    typealias Value = DatabaseService
}


struct RemoteDatabaseServiceConfiguration: Configuration {
    let hostname: String
    let port: Int
    
    
    func configure(_ app: Application) {
        app.storage[DatabaseServiceStorageKey.self] = RemoteDatabaseService(
            hostname: hostname,
            port: port,
            client: app.httpClient
        )
    }
}


extension Apodini.Application {
    var databaseService: DatabaseService {
        guard let databaseService = self.storage[DatabaseServiceStorageKey.self] else {
            fatalError("You need to add a RemoteDatabaseServiceConfiguration to the WebService configuration to use the databaseService in the Environment")
        }
        
        return databaseService
    }
}
