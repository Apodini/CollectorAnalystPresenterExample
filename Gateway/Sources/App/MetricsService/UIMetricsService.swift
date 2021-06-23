import AsyncHTTPClient
import AnalystPresenter
import NIO
import PrometheusAnalyst
import JaegerAnalyst

protocol MetricsService {
    func view() throws -> EventLoopFuture<Data>
}

final class UIMetricsService: MetricsService {

    // MARK: Stored Properties

    let metricsProvider: Prometheus
    let traceProvider: TraceProvider
    let client: HTTPClient

    // MARK: Computed Properties

    var eventLoop: EventLoop {
        metricsProvider.client.eventLoopGroup.next()
    }

    // MARK: Initialization

    public init(client: HTTPClient) {
        Presenter.use(plugin: AnalystPresenter())

        self.client = client

        let channel = ClientConnection.insecure(group: client.eventLoopGroup)
            .connect(host: Configuration.jaegerHostname, port: Configuration.jaegerAnalystPort)

        self.traceProvider = JaegerProvider(channel: channel)

        self.metricsProvider = Prometheus(
            baseURL: Configuration.prometheusURL,
            client: client
        )
    }

    // MARK: Nested Types

    func view() throws -> EventLoopFuture<Data> {
        try listView()
        .flatMapThrowing { try Presenter.encode(CoderView($0)) }
    }

    private func listView() throws -> ViewFuture {
        EventLoopFuture<(_CodableView, _CodableView, _CodableView)>
        .combine(try gateway(), try database(), try processing())
        .map { self.listView(gateway: $0, database: $1, processing: $2) }
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
            url: "http://database:80/metrics-ui",
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
            url: "http://processing:80/metrics-ui",
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
            }
            .padding(8)
        }
        .navigationBarTitle(.static(title), displayMode: .inline)
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
            }
            .padding(8)
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

}

extension EventLoopFuture {

    static func combine<A, B>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>
    ) -> EventLoopFuture<(A, B)> where Value == (A, B) {

        a.flatMap { aValue in b.map { (aValue, $0) } }
    }

    static func combine<A, B, C>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>
    ) -> EventLoopFuture<(A, B, C)> where Value == (A, B, C) {
        EventLoopFuture<(A, B)>.combine(a, b)
        .flatMap { aValue, bValue in c.map { (aValue, bValue, $0) } }
    }

    static func combine<A, B, C, D>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>,
        _ d: EventLoopFuture<D>
    ) -> EventLoopFuture<(A, B, C, D)> where Value == (A, B, C, D) {

        EventLoopFuture<((A, B), (C, D))>
        .combine(.combine(a, b), .combine(c, d))
        .map { abValues, cdValues in (abValues.0, abValues.1, cdValues.0, cdValues.1) }
    }

    static func combine<A, B, C, D, E>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>,
        _ d: EventLoopFuture<D>,
        _ e: EventLoopFuture<E>
    ) -> EventLoopFuture where Value == (A, B, C, D, E) {

        EventLoopFuture<((A, B), (C, D, E))>
        .combine(.combine(a, b), .combine(c, d, e))
        .map { abValues, cdeValues in (abValues.0, abValues.1, cdeValues.0, cdeValues.1, cdeValues.2) }
    }

    static func combine<A, B, C, D, E, F>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>,
        _ d: EventLoopFuture<D>,
        _ e: EventLoopFuture<E>,
        _ f: EventLoopFuture<F>
    ) -> EventLoopFuture where Value == (A, B, C, D, E, F) {

        EventLoopFuture<((A, B, C), (D, E, F))>
        .combine(.combine(a, b, c), .combine(d, e, f))
        .map { first, second in (first.0, first.1, first.2, second.0, second.1, second.2) }
    }

}
