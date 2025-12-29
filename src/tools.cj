macro package cjpminfo

import std.ast.*
import std.fs.{File, OpenMode, Path}
import std.env.getVariable
import std.io.readToEnd

class Module {
    Module(
        let cjc_version:String,
        let organization:String,
        let name:String,
        let description:String,
        let version:String,
        let output_type:String
    ) {

    }
}

var d:?Module= None
var loaded = false

// 简单解析 TOML 文件的 [package] 部分
func parseTomlValue(content: String, key: String): String {
    let lines = content.split("\n")
    var inPackage = false
    for (line in lines) {
        let trimmed = line.trimAscii()
        if (trimmed.startsWith("[package]")) {
            inPackage = true
        } else if (trimmed.startsWith("[")) {
            inPackage = false
        } else if (inPackage && trimmed.startsWith("${key}")) {
            // 解析 key = "value" 格式
            let parts = trimmed.split("=")
            if (parts.size >= 2) {
                var value = parts[1].trimAscii()
                // 去掉引号
                if (value.size >= 2 && value.startsWith("\"") && value.endsWith("\"")) {
                    return value[1..value.size - 1]
                }
            }
        }
    }
    return ""
}

func getModule():?Module {
    if (loaded) {
        return d
    }

    // 从环境变量获取项目目录
    let pwd = match (getVariable("PWD")) {
        case Some(v) => v
        case _ => "."
    }
    let fs = File(Path(pwd).join("cjpm.toml"), OpenMode.Read)
    let bs = readToEnd(fs)
    let content = String.fromUtf8(bs)

    let cjc_version = parseTomlValue(content, "cjc-version")
    let organization = ""  // TOML 中没有这个字段
    let name = parseTomlValue(content, "name")
    let description = parseTomlValue(content, "description")
    let version = parseTomlValue(content, "version")
    let output_type = parseTomlValue(content, "output-type")

    d = Module(cjc_version, organization, name, description, version, output_type)
    loaded = true
    return d
}

public macro ModuleVer(inputs:Tokens):Tokens {
    let m = getModule()
    let vsersion = m?.version ?? inputs[0].value
    return Tokens() + Token(STRING_LITERAL, vsersion)
}

public macro ModuleOrg(inputs:Tokens):Tokens {
    let m = getModule()
    let vsersion = m?.organization ?? inputs[0].value
    return Tokens() + Token(STRING_LITERAL, vsersion)
}

public macro ModuleCjv(inputs:Tokens):Tokens {
    let m = getModule()
    let vsersion = m?.cjc_version ?? inputs[0].value
    return Tokens() + Token(STRING_LITERAL, vsersion)
}

public macro ModuleName(inputs:Tokens):Tokens {
    let m = getModule()
    let vsersion = m?.name ?? inputs[0].value
    return Tokens() + Token(STRING_LITERAL, vsersion)
}

public macro ModuleDesc(inputs:Tokens):Tokens {
    let m = getModule()
    let vsersion = m?.description ?? inputs[0].value
    return Tokens() + Token(STRING_LITERAL, vsersion)
}
