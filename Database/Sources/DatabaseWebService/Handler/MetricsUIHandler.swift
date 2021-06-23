import Apodini
import PrometheusCollector


struct MetricsUIHandler: Handler {
    @Environment(\.metricsService) var metricsService: MetricsService
    
    @Throws(.serverError, reason: "Could not render the Metrics UI")
    var serverError: ApodiniError
    
    
    func handle() -> EventLoopFuture<Blob> {
        metricsService.view()
            .map { data in
                Blob(data, type: .application(.json))
            }
            .flatMapErrorThrowing { _ in
                throw serverError
            }
    }
}
