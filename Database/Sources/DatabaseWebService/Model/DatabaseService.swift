import Apodini
import FluentSQLiteDriver


protocol DatabaseService {
    func add(_ location: Coordinate, userID: Int) -> EventLoopFuture<Coordinate>
    func query(userID: Int) -> EventLoopFuture<[Coordinate]>
}


final class FluentDatabaseService: DatabaseService {
    let database: Database

    
    init(database: Database) {
        self.database = database
    }


    func add(_ location: Coordinate, userID: Int) -> EventLoopFuture<Coordinate> {
        let model = UserLocationModel()
        model.userID = userID
        model.latitude = location.latitude
        model.longitude = location.longitude
        return model.create(on: database)
            .map { location }
    }

    func query(userID: Int) -> EventLoopFuture<[Coordinate]> {
        UserLocationModel.query(on: database)
            .filter(\.$userID == userID)
            .all()
            .map {
                $0.map {
                    Coordinate(latitude: $0.latitude,
                               longitude: $0.longitude)
                }
            }
    }

}


fileprivate struct DatabaseServiceStorageKey: StorageKey {
    typealias Value = DatabaseService
}


extension Apodini.Application {
    var databaseService: DatabaseService {
        guard let databaseService = self.storage[DatabaseServiceStorageKey.self] else {
            self.storage[DatabaseServiceStorageKey.self] = FluentDatabaseService(database: self.database)
            return self.databaseService
        }
        
        return databaseService
    }
}
