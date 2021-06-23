
import PrometheusCollector
import JaegerCollector
import GRPC
import Vapor

/// Called before your application initializes.
public func configure(_ app: Application) throws {

    let client = HTTPClient(eventLoopGroupProvider: .shared(app.eventLoopGroup))
    let service: ConnectionService = RemoteConnectionService(client: client)
    let metricsService: MetricsService = UIMetricsService(client: client)
    Metric.setup()

    periodicTask()

    app.get("user", ":userID", "hotspots") { request -> EventLoopFuture<[Coordinate]> in

        guard let userID = request.parameters.get("userID", as: Int.self) else {
            throw Abort(.badRequest)
        }

        Metric
            .counter(label: "hotspots_usage_count", dimensions: ["userID": userID.description])
            .increment()

        return try service.hotspots(userID: userID)
    }

    app.post("user", ":userID", "location") { request -> EventLoopFuture<Coordinate> in

        guard let userID = request.parameters.get("userID", as: Int.self) else {
            throw Abort(.badRequest)
        }

        let location = try request.content.decode(Coordinate.self)

        Metric.counter(label: "location_usage_count", dimensions: ["userID": userID.description])
            .increment()

        Metric.gauge(label: "location_latitude", dimensions: ["userID": userID.description])
            .record(location.latitude)

        Metric.gauge(label: "location_longitude", dimensions: ["userID": userID.description])
            .record(location.longitude)

        return try service.add(location, userID: userID)
    }

    app.get("metrics") {
        Metric.string(on: $0.eventLoop)
    }

    app.get("metrics-ui") { _ in
        try metricsService.view()
    }

}

private func periodicTask() {
    let startDate = Date()

    Metric.counter(label: "gateway_periodic_task").increment()

    let process = ProcessInfo.processInfo

    Metric.gauge(label: "gateway_active_processor_count")
    .record(process.activeProcessorCount)

    Metric.gauge(label: "gateway_physical_memory")
    .record(process.physicalMemory)

    Metric.recorder(label: "gateway_processor_count")
    .record(process.processorCount)

    Metric.timer(label: "gateway_periodic_task_duration")
    .record(-startDate.timeIntervalSinceNow)

    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
        periodicTask()
    }
}

extension Data: ResponseEncodable {

    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        request.eventLoop.future(
            Response(status: .ok,
                     version: request.version,
                     headers: HTTPHeaders([("Content-Type", "application/json")]),
                     body: .init(data: self))
        )
    }

}
