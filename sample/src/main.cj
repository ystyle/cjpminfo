package demo

import cjpminfo.*

let cjc_version: String = @ModuleCjv("xxx")
let organization: String = @ModuleOrg("xxx")
let name: String = @ModuleName("xxx")
let description: String = @ModuleDesc("xxx")
let version: String = @ModuleVer("xxx")
let cjc_ver: String = @CjcVersion("unknown")
let cjpm_ver: String = @CjpmVersion("unknown")
let git_tag: String = @GitTag("v0.0.0")
let git_commit_id: String = @GitCommitId("unknown")
let git_commit_id_short: String = @GitCommitIdShort("unknown")
let git_branch: String = @GitBranch("unknown")

main(): Int64 {
    println("cjc_version: ${cjc_version}")
    println("organization: ${organization}")
    println("name: ${name}")
    println("description: ${description}")
    println("version: ${version}")
    println("cjc_compiler_version: ${cjc_ver}")
    println("cjpm_manager_version: ${cjpm_ver}")
    println("git_tag: ${git_tag}")
    println("git_commit_id: ${git_commit_id}")
    println("git_commit_id_short: ${git_commit_id_short}")
    println("git_branch: ${git_branch}")
    return 0
}
