import Apodini
import ApodiniAnalystPresenter
import ApodiniCollector
import ApodiniREST
import ArgumentParser
import Foundation


@main
struct ProcessingWebService: WebService {
    @Option var port: Int = 82
    @Option var jaegerCollectorURL: URL = URL(string: "http://localhost:14250")!
    @Option var prometheusURL: URL = URL(string: "http://localhost:9092")!
    @Option var databaseServiceURL: URL = URL(string: "http://localhost:81")!
    
    @PathParameter var userId: Int
    
    
    var configuration: Apodini.Configuration {
        // Configure the HTTP port based on the passed in arguments
        HTTPConfiguration(port: port)
        
        // We eexpose a RESTful API
        REST()
        
        // Configure the UI Metrics Service with the passed in arguments
        MetricsPresenterConfiguration(
            prometheusURL: prometheusURL,
            metric: Counter(
                label: "hotspots_usage",
                dimensions: ["job": "processing", "path": "user/{id}/hotspots"]
            ),
            title: "Processing"
        )
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "processing",
            jaegerURL: jaegerCollectorURL
        )
        
        // Configure the remote database serrvice with the passed in arguments
        RemoteDatabaseServiceConfiguration(
            databaseServiceURL: databaseServiceURL
        )
    }

    
    var content: some Component {
        Group("user", $userId, "hotspots") {
            ReadHotspotsHandler(userID: $userId)
        }
        Group("metrics-ui") {
            PresenterHandler()
        }
        Group("metrics") {
            MetricsHandler()
        }
    }
}
