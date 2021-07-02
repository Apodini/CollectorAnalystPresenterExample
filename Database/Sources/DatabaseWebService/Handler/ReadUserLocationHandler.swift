import Apodini
import JaegerCollector


struct ReadUserLocationHandler: Handler {
    @Environment(\.databaseService) var databaseService: DatabaseService
    @Environment(\.tracer) var tracer: Tracer
    @Environment(\.connection) var connection: Connection
    
    @Binding var userID: Int
    
    @Throws(.notFound, reason: "The specified user location could not be found")
    var notFound: ApodiniError
    
    
    func handle() -> EventLoopFuture<[Coordinate]> {
        let span = tracer.span(name: "location", from: connection)

        Metric
            .counter(label: "location_usage", dimensions: ["method": "GET", "path": "/user/{id}/locations"])
            .increment()

        let querySpan = span.child(name: "location-query")

        return databaseService.query(userID: userID)
            .always { _ in
                querySpan.finish()
            }
            .always { value in
                guard let result = try? value.get() else {
                    return
                }
                
                Metric
                    .recorder(label: "location_results", dimensions: ["method": "GET", "path": "/user/{id}/locations"])
                    .record(result.count)
            }
            .always { _ in
                span.finish()
            }
            .flatMapErrorThrowing { _ in
                throw notFound
            }
    }
}
