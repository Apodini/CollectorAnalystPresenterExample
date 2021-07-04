// swift-tools-version:5.4

import PackageDescription


let package = Package(
    name: "GatewayWebService",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "GatewayWebService",
            targets: ["GatewayWebService"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/Apodini/ApodiniAsyncHTTPClient.git", .upToNextMinor(from: "0.1.1")),
        .package(url: "https://github.com/Apodini/ApodiniCollector.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/Apodini/ApodiniAnalystPresenter.git", .upToNextMinor(from: "0.1.0"))
    ],
    targets: [
        .executableTarget(
            name: "GatewayWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniJobs", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniAsyncHTTPClient", package: "ApodiniAsyncHTTPClient"),
                .product(name: "ApodiniCollector", package: "ApodiniCollector"),
                .product(name: "ApodiniAnalystPresenter", package: "ApodiniAnalystPresenter")
            ]
        ),
        .testTarget(
            name: "GatewayWebServiceTests",
            dependencies: [
                .target(name: "GatewayWebService")
            ]
        )
    ]
)
