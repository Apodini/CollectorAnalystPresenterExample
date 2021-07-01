import Apodini
import ApodiniREST
import Apodini
import ApodiniAnalystPresenter
import ApodiniCollector
import ApodiniDatabase
import ArgumentParser
import Foundation


@main
struct DatabaseWebService: WebService {
    @Option var port: Int = 80
    @Option var jaegerURL: URL = URL(string: "http://jaeger:14250/")!
    @Option var prometheusURL: URL = URL(string: "http://databaseprometheus:9090/")!
    
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
        MetricsPresenterConfiguration(
            prometheusURL: prometheusURL,
            metric: Counter(
                label: "http_requests_total",
                dimensions: ["job": "database", "path": "GET /metrics"]
            ),
            title: "Database"
        )
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "database",
            jaegerURL: jaegerURL
        )
    }

    
    var content: some Component {
        Group("user", $userId, "location") {
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
