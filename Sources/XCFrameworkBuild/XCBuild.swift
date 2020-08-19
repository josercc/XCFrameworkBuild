//
//  XCBuild.swift
//  
//
//  Created by 张行 on 2019/12/30.
//

import Foundation
import SwiftShell
import Swiftline

class XCBuild {
    init() throws {
        let buildDir = try self.buildDir()
        if FileManager.default.fileExists(atPath: buildDir) {
            try FileManager.default.removeItem(atPath: buildDir)
        }
        try FileManager.default.createDirectory(atPath: buildDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    
    func xcCommand(_ cammands:[String], _ libbraryName:String) throws {
        let buildDir = try self.buildDir()
        let xcframeworkPath = "\(buildDir)/\(libbraryName).xcframework"
        try runAndPrint("xcodebuild", "-create-xcframework", cammands, "-output", xcframeworkPath)
        try runAndPrint("open", buildDir)
    }
    
    /// 分离框架重新组成新的框架
    /// - Parameter archs: 模拟器或者真机框架组
    /// - Parameter execName: 可执行文件名称
    /// - Parameter libPath: 框架所在的路径
    func spliteArchLib(_ archs:[String], _ execName:String, _ libPath:String, _ buildDir:String) throws -> String {
        // 分割出来的子框架的可执行文件
        var subArchExecs:[String] = []
        /// 子框架合集名称路径
        let archName = archs.joined(separator: "-")
        /// 合成可执行文件所在的文件夹
        let archDir = "\(buildDir)/\(archName)"
        /// 创建对应的文件夹
        try FileManager.default.createDirectory(atPath: archDir, withIntermediateDirectories: true, attributes: nil)
        /// 分离子框架
        for arch in archs {
            /// 子框架对应文件夹
            let subArchDir = "\(archDir)/\(arch)"
            try FileManager.default.createDirectory(atPath: subArchDir, withIntermediateDirectories: true, attributes: nil)
            let output = "\(subArchDir)/\(execName)"
            //  lipo 静态库源文件路径 -thin CPU架构名称 -output 拆分后文件存放路径
            try runAndPrint("lipo", "\(libPath)/\(execName)", "-thin", arch, "-output", output)
            subArchExecs.append(output)
        }
        /// 合并平台框架
        let newArchExt = "\(archDir)/\(execName)"
        try runAndPrint("lipo", "-create", subArchExecs, "-output", newArchExt)
        return newArchExt
    }
    
    /// 获取框架的名称
    /// - Parameter libraryPath: 框架的路径
    /// - Parameter libraryType: 框架的类型 比如.framework .a
    func libraryName(_ libraryPath:String, _ libraryType:String) -> String? {
        return libraryPath.components(separatedBy: "/").last?.replacingOccurrences(of: libraryType, with: "")
    }
    
    /// 查询可执行文件支持的平台
    /// - Parameter execPath: 可执行文件路径
    func parseLibraryArchs(_ execPath:String) -> ([[String]]) {
        let resultText = SwiftShell.run("lipo", "-info", execPath).stdout
        let archs = resultText.components(separatedBy: "are: ")[1].components(separatedBy: " ")
        var simulatorArchs:[String] = []
        var deviceArchs:[String] = []
        for arch in archs {
            if ["i386", "x86_64"].contains(arch) {
                simulatorArchs.append(arch)
            } else {
                deviceArchs.append(arch)
            }
        }
        return [simulatorArchs,deviceArchs]
    }
    
    /// 编译所在的文件夹
    func buildDir() throws -> String {
        let user = try userName()
        return "/Users/\(user)/Library/Caches/xcbuild"
    }
    
    /// 获取当前用户名
    func userName() throws -> String {
        guard let user = main.env["USER"] else {
            throw XCError.error("Can't get username!")
        }
        return user
    }
    
    func rootPath(_ path:String) -> String {
        var paths = path.components(separatedBy: "/")
        paths.removeLast()
        return paths.joined(separator: "/")
    }
}


extension XCBuild {
    func transfer() throws {
        let chooseType = choose("Please select the type of conversion", choices: "framework", "library")
        if chooseType == "framework" {
            try transferFramework()
        } else if chooseType == "library" {
            try transferLibrary()
        } else {
            throw XCError.error("\(chooseType) type is not currently supported")
        }
    }
    
    func transferFramework() throws {
        let frameworkDir = ask("Please enter the path where the .framework is located")
        guard let frameworkName = libraryName(frameworkDir, ".framework") else {
            throw XCError.error("Cannot find framework name")
        }
        /// 二进制的路径
        let frameworkExec = "\(frameworkDir)/\(frameworkName)"
        let archPlaforms = parseLibraryArchs(frameworkExec)
        var commands:[String] = []
        let buildDir = try self.buildDir()
        for archs in archPlaforms {
            let arcName = archs.joined(separator: "-")
            let command = try spliteArchLib(archs, frameworkName, frameworkDir, buildDir)
            let toFrameworkPath = "\(buildDir)/\(arcName)/\(frameworkName).framework"
            try FileManager.default.copyItem(atPath: frameworkDir, toPath: toFrameworkPath)
            let frameworkPath = "\(toFrameworkPath)/\(frameworkName)"
            let realPath:String
            if let symbolicLink = try? FileManager.default.destinationOfSymbolicLink(atPath: "\(toFrameworkPath)/\(frameworkName)") {
                realPath = symbolicLink
            } else {
                realPath = frameworkPath
            }
            let fromURL = URL(fileURLWithPath: "\(realPath)")
            let toURL = URL(fileURLWithPath: command)
            let _ = try FileManager.default.replaceItemAt(fromURL, withItemAt: toURL)
            commands.append(contentsOf: ["-framework", toFrameworkPath])
        }
        try xcCommand(commands, frameworkName)
    }
    
    func transferLibrary() throws {
        let libPath = ask("Please enter .a file path")
        let headerDir = ask("Please enter the folder where the header files are located")
        guard let libName = libraryName(libPath, ".a")?.replacingOccurrences(of: "lib", with: "") else {
            throw XCError.error("Cannot find library name")
        }
        /// 二进制的路径
        let libExec = libPath
        let archPlaforms = parseLibraryArchs(libExec)
        var commands:[String] = []
        let buildDir = try self.buildDir()
        let cacheHeaderDir = "\(buildDir)/headers"
        try FileManager.default.copyItem(atPath: headerDir, toPath: cacheHeaderDir)
        try deleteOtherFile(cacheHeaderDir)
        for archs in archPlaforms {
            let command = try spliteArchLib(archs, "lib\(libName).a", rootPath(libPath), buildDir)
            commands.append(contentsOf: ["-library", command, "-headers", cacheHeaderDir])
        }
        try xcCommand(commands, libName)
    }
    
    func deleteOtherFile(_ dir:String) throws {
        let contents = try FileManager.default.contentsOfDirectory(atPath: dir)
        for file in contents {
            let path = "\(dir)/\(file)"
            var isDir = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else {
                continue
            }
            if isDir.boolValue {
                try deleteOtherFile(path)
            } else {
                guard !file.contains(".h") else {
                    continue
                }
                try FileManager.default.removeItem(atPath: path)
            }
        }
    }
}

extension XCBuild {
    func build(platforms:[String]) throws {
        let xcodeprojPath = ask("Please enter the .xcodeproj file path")
        let buildList = BuildList(xcodeprojPath)
        let scheme:String
        guard buildList.schemes.count > 0 else {
            throw XCError.error("No Scheme exists")
        }
        if buildList.schemes.count == 1 {
            scheme = buildList.schemes[0]
        } else {
            scheme = choose("Please select the corresponding Scheme", type: String.self, costumizationBlock: { (setting) in
                for scheme in buildList.schemes {
                    setting.addChoice(scheme) { () -> String in
                        return scheme
                    }
                }
            })
        }
        var buildSettings = BuildSetting(project: xcodeprojPath, scheme: scheme)
        buildSettings.parse()
        
        let productName = buildSettings.settings["PRODUCT_NAME"] ?? scheme
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
        var xcCommands:[String] = []
        for platform in platforms {
            guard let items = destinations[platform] else {
                continue
            }
            for item in items {
                let commands = try xcodeBuild(xcodeprojPath: xcodeprojPath, scheme: scheme, sdk: item.1, configurations: "Release", productName: productName)
                xcCommands.append(contentsOf: commands)
            }
        }
        try xcCommand(xcCommands, productName)
    }
    
    func xcodeBuild(xcodeprojPath:String, scheme:String, sdk:String, configurations:String, productName:String) throws -> [String] {
        let buildDir = try self.buildDir()
        let buildLibraryDir = "\(buildDir)/\(configurations)-\(sdk)"
        try runAndPrint("xcodebuild", "-project", xcodeprojPath, "-scheme", scheme, "-configuration", configurations, "-sdk", sdk, "SKIP_INSTALL=NO", "BUILD_LIBRARIES_FOR_DISTRIBUTION=YES", "CONFIGURATION_BUILD_DIR=\(buildLibraryDir)", "-verbose")
        var isFramework = false
        for item in try FileManager.default.contentsOfDirectory(atPath: buildLibraryDir) {
            if item.contains(".framework") {
                isFramework = true
            }
        }
        if isFramework {
            return ["-framework", "\(buildLibraryDir)/\(productName).framework"]
        } else {
            return ["-library", "\(buildLibraryDir)/lib\(productName).a", "-headers", "\(buildLibraryDir)/include/\(productName)"]
        }
    }
}
