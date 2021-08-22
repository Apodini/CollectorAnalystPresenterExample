//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

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
