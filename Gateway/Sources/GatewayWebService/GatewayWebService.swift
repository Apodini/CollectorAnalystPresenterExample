import Apodini
import ApodiniAnalystPresenter
import ApodiniCollector
import ApodiniJobs
import ApodiniREST
import ArgumentParser
import Foundation


@main
struct GatewayWebService: WebService {
    @Option var port: Int = 80
    @Option var jaegerURL: URL = URL(string: "http://jaeger:14250/")!
    @Option var prometheusURL: URL = URL(string: "http://gatewayprometheus:9090/")!
    @Option var processingServiceURL: URL = URL(string: "http://processing:80/")!
    @Option var databaseServiceURL: URL = URL(string: "http://database:80/")!
    
    @PathParameter var userId: Int
    
    
    var configuration: Apodini.Configuration {
        // Configure the HTTP port based on the passed in arguments
        HTTPConfiguration(port: port)
        
        // We eexpose a RESTful API
        REST()
        
        // Configure the Gateway UI Service with the passed in arguments
        GatewayPresenterConfiguration(
            jaegerURL: jaegerURL,
            prometheusURL: prometheusURL,
            processingURL: processingServiceURL,
            databaseURL: databaseServiceURL
        )
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "processing",
            jaegerURL: jaegerURL
        )
        
        // Configure the remote database serrvice with the passed in arguments
        RemoveConnectionServiceConfiguration(
            databaseURL: databaseServiceURL,
            processingURL: processingServiceURL
        )
        
        Schedule(MetricsJob(), on: "* * * * *", \KeyStore.metricsJob)
    }

    
    var content: some Component {
        Group("user", $userId, "hotspots") {
            ReadHotspotsHandler(userID: $userId)
        }
        Group("user", $userId, "location") {
            CreateUserLocationHandler(userID: $userId)
        }
        Group("metrics-ui") {
            MetricsUIHandler()
        }
        Group("metrics") {
            MetricsHandler()
        }
    }
}
