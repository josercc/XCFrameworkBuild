//
//  BuildSettings.swift
//  
//
//  Created by 张行 on 2019/12/28.
//

import Foundation
import SwiftShell

struct BuildSetting {
    let project:String
    let scheme:String
    var settings:[String:String] = [:]
    mutating func parse() {
        let resultText = run("xcodebuild", "-project", project, "-scheme", scheme, "-showBuildSettings").stdout
        let contents = resultText.components(separatedBy: "\n    ")
        for content in contents.enumerated() {
            guard content.offset > 0 else {
                continue
            }
//            print(content.element)
            let configurations = content.element.components(separatedBy: " = ")
            self.settings[configurations[0]] = configurations[1]
        }
    }
}

func chooseTarget(_ project:String) throws -> String {
    let resultText = run("xcodebuild", "-project", project, "-list")
    return resultText.stdout
}

struct BuildList {
    let project:String
    var targets:[String] = []
    var schemes:[String] = []
    var configurations:[String] = []
    init(_ project:String) {
        self.project = project
        let resultText = run("xcodebuild", "-project", project, "-list").stdout
        let contents = resultText.components(separatedBy: "\n\n    ")
        parse(contents[0], &self.targets)
        parse(contents[1], &self.configurations)
        parse(contents[3], &self.schemes)
    }
    func parse(_ text:String, _ list:inout [String]) {
        let contents = text.components(separatedBy: "\n        ")
        for content in contents.enumerated() {
            guard content.offset > 0 else {
                continue
            }
            var text = content.element
            text = text.replacingOccurrences(of: "\n", with: "")
            list.append(text)
        }
    }
}
