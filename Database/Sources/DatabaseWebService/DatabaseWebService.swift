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
    @Option var port: Int = 81
    @Option var jaegerCollectorURL: URL = URL(string: "http://localhost:14250")!
    @Option var prometheusURL: URL = URL(string: "http://localhost:9091")!
    
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
                label: "location_usage",
                dimensions: ["job": "database"]
            ),
            title: "Total Database Usage"
        )
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "database",
            jaegerURL: jaegerCollectorURL
        )
    }

    
    var content: some Component {
        Group("user", $userId, "locations") {
            ReadUserLocationHandler(userID: $userId)
                .operation(.read)
            CreateUserLocationHandler(userID: $userId)
                .operation(.create)
        }
        Group("metrics-ui") {
            PresenterHandler()
        }
        Group("metrics") {
            MetricsHandler()
        }
    }
}
