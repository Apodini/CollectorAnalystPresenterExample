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
import ApodiniDatabase
import ApodiniREST
import ArgumentParser
import FluentSQLiteDriver
import Foundation


@main
struct DatabaseWebService: WebService {
    @Option var port: Int = 81
    @Option var jaegerCollectorURL = URL(string: "http://localhost:14250")! // swiftlint:disable:this force_unwrapping
    @Option var prometheusURL = URL(string: "http://localhost:9091")! // swiftlint:disable:this force_unwrapping
    
    @PathParameter var userId: Int
    
    
    var configuration: Apodini.Configuration {
        // Configure the HTTP port based on the passed in arguments
        HTTPConfiguration(bindAddress: .interface(port: port))
        
        // We eexpose a RESTful API
        REST()
        
        // Databasee Configuration
        DatabaseConfiguration(.sqlite(.memory), as: .sqlite)
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
