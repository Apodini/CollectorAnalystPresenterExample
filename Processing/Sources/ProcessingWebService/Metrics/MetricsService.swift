import Apodini
import AsyncHTTPClient
import AnalystPresenter
import NIO
import PrometheusAnalyst
import PrometheusCollector
import JaegerAnalyst


protocol MetricsService {
    func view() -> EventLoopFuture<Data>
}


final class UIMetricsService: MetricsService {

    // MARK: Stored Properties

    let metricsProvider: Prometheus
    let traceProvider: TraceProvider

    // MARK: Computed Properties

    var eventLoop: EventLoop {
        metricsProvider.client.eventLoopGroup.next()
    }

    // MARK: Initialization

    public init(
        client: HTTPClient,
        jaegerHostname: String,
        jaegerAnalystPort: Int,
        prometheusURL: URL
    ) {
        Presenter.use(plugin: AnalystPresenter())

        let channel = ClientConnection.insecure(group: client.eventLoopGroup)
            .connect(host: jaegerHostname, port: jaegerAnalystPort)

        self.traceProvider = JaegerProvider(channel: channel)

        self.metricsProvider = Prometheus(
            baseURL: prometheusURL,
            client: client
        )
    }

    // MARK: Methods

    func view() -> EventLoopFuture<Data> {
        serviceView()
            .flatMapThrowing {
                try Presenter.encode(CoderView($0))
            }
    }

    private func serviceView() -> ViewFuture {
        service(title: "Database", cards: [
            metricsRequests(job: "database")
        ])
    }
}

fileprivate struct MetricsServiceStorageKey: StorageKey {
    typealias Value = MetricsService
}


struct UIMetricsServiceConfiguration: Configuration {
    let jaegerHostname: String
    let jaegerAnalystPort: Int
    let prometheusURL: URL
    
    
    func configure(_ app: Application) {
        app.storage[MetricsServiceStorageKey.self] = UIMetricsService(
            client: app.httpClient,
            jaegerHostname: jaegerHostname,
            jaegerAnalystPort: jaegerAnalystPort,
            prometheusURL: prometheusURL
        )
        Metric.setup()
    }
}


extension Apodini.Application {
    var metricsService: MetricsService {
        guard let metricsService = self.storage[MetricsServiceStorageKey.self] else {
            fatalError("You need to add a UIMetricsServiceConfiguration to the WebService configuration to use the metricsService in the Environment")
        }
        
        return metricsService
    }
}
