import FluentSQLiteDriver
import Foundation


final class UserLocationModel: Model, Codable {
    static let schema = String(describing: UserLocationModel.self)

    
    init() {}

    
    @ID
    var id: UUID?

    @Field(key: "userID")
    var userID: Int

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double
}


extension UserLocationModel: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database
        .schema(UserLocationModel.schema)
        .field(.id, .uuid, .identifier(auto: true))
        .field("userID", .int)
        .field("latitude", .double)
        .field("longitude", .double)
        .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database
        .schema(UserLocationModel.schema)
        .delete()
    }
}
