package demo

import cjpminfo.*

let cjc_version: String = @ModuleCjv("xxx")
let organization: String = @ModuleOrg("xxx")
let name: String = @ModuleName("xxx")
let description: String = @ModuleDesc("xxx")
let version: String = @ModuleVer("xxx")

main(): Int64 {
    println("cjc_version: ${cjc_version}")
    println("organization: ${organization}")
    println("name: ${name}")
    println("description: ${description}")
    println("version: ${version}")
    return 0
}
