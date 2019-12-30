//
//  XCFrameworkBuild.swift
//  
//
//  Created by 张行 on 2019/12/13.
//

import Foundation
import SwiftShell


struct XCFrameworkBuild {
    let project:String
    let scheme:String
    let supportPlaforms:[String]
    let productName:String
    let productPath:String
    let configurations:String
    var frameworkPaths:[String] = []
    
    mutating func build() throws {
        let destinations:[String:[(String,String)]] = [
            "iOS" : [
                ("iOS","iphoneos"),
                ("iOS Simulator","iphonesimulator")
            ],
            "macOS" : [
                ("macOS","macosx"),
            ],
            "tvOS" : [
                ("tvOS","appletvos"),
                ("tvOS Simulator","appletvsimulator")
            ],
            "watchOS" : [
                ("watchOS","watchos"),
                ("watchOS Simulator","watchsimulator")
            ]
        ]
        for plaform in self.supportPlaforms {
            guard let destination = destinations[plaform] else {
                continue
            }
            for d in destination {
                try xcodeBuild(scheme: scheme, destination: d, configurations: configurations)
            }
        }
        var createXCFrameworks:[String] = ["-create-xcframework"]
        createXCFrameworks.append(contentsOf: self.frameworkPaths)
        createXCFrameworks.append("-output")
        let xcframeworkPath = "\(self.productPath)/\(self.productName).xcframework"
        if FileManager.default.fileExists(atPath: xcframeworkPath) {
            try runAndPrint("rm", "-r", xcframeworkPath)
        }
        createXCFrameworks.append(xcframeworkPath)
        try runAndPrint("xcodebuild", createXCFrameworks)
        try runAndPrint("open", self.productPath)
    }
    
    mutating func xcodeBuild(scheme:String, destination:(String,String), configurations:String) throws {
        let libraryPath = "\(self.productPath)/\(destination.1).xcarchive"
        try runAndPrint("xcodebuild", "-project", project, "archive", "-scheme", scheme, "-configuration", configurations, "-destination=\"\(destination.0)\"", "-archivePath", libraryPath, "-sdk", destination.1, "SKIP_INSTALL=NO", "BUILD_LIBRARIES_FOR_DISTRIBUTION=YES", "-verbose")
        
        let frameworkPath = "\(libraryPath)/Products/Library/Frameworks/\(self.productName).framework"
        let libLibraryPath = "\(libraryPath)/Products/usr/local/lib/lib\(self.productName).a"
        let rootPath = self.productPath.replacingOccurrences(of: "Products", with: "Intermediates.noindex")
        let headerMap:[String:String] = [
            "iOS" : "iphonesimulator",
            "iOS Simulator" : "iphonesimulator",
            "macOS" : "macosx",
            "tvOS" : "appletvsimulator",
            "tvOS Simulator" : "appletvsimulator",
            "watchOS" : "watchsimulator",
            "watchOS Simulator" : "watchsimulator",
        ]
        guard let headerValue = headerMap[destination.0] else {
            return
        }
        let headerPath = "\(rootPath)/ArchiveIntermediates/MyLibrary/BuildProductsPath/\(self.configurations)-\(headerValue)/include"
        if FileManager.default.fileExists(atPath: frameworkPath) {
            self.frameworkPaths.append("-framework")
            self.frameworkPaths.append(frameworkPath)
        } else {
            self.frameworkPaths.append("-library")
            self.frameworkPaths.append(libLibraryPath)
            self.frameworkPaths.append("-headers")
            self.frameworkPaths.append(headerPath)
        }
    }
    
}

