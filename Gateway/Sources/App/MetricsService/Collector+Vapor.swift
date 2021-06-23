import Collector
import Vapor

private struct VaporRequestModifier: Extractor, Injector {

    func extract(key: String, from carrier: Request) -> String? {
        carrier.headers.first(name: key)
    }

    func inject(_ value: String, forKey key: String, into carrier: inout Request) {
        carrier.headers.replaceOrAdd(name: key, value: value)
    }

}

extension Tracer {

    public func span(name: String, from request: Request) -> Span {
        span(name: name, from: request, using: VaporRequestModifier())
    }

}

extension Span {

    public func propagate(in request: inout Request) {
        propagate(in: &request, using: VaporRequestModifier())
    }

}
