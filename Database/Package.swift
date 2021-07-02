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
        .package(url: "https://github.com/Apodini/Apodini.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/Apodini/ApodiniCollector.git", .branch("develop")),
        .package(url: "https://github.com/Apodini/ApodiniAnalystPresenter.git", .branch("develop"))
    ],
    targets: [
        .executableTarget(
            name: "DatabaseWebService",
            dependencies: [
                .product(name: "Apodini", package: "Apodini"),
                .product(name: "ApodiniDatabase", package: "Apodini"),
                .product(name: "ApodiniREST", package: "Apodini"),
                .product(name: "ApodiniCollector", package: "ApodiniCollector"),
                .product(name: "ApodiniAnalystPresenter", package: "ApodiniAnalystPresenter")
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
