# XCFrameworkBuild

![image-20191213200218097](http://ipicimage-1251019290.coscd.myqcloud.com/2019-12-13-120221.png)

一个快速帮你构建出`XCFramework`的脚本程序。

## 安装

### 安装Mint

```shell
brew install mint
```

### 安装XCFrameworkBuild

```shell
mint install josercc/XCFrameworkBuild xcbuild
```

## Example

```shell
xcbuild /Users/zhangxing/Downloads/MyFramework/MyFramework.xcodeproj /Users/zhangxing/Downloads/Output
```

## 帮助信息

```
xcbuild --help
```

```shell
Usage:

    $ xcbuild <project> <exportPath>

Arguments:

    project - Project文件的路径
    exportPath - 编译完毕打包出来的目录

Options:
    --scheme [default: ] - 对应的scheme 默认为空 则自动获取 如果存在多个则需要选择
    --configurations [default: ] - 编译的配置 如果不设置则存在 Release就设置为Release 否则就需要选择
    --destination [default: ["iOS"]] - 编译类型 默认为iOS 支持类型[iOS macOS tvOS watchOS]
```

