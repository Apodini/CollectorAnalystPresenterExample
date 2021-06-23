// swift-tools-version:5.4

import PackageDescription


let package = Package(
    name: "Gateway",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "Run",
            targets: ["Run"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/Apodini/Analyst.git", from: "0.1.0"),
        .package(url: "https://github.com/Apodini/Collector.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "JaegerCollector", package: "Collector"),
                .product(name: "PrometheusCollector", package: "Collector"),
                .product(name: "JaegerAnalyst", package: "Analyst"),
                .product(name: "PrometheusAnalyst", package: "Analyst"),
                .product(name: "AnalystPresenter", package: "Analyst"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .executableTarget(
            name: "Run",
            dependencies: ["App"]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"]
        )
    ]
)
