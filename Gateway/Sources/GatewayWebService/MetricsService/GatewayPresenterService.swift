//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

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
    var view: _CodableView { // swiftlint:disable all
        get async throws { // We disable all SwiftLint lint rules for this section as SwiftLint wrogfully triggers a few rules here.
            do {
                return try await listView()
            } catch {
                return Text("Could not generate Presenter UI: \(error)")
            }
        }
    }
    var encodedView: Blob {
        get async throws { // swiftlint:disable:this implicit_getter
            let data = try Presenter.encode(CoderView(try await view))
            return Blob(data, type: .application(.json))
        }
    } // swiftlint:enable all
    
    
    init(
        client: HTTPClient,
        jaegerURL: URL,
        prometheusURL: URL,
        processingURL: URL,
        databaseURL: URL
    ) {
        Presenter.use(plugin: AnalystPresenter())
        Presenter.use(view: CoderView.self)
        
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

    private func listView() async throws -> _CodableView {
        async let gateway = gateway()
        async let database = database()
        async let processing = processing()
        
        return try await self.listView(gateway: gateway, database: database, processing: processing)
    }

    private func listView(gateway: _CodableView, database: _CodableView, processing: _CodableView) -> some View {
        NavigationView {
            ScrollView {
                VStack {
                    NavigationLink(
                        destination: CoderView(gateway),
                        isActive: .at("gateway.isActive", default: false),
                        label: self.cell(title: "Gateway", subtitle: "Web Service")
                    )

                    NavigationLink(
                        destination: CoderView(database),
                        isActive: .at("database.isActive", default: false),
                        label: self.cell(title: "Database", subtitle: "Web Service")
                    )

                    NavigationLink(
                        destination: CoderView(processing),
                        isActive: .at("processing.isActive", default: false),
                        label: self.cell(title: "Processing", subtitle: "Web Service")
                    )
                }
                .padding(8)
            }
            .navigationBarTitle(.static("System Status"))
        }
    }

    private func database() async -> _CodableView {
        do {
            let response = try await client.execute(request: try HTTPClient.Request(url: databaseURL.appendingPathComponent("/v1/metrics-ui"))).get()
            
            guard let body = response.body else {
                return Text(.static("Database UI could not be loaded"))
            }
            return DataView(.init(buffer: body))
        } catch {
            return Text(.static("Error"))
        }
    }

    private func processing() async -> _CodableView {
        do {
            let response = try await client.execute(request: try HTTPClient.Request(url: processingURL.appendingPathComponent("/v1/metrics-ui")))
                .get()
            
            guard let body = response.body else {
                return Text(.static("Processing UI could not be loaded"))
            }
            return DataView(.init(buffer: body))
        } catch {
            return Text(.static("Error"))
        }
    }

    private func gateway() async throws -> _CodableView {
        try await service(title: "Gateway", cards: [
            metricsCounterGraph(label: "location_usage", title: "Location Usage"),
            metricsCounterGraph(label: "hotspots_usage", title: "Hotspots Usage"),
            periodicTaskDuration(),
            try dependencies(),
            try lastTraces()
        ])
    }

    private func periodicTaskDuration() async throws -> _CodableView {
        let timer = Timer(label: "gateway_periodic_task_duration")
        let range = TimeRange.range(.days(3), step: .hours(1))
        let query = timer.query(scalar: .delta(timer[range.step]))
        return try await graph(for: query.in(range), title: "Periodic Task Duration")
    }

    private func list<C: Sequence, Cell: View>(
        _ title: String,
        for sequence: C,
        create: (C.Element) -> Cell
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                sequence.map(create)
            }.padding(8)
        }.navigationBarTitle(.static(title), displayMode: .inline)
    }

    private func cell(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading) {
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

    private func lastTraces() async throws -> _CodableView {
        let traces = try await traceProvider.traces(for: TraceQuery(service: "gateway", maxCount: 10)).get()
        return VStack {
            traces.map { trace in
                self.traceView(for: trace)
            }
        }
    }

    private func dependencies() async throws -> _CodableView {
        let startDate = Date().addingTimeInterval(-24 * 60 * 60)
        let dependencies = try await traceProvider.dependencies(from: startDate).get()
        
        return VStack {
            dependencies.map { dependency in
                Text(.static(dependency.parent + " -\(dependency.callCount)-> " + dependency.child))
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

    private func service(title: String, cards: [_CodableView]) -> _CodableView {
        ScrollView {
            VStack {
                cards
            }.padding(8)
        }.navigationBarTitle(.static(title))
    }

    private func metricsCounterGraph(label: String, title: String? = nil) async throws -> _CodableView {
        let counter = Counter(
            label: label,
            dimensions: ["job": "gateway"]
        )

        let range = TimeRange.range(.days(3), step: .hours(1))
        let query = counter.query(scalar: .delta(counter[range.step]))
        return try await graph(for: query.in(range), title: title ?? label)
    }

    private func graph(for query: RangeQuery<Analyst.Counter>, title: String? = nil) async throws -> _CodableView {
        let results = try await metricsProvider.results(for: query).get()
        return self.view(for: results, title: title ?? query.label)
    }

    private func graph(for query: RangeQuery<Analyst.Timer>, title: String? = nil) async throws -> _CodableView {
        let results = try await metricsProvider.results(for: query).get()
        return self.view(for: results, title: title ?? query.label)
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
    
    init(
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
    
    func configure(_ app: Application) {
        app.presenterService = GatewayPresenterService(
            client: app.httpClient,
            jaegerURL: jaegerURL,
            prometheusURL: prometheusURL,
            processingURL: processingURL,
            databaseURL: databaseURL
        )
    }
}
