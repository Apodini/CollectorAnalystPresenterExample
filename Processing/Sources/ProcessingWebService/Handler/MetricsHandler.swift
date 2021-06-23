import Apodini
import PrometheusCollector


struct MetricsHandler: Handler {
    @Environment(\.eventLoopGroup) var eventLoopGroup: EventLoopGroup
    
    
    func handle() -> EventLoopFuture<String> {
        Metric.string(on: eventLoopGroup.next())
    }
}
