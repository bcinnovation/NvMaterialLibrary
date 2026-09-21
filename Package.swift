// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NvMaterialLibrary",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "NvMaterialLibrary",
            type: .static,
            targets: ["NvMaterialLibrary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/bcinnovation/NvEffectFrameworks.git", from: "1.0.0"),
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMinor(from: "2.1.0")),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.17.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.3.0"),
        //.package(name: "NvMeicam", path: "../NvMeicam"), // 如果有的话
    ],
    targets: [
        .target(
            name: "NvMaterialLibrary",
            dependencies: [
                //"NvMeicam",
                .product(name: "Zip", package: "Zip"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder"),
                .product(name: "NveEffectKit", package: "NvEffectFrameworks"),
                .product(name: "NvEffectSdkCore", package: "NvEffectFrameworks"),
            ],
            path: "NvMaterialLibrary/NvMaterialLibrary",
            sources: ["SourceFiles"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/NvMaterialUIX.bundle")
            ]
        )
    ]
)
