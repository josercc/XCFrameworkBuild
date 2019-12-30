# XCFrameworkBuild

![image-20191213200218097](http://ipicimage-1251019290.coscd.myqcloud.com/2019-12-13-120221.png)

A script program that helps you build `XCFramework` quickly, and supports conversion of` .framework` and `.a` before` .xcframework`.

## Install

### Install Mint（If not already installed）

```shell
brew install mint
```

### Install XCFrameworkBuild

```shell
mint install josercc/XCFrameworkBuild@master xcbuild -f
```

## Example

### If you want to build XCFramework from source

```shell
xcbuild create [--platform=[iOS]]
```

### If you want to talk about .framework or .a to .xcframework

```
xcbuild transfer
```

## More commands

```
xcbuild --help
```

