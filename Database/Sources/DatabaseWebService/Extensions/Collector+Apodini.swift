import Apodini
import JaegerCollector


private struct ConnectionExtractor: Extractor {
    func extract(key: String, from carrier: Connection) -> String? {
        carrier.information[key]
    }
}

private struct ResponseInjector<C: Encodable>: Injector {
    func inject(_ value: String, forKey key: String, into carrier: inout Response<C>) {
        carrier.information.insert(.custom(key: key, rawValue: value))
    }
}

extension Tracer {
    public func span(name: String, from connection: Connection) -> Span {
        span(name: name, from: connection, using: ConnectionExtractor())
    }
}

extension Span {
    public func propagate<C: Encodable>(in response: inout Response<C>) {
        propagate(in: &response, using: ResponseInjector<C>())
    }
}
