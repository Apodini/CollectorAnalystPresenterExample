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
    name: "ProcessingWebService",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ProcessingWebService",
            targets: ["ProcessingWebService"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.6.2")),
        .package(url: "https://github.com/Apodini/ApodiniAsyncHTTPClient.git", .upToNextMinor(from: "0.3.2")),
        .package(url: "https://github.com/NSHipster/DBSCAN", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/Apodini/ApodiniCollector.git", .upToNextMinor(from: "0.3.2")),
        .package(url: "https://github.com/Apodini/ApodiniAnalystPresenter.git", .upToNextMinor(from: "0.3.2"))
    ],
    targets: [
        .executableTarget(
            name: "ProcessingWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniAsyncHTTPClient", package: "ApodiniAsyncHTTPClient"),
                .product(name: "ApodiniCollector", package: "ApodiniCollector"),
                .product(name: "ApodiniAnalystPresenter", package: "ApodiniAnalystPresenter"),
                .product(name: "DBSCAN", package: "DBSCAN")
            ]
        ),
        .testTarget(
            name: "ProcessingWebServiceTests",
            dependencies: [
                .target(name: "ProcessingWebService")
            ]
        )
    ]
)
