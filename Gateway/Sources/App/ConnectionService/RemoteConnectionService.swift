import JaegerCollector
import Vapor

class RemoteConnectionService: ConnectionService {

    // MARK: Nested Types

    static let sendInterval = 10.0

    // MARK: Stored Properties

    let client: HTTPClient

    private lazy var tracer: Tracer = {
        let channel = ClientConnection.insecure(group: client.eventLoopGroup)
            .connect(host: Configuration.jaegerHostname, port: Configuration.jaegerCollectorPort)
        let sender = JaegerSender(serviceName: "gateway", tags: [:], channel: channel)
        let agent = BasicAgent(interval: Self.sendInterval, sender: sender)
        return BasicTracer(agent: agent)
    }()

    // MARK: Initialization

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: Methods

    func add(_ coordinate: Coordinate, userID: Int) throws -> EventLoopFuture<Coordinate> {
        let data = try JSONEncoder().encode(coordinate)
        var request = try HTTPClient.Request(
            url: "http://database:80/v1/user/\(userID)/location",
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: .data(data)
        )
        let span = tracer.span(name: "/user/{id}/location")
        span.propagate(in: &request)

        return client
            .execute(request: request)
            .flatMapThrowing { response in
                span.set(Int(response.status.code), forKey: "status-code")
                guard (200..<300).contains(response.status.code) else {
                    throw Abort(response.status)
                }
                guard let body = response.body else {
                    throw Abort(.internalServerError)
                }
                span.set(Data(buffer: body), forKey: "body")
                return try JSONDecoder().decode(Coordinate.self, from: body)
            }
            .always { _ in span.finish() }
    }

    func hotspots(userID: Int) throws -> EventLoopFuture<[Coordinate]> {
        let span = tracer.span(name: "user/{id}/hotspots")
        var request = try HTTPClient.Request(
            url: "http://processing:80/v1/user/\(userID)/hotspots",
            method: .GET,
            headers: ["Content-Type": "application/json"]
        )

        span.propagate(in: &request)

        return client
            .execute(request: request)
            .flatMapThrowing { response in
                span.set(Int(response.status.code), forKey: "status-code")
                guard (200..<300).contains(response.status.code) else {
                    throw Abort(response.status)
                }
                guard let body = response.body else {
                    throw Abort(.internalServerError)
                }
                span.set(Data(buffer: body), forKey: "body")
                return try JSONDecoder().decode([Coordinate].self, from: body)
            }
            .always { _ in
                span.finish()
            }
    }

}
