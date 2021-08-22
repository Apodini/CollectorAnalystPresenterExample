//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

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
    @Option var jaegerCollectorURL = URL(string: "http://localhost:14250")! // swiftlint:disable:this force_unwrapping
    @Option var jaegerQueryURL = URL(string: "http://localhost:16685")! // swiftlint:disable:this force_unwrapping
    @Option var prometheusURL = URL(string: "http://localhost:9090")! // swiftlint:disable:this force_unwrapping
    @Option var processingServiceURL = URL(string: "http://localhost:82")! // swiftlint:disable:this force_unwrapping
    @Option var databaseServiceURL = URL(string: "http://localhost:81")! // swiftlint:disable:this force_unwrapping
    
    @PathParameter var userId: Int
    
    
    var configuration: Apodini.Configuration {
        // Configure the HTTP port based on the passed in arguments
        HTTPConfiguration(port: port)
        
        // We eexpose a RESTful API
        REST()
        
        // Configure the Gateway UI Service with the passed in arguments
        GatewayPresenterConfiguration(
            jaegerURL: jaegerQueryURL,
            prometheusURL: prometheusURL,
            processingURL: processingServiceURL,
            databaseURL: databaseServiceURL
        )
        // Configure the Tracer with the passed in arguments
        TracerConfiguration(
            serviceName: "processing",
            jaegerURL: jaegerCollectorURL
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
        Group("user", $userId, "locations") {
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
