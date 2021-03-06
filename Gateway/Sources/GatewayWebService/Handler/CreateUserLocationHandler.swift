//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniCollector


struct CreateUserLocationHandler: Handler {
    @Environment(\.connectionService) var connectionService: ConnectionService
    
    @Binding var userID: Int
    @Parameter var location: Coordinate
    
    @Throws(.serverError, reason: "Could not save the location")
    var serverError: ApodiniError
    
    
    func handle() throws -> EventLoopFuture<Coordinate> {
        do {
            Metric.counter(label: "location_usage", dimensions: ["userID": userID.description]).increment()
            Metric.gauge(label: "location_latitude", dimensions: ["userID": userID.description]).record(location.latitude)
            Metric.gauge(label: "location_longitude", dimensions: ["userID": userID.description]).record(location.longitude)
            
            return try connectionService.add(location, userID: userID)
        } catch {
            throw serverError
        }
    }
}
