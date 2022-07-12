# moduleinfo
>用于获取cpm包module.json简单信息的宏

## 使用
- 下载代码并创建cpm项目， 需要与使用的项目目录平级(否则自行修改依赖的path字段)
```shell
$ cd ~/CodeToCangjie
$ git clone https://gitee.com/HW-PLLab/moduleinfo.git
$ mkdir demo
$ cd demo
$ cpm new test demo
```
- 在`demo/module.json`添加`requires`
```json
"requires": {
	"moduleinfo": {
		"organization": "ystyle",
		"version":"1.0.0",
		"path": "../moduleinfo"
	  }
}
```
### 示例

```cj
from moduleinfo import moduleinfo.*

let cjc_version:String = @ModuleCjv(unknow)
let organization:String = @ModuleOrg(unknow)
let name:String = @ModuleName(unknow)
let description:String = @ModuleDesc(unknow)
let version:String = @ModuleVer(unknow)

main () {
    println("cjc_version: ${cjc_version}")
    println("organization: ${organization}")
    println("name: ${name}")
    println("description: ${description}")
    println("version: ${version}")
}
```