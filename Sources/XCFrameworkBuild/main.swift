import Commander
import Swiftline
import SwiftShell

//command(
//    Argument<String>("project", description: "Project文件的路径"),
//    Argument<String>("exportPath", description: "编译完毕打包出来的目录"),
//    Option<String>("scheme", default: "", description: "对应的scheme 默认为空 则自动获取 如果存在多个则需要选择"),
//    Option("configurations", default: "", description: "编译的配置 如果不设置则存在 Release就设置为Release 否则就需要选择"),
//    Options<String>("destination", default: ["iOS"], count: 4, description: "编译类型 默认为iOS 支持类型[iOS macOS tvOS watchOS]"),
//    Option("productName", default: "", description: "Framework 产品的名称默认[scheme]")
//) { project, exportPath, scheme, configurations, destination, productName in
//    var build = XCFrameworkBuild(project:project, exportPath:exportPath, scheme:scheme, configurations:configurations, destination:destination)
//    build.productName = productName
//    do {
//        try build.build()
//    } catch let error {
//        print(error.localizedDescription)
//    }
//
//}.run()

//print(main.env)

let commandGroup = Group {
    $0.command(
        "create",
        Option<String>("project", default: "", description: "Project文件路径，默认为当前路径查找"),
        Options<String>("plaform", default: ["iOS"], count: 4, description:"编译类型 默认为iOS 支持类型[iOS macOS tvOS watchOS]"),
        description: "Generate an XCFrameworks from source code"
    ) { project, plaform in
        do {
            try create(project, "Release",plaform)
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
//    $0.command("merge", description: "Merge a new framework or library into an .xcframework file") {
//
//    }
}
commandGroup.run()
