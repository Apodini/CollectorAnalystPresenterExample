import Apodini
import JaegerCollector


struct ReadHotspotsHandler: Handler {
    @Environment(\.databaseService) var databaseService: DatabaseService
    @Environment(\.processingService) var processingService: ProcessingService
    @Environment(\.tracer) var tracer: Tracer
    @Environment(\.connection) var connection: Connection
    
    @Binding var userID: Int
    
    @Throws(.notFound, reason: "The specified user location could not be found")
    var notFound: ApodiniError
    
    
    func handle() throws -> EventLoopFuture<[Coordinate]> {
        let span = tracer.span(name: "hotspots", from: connection)
        let querySpan = span.child(name: "database")

        Metric
            .counter(label: "hotspots_usage", dimensions: ["path": "user/{id}/hotspots"])
            .increment()

        return try databaseService
            .query(userID: userID, span: querySpan)
            .always { _ in
                querySpan.finish()
            }
            .flatMapThrowing { locations in
                Metric
                    .recorder(label: "hotspots_locations", dimensions: ["path": "user/{id}/hotspots"])
                    .record(locations.count)

                let child = span.child(name: "calculation")
                let spots = try processingService.hotspots(in: locations)
                child.finish()

                Metric
                    .recorder(label: "hotspots", dimensions: ["path": "user/{id}/hotspots"])
                    .record(spots.count)

                return spots
            }
            .always { _ in
                span.finish()
            }
            .flatMapErrorThrowing { _ in
                throw notFound
            }
    }
}
