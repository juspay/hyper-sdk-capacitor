// swift-tools-version: 5.9
/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription

let package = Package(
    name: "HyperSdkCapacitor",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "HyperSdkCapacitor",
            targets: ["HyperSdkCapacitor"]
        )
    ],
    dependencies: [

        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", exact: "6.2.1"),
        .package(url: "https://github.com/juspay/hypersdk-ios.git", exact: "2.2.5")
    ],
    targets: [
        .target(
            name: "HyperSdkCapacitor",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "HyperSDK", package: "hypersdk-ios")
            ],
            path: "ios/Plugin",
            exclude: ["HyperServicesPlugin.m"],
            sources: ["HyperServicesPlugin.swift"]
        )
    ]
)
