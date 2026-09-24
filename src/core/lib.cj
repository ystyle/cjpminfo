// 清单解析与"当前包所在项目目录"的定位逻辑。
//
// 独立成普通包（而非直接写在宏包里）是为了可单元测试：
// 宏包（`macro package`）里的 `@Test` 不会被登记，`cjpm test` 收集不到用例。
package cjpminfo.core

import std.collection.ArrayList
import std.env.{getCommandLine, getVariable}
import std.fs.{File, OpenMode, Path, exists}
import std.io.readToEnd

public class Module {
    public Module(
        public let cjc_version: String,
        public let organization: String,
        public let name: String,
        public let description: String,
        public let version: String,
        public let output_type: String
    ) {
    }
}

// 解析 cjpm.toml 的 [package] 段中的字段。
// 只在 [package] 段内查找，且键之后必须紧跟 '=' 或空白，避免 "name" 误命中 "name-x"。
public func parseTomlValue(content: String, key: String): String {
    var inPackage = false
    for (line in content.split("\n")) {
        let trimmed = line.trimAscii()
        if (trimmed.startsWith("[package]")) {
            inPackage = true
            continue
        }
        if (trimmed.startsWith("[")) {
            inPackage = false
            continue
        }
        if (!inPackage) {
            continue
        }
        if (!trimmed.startsWith(key)) {
            continue
        }
        let rest = trimmed[key.size..trimmed.size]
        if (!(rest.startsWith("=") || rest.startsWith(" ") || rest.startsWith("\t"))) {
            continue
        }
        if (let Some(eq) <- trimmed.indexOf("=")) {
            let value = trimmed[eq + 1..trimmed.size].trimAscii()
            // 只取首个引号串，顺带挡掉行尾注释
            if (value.startsWith("\"")) {
                let body = value[1..value.size]
                if (let Some(end) <- body.indexOf("\"")) {
                    return body[0..end]
                }
                return value
            }
            return value
        }
    }
    return ""
}

// 从编译器命令行里取"正在编译的包"的源码目录。
//
// 宏在 cjc 进程内展开，`cjc` 的 `-p` 指向当前正在编译的包；调用方 shell 的 `PWD`
// 是消费方项目的工作目录 —— 编译依赖时两者并不相同，用 PWD 会读到消费方的清单。
public func startDirFromArgs(args: Array<String>): ?String {
    var i = 0
    while (i < args.size) {
        let a = args[i]
        if (a == "-p" || a == "--package") {
            if (i + 1 < args.size) {
                return args[i + 1]
            }
        } else if (a.startsWith("-p=") || a.startsWith("--package=")) {
            if (let Some(eq) <- a.indexOf("=")) {
                return a[eq + 1..a.size]
            }
        }
        i++
    }
    // 没有 -p：cjc 直接以源码文件为输入（如编译 build.cj），取该文件所在目录
    for (a in args) {
        if (a.endsWith(".cj")) {
            return Path(a).parent.toString()
        }
    }
    return None
}

// 从包的源码目录向上找最近的 cjpm.toml。
// 子包编译时 -p 指向 <proj>/src/sub，只取父目录会落在 <proj>/src（没有清单），故必须向上找。
public func findProjectDir(start: String): ?String {
    var cur = Path(start)
    var depth = 0
    while (depth < 16) {
        if (exists(cur.join("cjpm.toml"))) {
            return cur.toString()
        }
        let up = cur.parent
        if (up.toString() == cur.toString()) {
            break
        }
        cur = up
        depth++
    }
    return None
}

// 当前包所在的项目目录：优先用编译器给的信息，取不到再退回调用方工作目录
public func resolveProjectDir(): ?String {
    if (let Some(start) <- startDirFromArgs(getCommandLine())) {
        if (let Some(proj) <- findProjectDir(start)) {
            return proj
        }
    }
    let pwd = match (getVariable("PWD")) {
        case Some(v) => v
        case None => "."
    }
    return findProjectDir(pwd)
}

public func parseModule(content: String): Module {
    return Module(
        parseTomlValue(content, "cjc-version"),
        parseTomlValue(content, "organization"),
        parseTomlValue(content, "name"),
        parseTomlValue(content, "description"),
        parseTomlValue(content, "version"),
        parseTomlValue(content, "output-type")
    )
}

// 读不到清单（不存在/无权限）返回 None，由宏退回入参字面量：编译不该因为取不到元数据而失败
public func loadModule(projectDir: String): ?Module {
    try {
        let fs = File(Path(projectDir).join("cjpm.toml"), OpenMode.Read)
        return parseModule(String.fromUtf8(readToEnd(fs)))
    } catch (e: Exception) {
        return None
    }
}

// git 子命令也要在"当前包所在项目"里执行：默认工作目录是消费方项目，取到的会是消费方的仓库信息
public func prependProjectDir(args: Array<String>, proj: ?String): Array<String> {
    let out = ArrayList<String>()
    match (proj) {
        case Some(p) =>
            out.add("-C")
            out.add(p)
        case None => ()
    }
    for (a in args) {
        out.add(a)
    }
    return out.toArray()
}

public func gitArgsInProjectDir(args: Array<String>): Array<String> {
    return prependProjectDir(args, resolveProjectDir())
}
