import Foundation
import Vapor

struct Coordinate: Codable, Content {
    var latitude: Double
    var longitude: Double
}

protocol ConnectionService {
    func add(_ coordinate: Coordinate, userID: Int) throws -> EventLoopFuture<Coordinate>
    func hotspots(userID: Int) throws -> EventLoopFuture<[Coordinate]>
}
