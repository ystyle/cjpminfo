// cjpminfo.core 单元测试
// 覆盖：编译器 argv 取包目录（-p / -p= / 裸 .cj 输入）、向上找 cjpm.toml、
//       [package] 段解析（含干扰键、行尾注释）、清单缺失容错、git 参数注入项目目录
package cjpminfo.core

import std.unittest.testmacro.*
import std.fs.{Directory, File, OpenMode, Path}

// 造一个临时项目：<tmp>/proj/cjpm.toml 内容为 content
func makeProject(content: String): String {
    let base = Directory.createTemp(Path("/tmp")).toString()
    let dir = Path(base).join("proj")
    Directory.create(dir, recursive: true)
    let f = File(dir.join("cjpm.toml"), OpenMode.Write)
    f.write(content.toArray())
    f.close()
    return dir.toString()
}

const MANIFEST = """
[dependencies]

[package]
  cjc-version = "1.1.3"
  description = "使用宏获取cjpm.toml信息"
  name = "cjpminfo"
  output-type = "static"
  version = "1.2.0"
"""

@Test
func parseTomlValueReadsPackageFields(): Unit {
    @Expect(parseTomlValue(MANIFEST, "version"), "1.2.0")
    @Expect(parseTomlValue(MANIFEST, "name"), "cjpminfo")
    @Expect(parseTomlValue(MANIFEST, "cjc-version"), "1.1.3")
    @Expect(parseTomlValue(MANIFEST, "output-type"), "static")
    @Expect(parseTomlValue(MANIFEST, "description"), "使用宏获取cjpm.toml信息")
}

@Test
func parseTomlValueIgnoresOtherSections(): Unit {
    // [dependencies] 里的同名键不能被当成 [package] 的
    let content = """
[dependencies]
  version = "9.9.9"

[package]
  version = "1.2.0"
"""
    @Expect(parseTomlValue(content, "version"), "1.2.0")
}

@Test
func parseTomlValueRequiresKeyBoundary(): Unit {
    // "name-x" 不能被 "name" 命中
    let content = """
[package]
  name-x = "wrong"
  name = "right"
"""
    @Expect(parseTomlValue(content, "name"), "right")
}

@Test
func parseTomlValueStripsTrailingComment(): Unit {
    let content = """
[package]
  version = "1.2.0" # 注释
"""
    @Expect(parseTomlValue(content, "version"), "1.2.0")
}

@Test
func parseTomlValueReturnsEmptyWhenMissing(): Unit {
    @Expect(parseTomlValue(MANIFEST, "repository"), "")
}

@Test
func startDirFromArgsReadsDashP(): Unit {
    let args = ["cjc", "-p", "/a/b/src", "--output-dir=/x", "-o=y"]
    @Expect(startDirFromArgs(args) ?? "", "/a/b/src")
}

@Test
func startDirFromArgsReadsEqualsForm(): Unit {
    @Expect(startDirFromArgs(["cjc", "-p=/a/b/src", "-o=x"]) ?? "", "/a/b/src")
    @Expect(startDirFromArgs(["cjc", "--package=/a/b/src"]) ?? "", "/a/b/src")
}

@Test
func startDirFromArgsFallsBackToSourceFile(): Unit {
    // 编译 build.cj 这类"直接给源码文件"的调用没有 -p
    let args = ["cjc", "/w/guanyi/cjpm_ws-0.1.4/build.cj", "-o", "/tmp/bs"]
    @Expect(startDirFromArgs(args) ?? "", "/w/guanyi/cjpm_ws-0.1.4")
}

@Test
func startDirFromArgsReturnsNoneWithoutClues(): Unit {
    @Expect(startDirFromArgs(["cjc", "-o=x"]).isNone(), true)
    @Expect(startDirFromArgs([]).isNone(), true)
}

@Test
func findProjectDirWalksUpFromSubpackage(): Unit {
    // 子包编译时 -p 指向 <proj>/src/sub，必须向上找到 <proj>
    let proj = makeProject(MANIFEST)
    let sub = Path(proj).join("src").join("sub")
    Directory.create(sub, recursive: true)
    @Expect(findProjectDir(sub.toString()) ?? "", proj)
    @Expect(findProjectDir(Path(proj).join("src").toString()) ?? "", proj)
    @Expect(findProjectDir(proj) ?? "", proj)
}

@Test
func findProjectDirReturnsNoneWhenAbsent(): Unit {
    let base = Directory.createTemp(Path("/tmp")).toString()
    let lonely = Path(base).join("no-manifest")
    Directory.create(lonely, recursive: true)
    @Expect(findProjectDir(lonely.toString()).isNone(), true)
}

@Test
func loadModuleReturnsNoneOnMissingManifest(): Unit {
    @Expect(loadModule("/definitely/not/here").isNone(), true)
}

@Test
func loadModuleParsesManifest(): Unit {
    let proj = makeProject(MANIFEST)
    match (loadModule(proj)) {
        case Some(m) =>
            @Expect(m.version, "1.2.0")
            @Expect(m.name, "cjpminfo")
        case None => @Fail("expected module to load")
    }
}

@Test
func parseModuleKeepsEmptyForAbsentOrganization(): Unit {
    // organization 在 cjpm.toml 里通常没有；保持空串，由宏层决定退回入参
    let m = parseModule(MANIFEST)
    @Expect(m.organization, "")
}

@Test
func prependProjectDirAddsDashC(): Unit {
    let args = prependProjectDir(["describe", "--tags"], Some("/proj"))
    @Expect(args, ["-C", "/proj", "describe", "--tags"])
}

@Test
func prependProjectDirWithoutProjectKeepsArgs(): Unit {
    @Expect(prependProjectDir(["rev-parse", "HEAD"], None), ["rev-parse", "HEAD"])
}
