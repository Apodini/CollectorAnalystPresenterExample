// swift-tools-version:5.4

import PackageDescription


let package = Package(
    name: "ProcessingWebService",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "ProcessingWebService",
            targets: ["ProcessingWebService"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/Apodini/ApodiniAsyncHTTPClient.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/NSHipster/DBSCAN", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/Apodini/ApodiniCollector.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/Apodini/ApodiniAnalystPresenter.git", .upToNextMinor(from: "0.2.0"))
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
