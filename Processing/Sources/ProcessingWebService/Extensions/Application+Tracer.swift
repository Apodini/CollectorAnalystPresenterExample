import Apodini
import JaegerCollector


fileprivate struct TracerStorageKey: StorageKey {
    typealias Value = Tracer
}


struct TracerConfiguration: Apodini.Configuration {
    let serviceName: String
    let jaegerHostname: String
    let jaegerCollectorPort: Int
    
    
    init(serviceName: String, jaegerHostname: String, jaegerCollectorPort: Int) {
        self.serviceName = serviceName
        self.jaegerHostname = jaegerHostname
        self.jaegerCollectorPort = jaegerCollectorPort
    }
    
    
    func configure(_ app: Application) {
        let channel = ClientConnection.insecure(group: app.eventLoopGroup)
            .connect(host: jaegerHostname, port: jaegerCollectorPort)
        
        let sender = JaegerSender(serviceName: serviceName, tags: [:], channel: channel)
        let agent = BasicAgent(interval: 60, sender: sender)
        
        app.storage[TracerStorageKey.self] = BasicTracer(agent: agent)
    }
}


extension Application {
    var tracer: Tracer {
        guard let tracer = self.storage[TracerStorageKey.self] else {
            fatalError("You need to add a TracerConfiguration to the WebService configuration to use the tracer in the Environment")
        }
        
        return tracer
    }
}
