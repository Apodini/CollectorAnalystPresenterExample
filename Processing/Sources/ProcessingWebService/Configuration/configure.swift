//import JaegerCollector
//import PrometheusCollector
//import Vapor
//
//public func configure(_ app: Application) throws {
//    let client = HTTPClient(eventLoopGroupProvider: .shared(app.eventLoopGroup))
//    let databaseService: DatabaseService =
//        RemoteDatabaseService(hostname: "database",
//                              port: 80,
//                              client: client)
//    let processingService: ProcessingService =
//        DefaultProcessingService()
//
//    let channel = ClientConnection.insecure(group: client.eventLoopGroup)
//        .connect(host: Configuration.jaegerHostname, port: Configuration.jaegerCollectorPort)
//    let sender = JaegerSender(serviceName: "processing", tags: [:], channel: channel)
//    let agent = BasicAgent(interval: 60, sender: sender)
//    let tracer = BasicTracer(agent: agent)
//
//    let metricsService: MetricsService = UIMetricsService(client: client)
//
//    Metric.setup()
//
//    app.get("user", ":userID", "hotspots") { request -> EventLoopFuture<[Coordinate]> in
//        guard let userID = request.parameters.get("userID", as: Int.self) else {
//            throw Abort(.badRequest)
//        }
//        let span = tracer.span(name: "hotspots-\(userID)", from: request)
//        let querySpan = span.child(name: "database-access")
//
//        Metric
//        .counter(label: "usage", dimensions: ["path": "user/{id}/hotspots"])
//        .increment()
//
//        return try databaseService.query(userID: userID, span: querySpan)
//            .always { _ in querySpan.finish() }
//            .flatMapThrowing { locations in
//
//                Metric
//                .recorder(label: "input-count", dimensions: ["path": "user/{id}/hotspots"])
//                .record(locations.count)
//
//                let child = span.child(name: "hotspots")
//                let spots = try processingService.hotspots(in: locations)
//                child.finish()
//
//                Metric
//                .recorder(label: "output-count", dimensions: ["path": "user/{id}/hotspots"])
//                .record(spots.count)
//
//                return spots
//            }
//            .always { _ in span.finish() }
//    }
//
//    app.get("metrics") { request in
//        Metric.string(on: request.eventLoop)
//    }
//
//    app.get("metrics-ui") { _ in
//        try metricsService.view()
//    }
//
//}
//
//extension Data: ResponseEncodable {
//
//    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
//        request.eventLoop.future(
//            Response(status: .ok,
//                     version: request.version,
//                     headers: HTTPHeaders([("Content-Type", "application/json")]),
//                     body: .init(data: self))
//        )
//    }
//
//}
