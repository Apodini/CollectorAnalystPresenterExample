import AnalystPresenter
import NIO


extension Trace {
    var rootSpan: Span? {
        spans.first { $0.references.isEmpty }
    }

    var id: UUID {
        rootSpan!.context.traceID
    }

    var name: String {
        rootSpan!.name
    }

    var duration: TimeInterval {
        rootSpan!.duration
    }
}


extension Span {
    var id: UUID {
        context.spanID
    }

    var traceID: UUID {
        context.traceID
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}


typealias ViewFuture = EventLoopFuture<_CodableView>


extension Color {
    static var lightGray: Color {
        Color(red: 0.75, green: 0.75, blue: 0.75)
    }

    static var black: Color {
        Color(red: 0, green: 0, blue: 0)
    }
}


extension UIMetricsService {
    func service(title: String, cards: [ViewFuture]) -> ViewFuture {
        EventLoopFuture.whenAllSucceed(cards, on: eventLoop)
        .map { cards in
            ScrollView {
                VStack {
                    cards
                }
                .padding(8)
            }
            .navigationBarTitle(.static(title))
        }
    }

    func metricsRequests(job: String) -> ViewFuture {
        let counter = Counter(label: "http_requests_total",
                              dimensions: ["job": job, "path": "GET /metrics"])

        let range = TimeRange.range(.days(3), step: .hours(1))
        let query = counter.query(scalar: .delta(counter[range.step]))
        return graph(for: query.in(range), title: "GET /metrics")
    }

    func graph(for query: RangeQuery<Analyst.Counter>, title: String? = nil) -> ViewFuture {
        metricsProvider.results(for: query)
        .map { self.view(for: $0, title: title ?? query.label) }
    }

    func graph(for query: RangeQuery<Analyst.Gauge>, title: String? = nil) -> ViewFuture {
        metricsProvider.results(for: query)
        .map { self.view(for: $0, title: title ?? query.label) }
    }

    func graph(for query: RangeQuery<Analyst.Recorder>, title: String? = nil) -> ViewFuture {
        metricsProvider.results(for: query)
        .map { self.view(for: $0, title: title ?? query.label) }
    }

    func graph(for query: RangeQuery<Analyst.Timer>, title: String? = nil) -> ViewFuture {
        metricsProvider.results(for: query)
        .map { self.view(for: $0, title: title ?? query.label) }
    }

    private func view(for results: [RangeResult], title: String) -> some View {
        GraphCard(configuration: self.configuration, results: results)
        .view(title: title, subtitle: "")
    }

    private var configuration: GraphConfiguration {
        PrometheusGraphConfiguration(styles:
            colors.map { color in
                (.line(.init(.quadCurve, color: color, width: 2)), color)
            }
        )
    }

    private var colors: [Color] {
        [
            .systemBlue,
            .systemIndigo,
            .systemOrange,
            .systemPink,
            .systemPurple,
            .systemRed,
            .systemTeal
        ]
    }

}


extension Color {
    static var systemBlue: Color {
        .init(red: 0 / 255, green: 122 / 255, blue: 255 / 255)
    }

    static var systemIndigo: Color {
        .init(red: 88 / 255, green: 86 / 255, blue: 214 / 255)
    }

    static var systemOrange: Color {
        .init(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
    }

    static var systemPink: Color {
        .init(red: 255 / 255, green: 45 / 255, blue: 85 / 255)
    }

    static var systemPurple: Color {
        .init(red: 175 / 255, green: 82 / 255, blue: 222 / 255)
    }

    static var systemRed: Color {
        .init(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    }

    static var systemTeal: Color {
        .init(red: 90 / 255, green: 200 / 255, blue: 250 / 255)
    }
}
