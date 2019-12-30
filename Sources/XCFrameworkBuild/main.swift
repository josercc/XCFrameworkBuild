import Commander
import Swiftline
import SwiftShell

enum XCError : Error {
    case error(String)
    var localizedDescription: String {
        switch self {
        case .error(let message):
            return message
        }
    }
}

let commandGroup = Group {
    $0.command(
        "create",
        Option<String>("project", default: "", description: "Project文件路径，默认为当前路径查找"),
        Options<String>("plaform", default: ["iOS"], count: 4, description:"编译类型 默认为iOS 支持类型[iOS macOS tvOS watchOS]"),
        description: "Generate an XCFrameworks from source code"
    ) { project, plaforms in
        do {
            let xcbuild = try XCBuild()
            try xcbuild.build(platforms: plaforms)
        } catch let error {
            print(error.localizedDescription.f.Red)
        }
    }
    $0.command(
    "transfer",
    description: "Convert previous .a or .framework to XCFrameworks"
    ) {
        do {
            let xcbuild = try XCBuild()
            try xcbuild.transfer()
        } catch let error {
            print(error.localizedDescription.f.Red)
        }
    }
}
commandGroup.run()
