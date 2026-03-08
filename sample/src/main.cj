package demo

import cjpminfo.*

let cjc_version: String = @ModuleCjv("xxx")
let organization: String = @ModuleOrg("xxx")
let name: String = @ModuleName("xxx")
let description: String = @ModuleDesc("xxx")
let version: String = @ModuleVer("xxx")
let cjc_ver: String = @CjcVersion("unknown")
let cjpm_ver: String = @CjpmVersion("unknown")

main(): Int64 {
    println("cjc_version: ${cjc_version}")
    println("organization: ${organization}")
    println("name: ${name}")
    println("description: ${description}")
    println("version: ${version}")
    println("cjc_compiler_version: ${cjc_ver}")
    println("cjpm_manager_version: ${cjpm_ver}")
    return 0
}
