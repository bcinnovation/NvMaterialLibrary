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
            type: .dynamic,
            targets: ["NvMaterialLibrary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMinor(from: "2.1.0")),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.3.0"),
        //.package(name: "NvMeicam", path: "../NvMeicam"), // 如果有的话
    ],
    targets: [
        .target(
            name: "NvMaterialLibrary",
            dependencies: [
                //"NvMeicam",
                .product(name: "Zip", package: "Zip"),
                .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder"),
                "NveEffectKit",
                "NvEffectSdkCore"
            ],
            path: "NvMaterialLibrary/NvMaterialLibrary",
            sources: ["SourceFiles"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/NvMaterialUIX.bundle")
            ]
        ),
        .binaryTarget(
            name: "NveEffectKit",
            path: "../Frameworks/NveEffectKit.xcframework"
        ),
        .binaryTarget(
            name: "NvEffectSdkCore",
            path: "../Frameworks/NvEffectSdkCore.xcframework"
        )
    ]
)
