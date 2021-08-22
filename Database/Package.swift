// swift-tools-version:5.5

//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import PackageDescription


let package = Package(
    name: "DatabaseWebService",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DatabaseWebService",
            targets: [
                "DatabaseWebService"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.4.1")),
        .package(url: "https://github.com/Apodini/ApodiniCollector.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/Apodini/ApodiniAnalystPresenter.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.1.0")
    ],
    targets: [
        .executableTarget(
            name: "DatabaseWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniDatabase", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniCollector", package: "ApodiniCollector"),
                .product(name: "ApodiniAnalystPresenter", package: "ApodiniAnalystPresenter"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ]
        ),
        .testTarget(
            name: "DatabaseWebServiceTests",
            dependencies: [
                .target(name: "DatabaseWebService")
            ]
        )
    ]
)
