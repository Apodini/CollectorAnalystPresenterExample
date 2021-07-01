import Apodini
import ApodiniCollector


struct ReadHotspotsHandler: Handler {
    @Environment(\.connectionService) var connectionService: ConnectionService
    
    @Binding var userID: Int
    
    @Throws(.notFound, reason: "Could not load the hotspots")
    var notFound: ApodiniError
    
    
    func handle() throws -> EventLoopFuture<[Coordinate]> {
        do {
            Metric.counter(label: "hotspots_usage_count", dimensions: ["userID": userID.description]).increment()
            
            return try connectionService.hotspots(userID: userID)
        } catch {
            throw notFound
        }
    }
}
