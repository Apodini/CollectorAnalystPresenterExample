import Apodini
import AsyncHTTPClient
import ApodiniAnalystPresenter
import PrometheusAnalyst
import JaegerAnalyst


final class GatewayPresenterService: PresenterService {
    let client: HTTPClient
    let metricsProvider: Prometheus
    let traceProvider: TraceProvider
    let processingURL: URL
    let databaseURL: URL
    
    
    var eventLoop: EventLoop {
        client.eventLoopGroup.next()
    }
    var view: ViewFuture {
        do {
            return try listView()
        } catch {
            return eventLoop.makeFailedFuture(ApodiniError(type: .serverError, reason: "Could not generate Presenter UI."))
        }
    }
    
    
    public init(
        client: HTTPClient,
        jaegerURL: URL,
        prometheusURL: URL,
        processingURL: URL,
        databaseURL: URL
    ) {
        Presenter.use(plugin: AnalystPresenter())
        
        self.client = client

        guard let jaegerHost = jaegerURL.host, let jaegerPort = jaegerURL.port else {
            fatalError("Could not identify a hostname and port in the URL: \(jaegerURL)")
        }
        let channel = ClientConnection.insecure(group: client.eventLoopGroup)
            .connect(host: jaegerHost, port: jaegerPort)
        self.traceProvider = JaegerProvider(channel: channel)
        
        self.metricsProvider = Prometheus(
            baseURL: prometheusURL,
            client: client
        )
        
        self.processingURL = processingURL
        self.databaseURL = databaseURL
    }

    // MARK: Nested Types

    private func listView() throws -> ViewFuture {
        EventLoopFuture<(_CodableView, _CodableView, _CodableView)>
            .combine(try gateway(), try database(), try processing())
            .map {
                self.listView(gateway: $0, database: $1, processing: $2)
            }
    }

    private func listView(gateway: _CodableView, database: _CodableView, processing: _CodableView) -> some View {
        NavigationView {
            ScrollView {
                VStack {
                    NavigationLink(
                        destination: CoderView(gateway),
                        isActive: .at("gateway.isActive", default: false),
                        label: self.cell(title: "Gateway", subtitle: "Microservice")
                    )

                    NavigationLink(
                        destination: CoderView(database),
                        isActive: .at("database.isActive", default: false),
                        label: self.cell(title: "Database", subtitle: "Microservice")
                    )

                    NavigationLink(
                        destination: CoderView(processing),
                        isActive: .at("processing.isActive", default: false),
                        label: self.cell(title: "Processing", subtitle: "Microservice")
                    )
                }
                .padding(8)
            }
            .navigationBarTitle(.static("Prometheus"))
        }
    }

    private func database() throws -> ViewFuture {
        let request = try HTTPClient.Request(
            url: databaseURL.appendingPathComponent("/v1/metrics-ui"),
            method: .GET,
            headers: ["Content-Type": "application/json"]
        )
        return client
            .execute(request: request)
            .map { response in
                guard let body = response.body else {
                    return Text(.static("not found"))
                }
                return DataView(.init(buffer: body))
            }
            .flatMapError { _ in
                self.eventLoop.future(Text(.static("Error")))
            }
    }

    private func processing() throws -> ViewFuture {
        let request = try HTTPClient.Request(
            url: processingURL.appendingPathComponent("/v1/metrics-ui"),
            method: .GET,
            headers: ["Content-Type": "application/json"]
        )
        return client
            .execute(request: request)
            .map { response in
                guard let body = response.body else {
                    return Text(.static("not found"))
                }
                return DataView(.init(buffer: body))
            }
            .flatMapError { _ in
                self.eventLoop.future(Text(.static("Error")))
            }
    }

    private func gateway() throws -> ViewFuture {
        service(title: "Gateway", cards: [
            metricsRequests(job: "gateway"),
            periodicTaskDuration(),
            try dependencies(),
            try lastTraces()
        ])
    }

    private func periodicTaskDuration() -> ViewFuture {
        let timer = Timer(label: "gateway_periodic_task_duration")
        let range = TimeRange.range(.days(3), step: .hours(1))
        let query = timer.query(scalar: .delta(timer[range.step]))
        return graph(for: query.in(range), title: "Periodic Task Duration")
    }

    private func list<C: Sequence, Cell: View>(
        _ title: String,
        for sequence: C,
        create: (C.Element) -> Cell
    ) -> some View {
        return ScrollView {
            VStack(alignment: .leading) {
                sequence.map(create)
            }.padding(8)
        }.navigationBarTitle(.static(title), displayMode: .inline)
    }

    private func cell(title: String, subtitle: String) -> some View {
        return VStack(alignment: .leading) {
            HStack {
                Text(.static(title))
                    .font(.headline)
                Spacer()
            }
            Text(.static(subtitle))
                .font(.caption)
        }
            .padding(16)
            .card()
            .padding(8)
    }

    private func lastTraces() throws -> ViewFuture {
        return traceProvider.traces(for: TraceQuery(service: "gateway", maxCount: 10))
            .map { traces in
                VStack {
                    traces.map { trace in
                        self.traceView(for: trace)
                    }
                }
            }
    }

    private func dependencies() throws -> ViewFuture {
        let startDate = Date().addingTimeInterval(-24 * 60 * 60)
        return traceProvider.dependencies(from: startDate)
            .map { dependencies in
                VStack {
                    dependencies.map { dependency in
                        Text(.static(dependency.parent + " -\(dependency.callCount)-> " + dependency.child))
                    }
                }
            }
    }

    private func traceView(for trace: Trace) -> some View {
        guard let root = trace.rootSpan else {
            return VStack {
                Text("No root span.")
                    .padding(8)
                Divider()
            }
        }

        return VStack {
            VStack {
                trace.spans.map { span in
                    spanRow(root: root, for: span)
                }
            }.padding(8)
            Divider()
        }
    }

    private func spanRow(root: Span, for span: Span) -> some View {
        let startOffset = -span.startTime.timeIntervalSince(root.startTime)
        let duration = span.duration
        return HStack {
            Text(.static(span.name))
                .font(.headline)
            Spacer()
            Text(.static(startOffset.description + "s - " + duration.description + "s"))
                .font(.caption)
        }
    }

    private func service(title: String, cards: [ViewFuture]) -> ViewFuture {
        EventLoopFuture.whenAllSucceed(cards, on: eventLoop)
        .map { cards in
            ScrollView {
                VStack {
                    cards
                }.padding(8)
            }.navigationBarTitle(.static(title))
        }
    }

    private func metricsRequests(job: String) -> ViewFuture {
        let counter = Counter(label: "http_requests_total",
                              dimensions: ["job": job, "path": "GET /metrics"])

        let range = TimeRange.range(.days(3), step: .hours(1))
        let query = counter.query(scalar: .delta(counter[range.step]))
        return graph(for: query.in(range), title: "GET /metrics")
    }

    private func graph(for query: RangeQuery<Analyst.Counter>, title: String? = nil) -> ViewFuture {
        metricsProvider.results(for: query)
        .map { self.view(for: $0, title: title ?? query.label) }
    }

    private func graph(for query: RangeQuery<Analyst.Timer>, title: String? = nil) -> ViewFuture {
        metricsProvider.results(for: query)
            .map { self.view(for: $0, title: title ?? query.label) }
    }

    private func view(for results: [RangeResult], title: String) -> some View {
        GraphCard(configuration: Color.systemColorGraphConfiguration, results: results)
            .view(title: title, subtitle: "")
    }
}


struct GatewayPresenterConfiguration: Configuration {
    let jaegerURL: URL
    let prometheusURL: URL
    let processingURL: URL
    let databaseURL: URL
    
    public init(
        jaegerURL: URL,
        prometheusURL: URL,
        processingURL: URL,
        databaseURL: URL
    ) {
        self.jaegerURL = jaegerURL
        self.prometheusURL = prometheusURL
        self.processingURL = processingURL
        self.databaseURL = databaseURL
    }
    
    public func configure(_ app: Application) {
        app.presenterService = GatewayPresenterService(
            client: app.httpClient,
            jaegerURL: jaegerURL,
            prometheusURL: prometheusURL,
            processingURL: processingURL,
            databaseURL: databaseURL
        )
    }
}
