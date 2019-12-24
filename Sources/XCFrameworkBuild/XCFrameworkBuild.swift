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
    let exportPath:String
    let scheme:String
    let configurations:String
    let destination:[String]
    var productName:String = ""
    var frameworkPaths:[String] = []
    
    mutating func build() throws {
        var scheme = self.scheme
        var configurations = self.configurations
        print("→ 正在获取工程配置信息")
        // xcodebuild -project project -list
        let output = run("xcodebuild", "-project", project, "-list").stdout
        let outputList = output.components(separatedBy: "\n\n")
        for item in outputList {
            let _item = item.replacingOccurrences(of: " ", with: "")
            let itemList = _item.components(separatedBy: "\n")
            if item.contains("Build Configurations") && configurations.count == 0 {
                print("→ 正在查询当前配置")
                if itemList.contains("Release") {
                    configurations = "Release"
                } else {
                    configurations = readLine(description: "读取不到默认配置Release请手动选择", content: itemList)
                }
                print("→ 读取配置[\(configurations)]")
            } else if item.contains("Schemes") && scheme.count == 0 {
                if itemList.count == 2 {
                    scheme = itemList[1]
                } else {
                    scheme = readLine(description: "请选择对应的Scheme", content: itemList, ignoreIndex: 0)
                }
                print("→ 读取scheme[\(scheme)]")
            }
        }
        for destination in self.destination {
            try xcodeBuild(scheme: scheme, destination: destination, configurations: configurations)
        }
        var createXCFrameworks:[String] = ["-create-xcframework"]
        for item in self.frameworkPaths {
            createXCFrameworks.append("-framework")
            createXCFrameworks.append(item)
        }
        createXCFrameworks.append("-output")
        createXCFrameworks.append("\(self.exportPath)/\(self.currenntSetProductName()).xcframework")
        // xcodebuild -create-xcframework -framework /tmp/xcf/ios.xcarchive/Products/Library/Frameworks/TestFramework.framework -framework /tmp/xcf/iossimulator.xcarchive/Products/Library/Frameworks/TestFramework.framework -output /tmp/xcf/TestFramework.xcframework
        try runAndPrint("xcodebuild", createXCFrameworks)
    }
    
    mutating func xcodeBuild(scheme:String, destination:String, configurations:String) throws {
        let sdkMap:[String:String] = [
            "iOS" : "iphoneos",
            "iOS Simulator" : "iphonesimulator",
            "macOS" : "macosx",
            "tvOS" : "appletvos",
            "tvOS Simulator" : "appletvsimulator",
            "watchOS" : "watchos",
            "watchOS Simulator" : "watchsimulator",
        ]
        let sdk = sdkMap[destination] ?? "iphoneos"
        let archivePath = "\(self.exportPath)/\(sdk).xcarchive"
        //         // xcodebuild archive -scheme TestFramework -destination="iOS" -archivePath /tmp/xcf/ios.xcarchive -derivedDataPath /tmp/iphoneos -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
        try runAndPrint("xcodebuild", "-project", project, "archive", "-scheme", scheme, "-configuration", configurations, "-destination=\"\(destination)\"", "-archivePath", archivePath, "-sdk", sdk, "SKIP_INSTALL=NO", "BUILD_LIBRARIES_FOR_DISTRIBUTION=YES", "-verbose")
        let frameworkPath = "\(archivePath)/Products/Library/Frameworks/\(self.currenntSetProductName()).framework"
        self.frameworkPaths.append(frameworkPath)
        if !destination.contains("macOS") && !destination.contains("Simulator") {
            try xcodeBuild(scheme: scheme, destination: "\(destination) Simulator", configurations: configurations)
        }
    }
    
    func readLine(description:String, content:[String], ignoreIndex:Int = 0) -> String {
        var output = description
        var content = content
        content.remove(at: ignoreIndex)
        for elenment in content.enumerated() {
            output += "\n\(elenment.offset) \(elenment.element)"
        }
        print(output)
        guard let index =  Int(Swift.readLine() ?? "") else {
            print("🔴 输入序列号错误 重新输入")
            return readLine(description: description, content: content, ignoreIndex: ignoreIndex)
        }
        guard index < content.count else {
            print("🔴 输入序列号错误 重新输入")
            return readLine(description: description, content: content, ignoreIndex: ignoreIndex)
        }
        return content[index]
    }
    
    func currenntSetProductName() -> String {
        if self.productName.count > 0 {
            return self.productName
        } else {
            return self.scheme
        }
    }
}

