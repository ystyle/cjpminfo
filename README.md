# cjpminfo

用于在编译时从 `cjpm.toml` 读取项目元数据的 Cangjie 宏包。

## 功能

cjpminfo 提供了一组编译时宏，可以自动从项目的 `cjpm.toml` 文件中读取版本号、项目名称等信息，无需手动维护硬编码的版本号。

## 支持的宏

### 项目元数据宏

- `@ModuleVer(默认值)` - 读取 package.version
- `@ModuleCjv(默认值)` - 读取 package.cjc-version
- `@ModuleName(默认值)` - 读取 package.name
- `@ModuleDesc(默认值)` - 读取 package.description
- `@ModuleOrg(默认值)` - 读取 package.organization（如果存在）

### 编译器版本宏

- `@CjcVersion(默认值)` - 执行 `cjc -v` 命令获取编译器版本号
- `@CjpmVersion(默认值)` - 执行 `cjpm -v` 命令获取包管理器版本号

### Git 信息宏

- `@GitTag(默认值)` - 获取最新的 git tag
- `@GitCommitId(默认值)` - 获取完整的 git commit id（40位）
- `@GitCommitIdShort(默认值)` - 获取短的 git commit id（7位）
- `@GitBranch(默认值)` - 获取当前 git 分支名

## 安装

在 `cjpm.toml` 中添加：

```toml
[dependencies]
cjpminfo = "1.2.1"
```

或使用本地 path 依赖：

```toml
[dependencies]
cjpminfo = { path = "../cjpminfo/", output-type = "static"}
```

## 使用方法

### 1. 在 cjpm.toml 中添加依赖

按照上面的安装方式添加依赖。

### 2. 在代码中使用宏

```cangjie
package demo

import cjpminfo.*

// 项目元数据
let version: String = @ModuleVer("1.1.0")
let cjcVersion: String = @ModuleCjv("1.0.0")
let name: String = @ModuleName("demo")
let description: String = @ModuleDesc("description")
let organization: String = @ModuleOrg("org")

// 编译器版本
let cjcVer: String = @CjcVersion("unknown")
let cjpmVer: String = @CjpmVersion("unknown")

// Git 信息
let gitTag: String = @GitTag("v0.0.0")
let gitCommitId: String = @GitCommitId("unknown")
let gitCommitIdShort: String = @GitCommitIdShort("unknown")
let gitBranch: String = @GitBranch("unknown")

main(): Int64 {
    println("version: ${version}")
    println("cjc_version: ${cjcVersion}")
    println("name: ${name}")
    println("description: ${description}")
    println("organization: ${organization}")
    println("cjc_version: ${cjcVer}")
    println("cjpm_version: ${cjpmVer}")
    println("git_tag: ${gitTag}")
    println("git_commit_id: ${gitCommitId}")
    println("git_commit_id_short: ${gitCommitIdShort}")
    println("git_branch: ${gitBranch}")
    return 0
}
```

### 3. 编译项目

```bash
# 需要设置 stdx 环境变量（如果使用 stdx）
export CANGJIE_STDX_PATH=/path/to/stdx/1.0.0/linux_x86_64_llvm/static/stdx

# 编译
cjpm build
```

## 工作原理

cjpminfo 的宏在编译时执行：

1. 从编译器命令行取 `-p`（当前正在编译的包的源码目录），从该目录向上找到最近的 `cjpm.toml`
2. 解析 `[package]` 部分的字段
3. 将对应的值注入到代码中

`-p` 指向的是**当前正在编译的包**，而不是调用方的工作目录 —— 因此**作为依赖被编译时读到的是依赖自己的清单**，
拿到的是依赖自己的版本号。取不到 `-p`（例如直接 `cjc` 编译单个源码文件）时退回调用方工作目录。

`@GitTag` / `@GitCommitId` / `@GitCommitIdShort` / `@GitBranch` 同样在**当前包所在项目**里执行
（`git -C <项目目录>`），而不是调用方的工作目录。

如果读不到清单、字段缺失或字段为空，则使用宏参数中提供的默认值（并在 stderr 留一行提示），
编译不会因为取不到元数据而失败。

## 版本管理最佳实践

使用 cjpminfo 后，只需要在 `cjpm.toml` 中维护版本号：

```toml
[package]
  name = "myproject"
  version = "1.2.3"
  cjc-version = "1.0.0"
  description = "My awesome project"
```

代码中使用 `@ModuleVer` 宏即可自动获取版本号，无需在多处同步修改。

## 注意事项

1. **编译时依赖**：cjpminfo 是编译时宏，只能在编译阶段使用
2. **环境变量**：需要正确设置 `CANGJIE_STDX_PATH`（如果项目使用 stdx）
3. **路径配置**：确保 cjpm.toml 中的 path 路径正确指向 cjpminfo 目录
4. **作为依赖被编译**：宏读到的是**依赖自己**的 `cjpm.toml`，因此库用 `@ModuleVer("1.0.0")`
   声明的版本号，在被别人依赖构建时也是这个库自己的版本（不会是消费方的）
5. **`@GitTag` 等 git 宏**：从中心仓拉取的依赖源码目录不是 git 仓库，此时会退回宏入参默认值

## 许可证

MulanPSL2
