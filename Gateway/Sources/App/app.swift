import Vapor

/// Creates an instance of `Application`. This is called from `main.swift` in the run target.
public func app(_ env: Environment) throws -> Application {
    let app = Application(env, .createNew)
    try configure(app)
    return app
}

enum Configuration {
    static let jaegerHostname = "jaeger"
    static let jaegerCollectorPort = 14250
    static let jaegerAnalystPort = 16686
    static let prometheusURL = URL(string: "http://prometheus:9090/")!
}
