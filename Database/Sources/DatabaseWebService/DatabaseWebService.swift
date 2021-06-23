import Apodini
import ApodiniREST
import ApodiniDatabase
import ArgumentParser
import Foundation


@main
struct DatabaseWebService: WebService {
    @Option var port: Int = 80
    @Option var jaegerHostname: String = "jaeger"
    @Option var jaegerCollectorPort: Int = 14250
    @Option var jaegerAnalystPort: Int = 16686
    @Option var prometheusURL: URL = URL(string: "http://prometheus:9090/")!
    
    @PathParameter var userId: Int
    
    
    var configuration: Apodini.Configuration {
        // Configure the HTTP port based on the passed in arguments
        HTTPConfiguration(port: port)
        
        // We eexpose a RESTful API
        REST()
        
        // Databasee Configuration
        DatabaseConfiguration(.sqlite(.memory))
            .addMigrations(UserLocationModel())
        
        // Configure the UI Metrics Service with the passed in arguments
        UIMetricsServiceConfiguration(
            jaegerHostname: jaegerHostname,
            jaegerAnalystPort: jaegerCollectorPort,
            prometheusURL: prometheusURL
        )
        
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "database",
            jaegerHostname: jaegerHostname,
            jaegerCollectorPort: jaegerCollectorPort
        )
    }

    
    var content: some Component {
        Group("user", $userId, "hotspots") {
            ReadUserLocationHandler(userID: $userId)
                .operation(.read)
            CreateUserLocationHandler(userID: $userId)
                .operation(.create)
        }
        Group("metrics-ui") {
            MetricsUIHandler()
        }
        Group("metrics") {
            MetricsHandler()
        }
    }
}
