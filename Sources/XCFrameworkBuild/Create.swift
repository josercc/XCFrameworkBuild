//
//  Create.swift
//  XCFrameworkBuild
//
//  Created by 张行 on 2019/12/27.
//

import Foundation
import SwiftShell
import Swiftline

enum XCError : Error {
    case error(String)
    var localizedDescription: String {
        switch self {
        case .error(let message):
            return message
        }
    }
}

func create(_ project:String, _ configuration:String, _ plaform:[String]) throws {
    var _project = project
    if _project.count == 0 {
        _project = try chooseProjectPath()
    }
    let buildList = BuildList(_project)
    let scheme:String
    guard buildList.schemes.count > 0 else {
        throw XCError.error("不存在任何的 Scheme")
    }
    if buildList.schemes.count == 1 {
        scheme = buildList.schemes[0]
    } else {
        scheme = choose("请选择对应的 Scheme\n", type: String.self, costumizationBlock: { (setting) in
            for scheme in buildList.schemes {
                setting.addChoice(scheme) { () -> String in
                    return scheme
                }
            }
        })
    }
    var buildSettings = BuildSetting(project: _project, scheme: scheme)
    buildSettings.parse()
    
    let productName = buildSettings.settings["PRODUCT_NAME"] ?? scheme
    
    guard let productPath = buildSettings.settings["BUILD_DIR"] else {
        throw XCError.error("查找不到对应编译路径")
    }
    
    var build = XCFrameworkBuild(project: _project, scheme: scheme, supportPlaforms: plaform, productName: productName, productPath: productPath, configurations: configuration)
    try build.build()
}

func pwd() throws -> String {
    guard let pwd =  main.env["PWD"] else {
        throw XCError.error("获取当前路径失败")
        
    }
    return pwd
}

func exprotPath(_ projectPath:String) -> String {
    var paths = projectPath.components(separatedBy: "/")
    paths.removeLast()
    return "\(paths.joined(separator: "/"))/build"
}

func chooseProjectPath() throws -> String {
    let pwdPath = try pwd()
    let fileContents:[String] = try FileManager.default.contentsOfDirectory(atPath: pwdPath)
    var projectFileContents:[String] = []
    for file in fileContents.enumerated() {
        if file.element.contains(".xcodeproj") {
            projectFileContents.append(file.element)
        }
    }
    guard projectFileContents.count > 0 else {
        throw XCError.error("当前路径不存在 Project 文件")
    }
    guard projectFileContents.count > 1 else {
        return "\(pwdPath)/\(projectFileContents[0])"
    }
    let chooseValue = choose("请选择对应的 Project 文件", type: String.self) { (setting) in
        for file in projectFileContents {
            setting.addChoice(file) { () -> String in
                return file
            }
        }
    }
    return "\(pwdPath)/\(chooseValue)"
}

