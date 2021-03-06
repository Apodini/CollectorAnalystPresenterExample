//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import JaegerCollector


struct CreateUserLocationHandler: Handler {
    @Environment(\.databaseService) var databaseService: DatabaseService
    @Environment(\.tracer) var tracer: Tracer
    @Environment(\.connection) var connection: Connection
    
    @Binding var userID: Int
    @Parameter var location: Coordinate
    
    @Throws(.notFound, reason: "The specified user location could not be found")
    var notFound: ApodiniError
    
    
    func handle() -> EventLoopFuture<Coordinate> {
        let span = tracer.span(name: "location", from: connection)
        
        Metric
            .counter(label: "location_usage", dimensions: ["method": "POST", "path": "/user/{id}/locations"])
            .increment()
        
        return databaseService.add(location, userID: userID)
            .always { _ in
                span.finish()
            }
            .flatMapErrorThrowing { _ in
                throw notFound
            }
    }
}
