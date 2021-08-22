//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import DBSCAN
import Foundation


protocol ProcessingService {
    func hotspots(in location: [Coordinate]) throws -> [Coordinate]
}


class DefaultProcessingService: ProcessingService {
    func hotspots(in locations: [Coordinate]) throws -> [Coordinate] {
        let scan = DBSCAN(locations)
        let (clusters, _) = scan(epsilon: 20,
                                 minimumNumberOfPoints: 10,
                                 distanceFunction: distance)
        return clusters.map { content in
            let latitude = content.reduce(0) { $0 + $1.latitude } / Double(content.count)
            let longitude = content.reduce(0) { $0 + $1.longitude } / Double(content.count)
            return Coordinate(latitude: latitude, longitude: longitude)
        }
    }

    private func distance(between first: Coordinate,
                          and second: Coordinate) -> Double {
        let latitudeDelta = (first.latitude - second.latitude) * 0.00001
        let longitudeDelta = (first.longitude - second.longitude) * 0.00001
        return sqrt(latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta)
    }
}


private struct ProcessingServiceStorageKey: StorageKey {
    typealias Value = ProcessingService
}


extension Apodini.Application {
    var processingService: ProcessingService {
        guard let processingService = self.storage[ProcessingServiceStorageKey.self] else {
            self.storage[ProcessingServiceStorageKey.self] = DefaultProcessingService()
            return self.processingService
        }
        
        return processingService
    }
}
