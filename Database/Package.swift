// swift-tools-version:5.4
import PackageDescription


let package = Package(
    name: "DatabaseWebService",
    platforms: [
        .macOS(.v10_15)
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
        .package(url: "https://github.com/Apodini/Analyst.git", from: "0.1.0"),
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/Apodini/ApodiniAsyncHTTPClient.git", from: "0.1.1"),
        .package(url: "https://github.com/Apodini/Collector.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "DatabaseWebService",
            dependencies: [
                .product(name: "PrometheusAnalyst", package: "Analyst"),
                .product(name: "JaegerAnalyst", package: "Analyst"),
                .product(name: "AnalystPresenter", package: "Analyst"),
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniDatabase", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniAsyncHTTPClient", package: "ApodiniAsyncHTTPClient"),
                .product(name: "JaegerCollector", package: "Collector"),
                .product(name: "PrometheusCollector", package: "Collector")
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
