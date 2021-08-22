//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniCollector


struct ReadHotspotsHandler: Handler {
    @Environment(\.connectionService) var connectionService: ConnectionService
    
    @Binding var userID: Int
    
    @Throws(.notFound, reason: "Could not load the hotspots")
    var notFound: ApodiniError
    
    
    func handle() throws -> EventLoopFuture<[Coordinate]> {
        do {
            Metric.counter(label: "hotspots_usage", dimensions: ["userID": userID.description]).increment()
            
            return try connectionService.hotspots(userID: userID)
        } catch {
            throw notFound
        }
    }
}
