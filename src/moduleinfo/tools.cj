macro package moduleinfo

from serialization import serialization.{ Serializable, DataModel, DataModelStruct }
from std import ast.*
from std import os.{Process}
from std import fs.{File, OpenOption}
from encoding import json.*

class Module <: Serializable<Module> {
    Module(
        let cjc_version:String,
        let organization:String,
        let name:String,
        let description:String,
        let version:String,
        let output_type:String
    ) {

    }
    public func serialize(): DataModel {
        return DataModelStruct()
    }
    public static func deserialize(dm: DataModel): Module {
        var dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let cjc_version = String.deserialize(dms.get("cjc_version"))
        let organization = String.deserialize(dms.get("organization"))
        let name = String.deserialize(dms.get("name"))
        let description = String.deserialize(dms.get("description"))
        let version = String.deserialize(dms.get("version"))
        let output_type = String.deserialize(dms.get("output_type"))
        return Module(cjc_version, organization, name, description, version, output_type)
    }
}

var d:?Module= None
var cjcver:?String = None
var loaded = false

func getModule():?Module {
    if (loaded) {
        return d
    }
    let fs = File("./module.json", OpenOption.Open(true, false))
    let text = fs.readToEnd()
    let m = JsonObject.fromStr(String.fromUtf8(text))
    d = Module.deserialize(DataModel.fromJson(m))
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