// 宏层：只负责把 cjpminfo.core 解析出的清单字段展开成字面量。
// 解析与目录定位逻辑在 cjpminfo.core（那里可跑单元测试）。
macro package cjpminfo

import std.ast.*
import std.process.executeWithOutput
import cjpminfo.core.*

// 一个 cjc 进程只编译一个包（-p 是单个包目录），故按进程缓存即可
var d: ?Module = None
var loaded = false

func getModule(): ?Module {
    if (loaded) {
        return d
    }
    loaded = true
    match (resolveProjectDir()) {
        case Some(proj) =>
            d = loadModule(proj)
            match (d) {
                case Some(_) => ()
                case None =>
                    eprintln("[cjpminfo] cannot read cjpm.toml under '" + proj +
                        "', macro falls back to its literal argument")
            }
        case None =>
            eprintln("[cjpminfo] cannot locate cjpm.toml (no '-p' in compiler argv and none under PWD), " +
                "macro falls back to its literal argument")
    }
    return d
}

func fallbackValue(inputs: Tokens): String {
    if (inputs.size > 0) {
        return inputs[0].value
    }
    return ""
}

// 字段为空（清单读不到、或该字段本就没写）就退回入参字面量：
// 直接返回空串会让调用方的默认值形同虚设。
func pick(field: String, inputs: Tokens): String {
    if (field.isEmpty()) {
        return fallbackValue(inputs)
    }
    return field
}

// 读不到清单时视同"字段为空"
func fieldOf(select: (Module) -> String): String {
    match (getModule()) {
        case Some(m) => return select(m)
        case None => return ""
    }
}

public macro ModuleVer(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, pick(fieldOf({m => m.version}), inputs))
}

public macro ModuleOrg(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, pick(fieldOf({m => m.organization}), inputs))
}

public macro ModuleCjv(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, pick(fieldOf({m => m.cjc_version}), inputs))
}

public macro ModuleName(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, pick(fieldOf({m => m.name}), inputs))
}

public macro ModuleDesc(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, pick(fieldOf({m => m.description}), inputs))
}

func getCommandVersion(cmd: String): ?String {
    try {
        let (exitCode, stdout, _) = executeWithOutput(cmd, ["-v"])
        if (exitCode == 0) {
            let output = String.fromUtf8(stdout)
            let lines = output.split("\n")
            if (lines.size > 0) {
                let firstLine = lines[0]
                let colonIndex = firstLine.indexOf(":")
                if (let Some(idx) <- colonIndex) {
                    let version = firstLine[idx + 1..firstLine.size]
                    return version.trimAscii()
                }
                return firstLine.trimAscii()
            }
        }
    } catch (e: Exception) {
        // 命令不可执行（未安装/不在 PATH）：退回宏入参字面量，返回值语义不变；
        // 但必须留痕，否则编译产物里的版本号悄悄变成占位值而无人知晓
        eprintln("[cjpminfo] run '" + cmd + " -v' failed, macro falls back to its literal argument: " + e.toString())
    }
    return None
}

func executeGitCommand(args: Array<String>): ?String {
    try {
        let (exitCode, stdout, _) = executeWithOutput("git", args)
        if (exitCode == 0) {
            let output = String.fromUtf8(stdout)
            return output.trimAscii()
        }
    } catch (e: Exception) {
        // git 不可用：退回宏入参字面量，返回值语义不变；留痕以便区分"真没 tag"与"git 跑不起来"
        eprintln("[cjpminfo] execute git command failed, macro falls back to its literal argument: " + e.toString())
    }
    return None
}

func gitCommand(args: Array<String>, inputs: Tokens): String {
    let out = executeGitCommand(gitArgsInProjectDir(args)) ?? inputs[0].value
    return out
}

public macro CjcVersion(inputs: Tokens): Tokens {
    let version = getCommandVersion("cjc") ?? fallbackValue(inputs)
    return Tokens() + Token(STRING_LITERAL, version)
}

public macro CjpmVersion(inputs: Tokens): Tokens {
    let version = getCommandVersion("cjpm") ?? fallbackValue(inputs)
    return Tokens() + Token(STRING_LITERAL, version)
}

public macro GitTag(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, gitCommand(["describe", "--tags", "--abbrev=0"], inputs))
}

public macro GitCommitId(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, gitCommand(["rev-parse", "HEAD"], inputs))
}

public macro GitCommitIdShort(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, gitCommand(["rev-parse", "--short", "HEAD"], inputs))
}

public macro GitBranch(inputs: Tokens): Tokens {
    return Tokens() + Token(STRING_LITERAL, gitCommand(["rev-parse", "--abbrev-ref", "HEAD"], inputs))
}
