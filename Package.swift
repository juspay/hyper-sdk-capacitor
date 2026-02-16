// swift-tools-version: 5.9
/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription
import Foundation


var hyperSdkVersion = "2.2.2"

func getHyperSdkVersion() -> String {
    let fileManager = FileManager.default
    let packageDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
    
    var searchPaths: [String] = []
    
    // Search sibling directories (for monorepo/local dev)
    if let contents = try? fileManager.contentsOfDirectory(atPath: packageDir.path) {
        for item in contents {
            let itemPath = packageDir.appendingPathComponent(item)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: itemPath.path, isDirectory: &isDir) && isDir.boolValue {
                let packageJsonPath = itemPath.appendingPathComponent("package.json").path
                searchPaths.append(packageJsonPath)
                if let version = readHyperSdkVersion(from: packageJsonPath) {
                    return version
                }
            }
        }
    }
    
    // Search parent directories (for node_modules install)
    var currentPath = packageDir
    for _ in 1...6 {
        currentPath = currentPath.deletingLastPathComponent()
        let packageJsonPath = currentPath.appendingPathComponent("package.json").path
        searchPaths.append(packageJsonPath)
        
        if let version = readHyperSdkVersion(from: packageJsonPath) {
            return version
        }
    }
    
    return hyperSdkVersion
}

func readHyperSdkVersion(from path: String) -> String? {
    guard FileManager.default.fileExists(atPath: path),
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let version = json["hyperSdkIOSVersion"] as? String else {
        return nil
    }
    return version
}

let resolvedHyperSdkVersion = getHyperSdkVersion()

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
        .package(url: "https://github.com/juspay/hypersdk-ios.git", exact: Version(stringLiteral: resolvedHyperSdkVersion))
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
            sources: ["HyperServicesPlugin.swift", "HyperServicesPluginExtension.swift"]
        )
    ]
)
