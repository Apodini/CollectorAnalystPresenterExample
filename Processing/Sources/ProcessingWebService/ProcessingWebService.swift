import Apodini
import ApodiniREST
import ArgumentParser
import Foundation


@main
struct ProcessingWebService: WebService {
    @Option var port: Int = 80
    @Option var jaegerHostname: String = "jaeger"
    @Option var jaegerCollectorPort: Int = 14250
    @Option var jaegerAnalystPort: Int = 16686
    @Option var prometheusURL: URL = URL(string: "http://prometheus:9090/")!
    @Option var databaseHostname: String = "database"
    @Option var databasePort: Int = 80
    
    @PathParameter var userId: Int
    
    
    var configuration: Apodini.Configuration {
        // Configure the HTTP port based on the passed in arguments
        HTTPConfiguration(port: port)
        
        // We eexpose a RESTful API
        REST()
        
        // Configure the UI Metrics Service with the passed in arguments
        UIMetricsServiceConfiguration(
            jaegerHostname: jaegerHostname,
            jaegerAnalystPort: jaegerCollectorPort,
            prometheusURL: prometheusURL
        )
        
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "processing",
            jaegerHostname: jaegerHostname,
            jaegerCollectorPort: jaegerCollectorPort
        )
        
        // Configure the remote database serrvice with the passed in arguments
        RemoteDatabaseServiceConfiguration(
            hostname: databaseHostname,
            port: databasePort
        )
    }

    
    var content: some Component {
        Group("user", $userId, "hotspots") {
            ReadHotspotsHandler(userID: $userId)
        }
        Group("metrics-ui") {
            MetricsUIHandler()
        }
        Group("metrics") {
            MetricsHandler()
        }
    }
}
