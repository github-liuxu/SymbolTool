//
//  ParserProtocol.swift
//  SymbolTool
//
//  Created by Mac-Mini on 2025/5/23.
//

import Foundation

protocol ParserProtocol {
    func setDsymPath(path: String)
    func setArch(arch: String)
    func getUUID(arch: String) -> String
    func parser(text: String) -> String
    func parser(params: [String]) -> String
}

class Parser: ParserProtocol {
    var dsymPath: String = ""
    var parserExePath: String = ""
    var atosPath: String = ""
    var keyWorld: String = ""
    var arch: String = "arm64"
    init() {
        atosPath = CmdUtil.executeCommand("/usr/bin/which", arguments: ["atos"]).replacingOccurrences(of: "\n", with: "")
    }
    
    func setDsymPath(path: String) {
        let fm = FileManager.default
        let content = try? fm.contentsOfDirectory(atPath: path + "/Contents/Resources/DWARF")
        if let name = content?.first {
            dsymPath = path + "/Contents/Resources/DWARF/" + name
            keyWorld = name
        }
    }
    
    func setArch(arch: String) {
        self.arch = arch
    }
    
    func getUUID(arch: String) -> String {
        let uuids = CmdUtil.executeCommand("/usr/bin/dwarfdump", arguments: ["--uuid", dsymPath]).split(separator: "\n")
        var uuid = ""
        uuids.forEach { uuidInfo in
            let info = uuidInfo.split(separator: " ")
            if info.count > 2 {
                if String(info[2]).contains(arch) {
                    uuid = String(info[1])
                }
            }
        }
        return uuid
    }
    
    func parser(text: String) -> String {
        if !text.contains(keyWorld) {
            return text
        }
        let tempTxt = text.replacingOccurrences(of: "\t", with: "")
        let items = tempTxt.split(separator: " ")
        let index = items.firstIndex { item in
            item.hasPrefix("0x")
        }
        var addr0 = ""
        var addr1 = ""
        if let index = index {
            if items.count > index {
                addr0 = String(items[index])
                if items.count > index + 1 {
                    addr1 = String(items[index + 1])
                }
            }
        }
        let args = ["-arch",arch,"-o",dsymPath, "-l",addr1, addr0]
        return CmdUtil.executeCommand(atosPath, arguments: args)
    }
    
    func parser(params: [String]) -> String {
        let args = ["-arch",arch,"-o",dsymPath, "-l", params[0], params[1]]
        return CmdUtil.executeCommand(atosPath, arguments: args)
    }
}

class AndroidParser: ParserProtocol {
    var dsymPath: String = ""
    var parserExePath: String = ""
    var addr2line: String = ""
    var keyWorld: String = ""
    var arch: String = "arm64"
    init() {
        let home = "/Users/" + CmdUtil.executeCommand("/usr/bin/whoami").replacingOccurrences(of: "\n", with: "")
        addr2line = home + "/android-ndk-r21/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin/aarch64-linux-android-addr2line"
    }
    func setDsymPath(path: String) {
        self.dsymPath = path
        let fileInfo = CmdUtil.executeCommand("/usr/bin/file", arguments: [path])
        let buildId = fileInfo.split(separator: ",").filter { $0.contains("BuildID") }
        if buildId.count > 0 {
            let array: Array =  buildId[0].split(separator: "=")
            if array.count > 1 {
                keyWorld = String(array[1])
            }
        }
    }

    func setArch(arch: String) {
        self.arch = arch
    }

    func getUUID(arch: String) -> String {
        return keyWorld
    }

    func parser(text: String) -> String {
        if !text.contains(keyWorld) {
            return text
        }
        let array = text.split(separator: " ")
        if array.count >= 3 {
            let addr = String(array[2])
            let result = CmdUtil.executeCommand(addr2line, arguments: ["-C -f -e", self.dsymPath, addr])
            return result
        }
        return text
    }
    
    func parser(params: [String]) -> String {
        if params.count == 0 {
            return ""
        }
        let result = CmdUtil.executeCommand(addr2line, arguments: ["-C -f -e", self.dsymPath, params.first ?? ""])
        return result
    }
}

class HarmonyParser: ParserProtocol {
    var dsymPath: String = ""
    var parserExePath: String = ""
    var addr2line: String = ""
    var keyWorld: String = ""
    var arch: String = "arm64"
    init() {
        let home = "/Users/" + CmdUtil.executeCommand("/usr/bin/whoami").replacingOccurrences(of: "\n", with: "")
        addr2line = home + "/command-line-tools/sdk/default/openharmony/native/llvm/bin/llvm-addr2line"
    }
    func setDsymPath(path: String) {
        self.dsymPath = path
        let fileInfo = CmdUtil.executeCommand("/usr/bin/file", arguments: [path])
        let buildId = fileInfo.split(separator: ",").filter { $0.contains("BuildID") }
        if buildId.count > 0 {
            let array: Array =  buildId[0].split(separator: "=")
            if array.count > 1 {
                keyWorld = String(array[1])
            }
        }
    }

    func setArch(arch: String) {
        self.arch = arch
    }

    func getUUID(arch: String) -> String {
        return keyWorld
    }

    func parser(text: String) -> String {
        if !text.contains(keyWorld) {
            return text
        }
        let array = text.split(separator: " ")
        if array.count >= 3 {
            let addr = String(array[2])
            let result = CmdUtil.executeCommand(addr2line, arguments: ["-Cfie", self.dsymPath, addr])
            return result
        }
        return text
    }
    
    func parser(params: [String]) -> String {
        if params.count == 0 {
            return ""
        }
        let result = CmdUtil.executeCommand(addr2line, arguments: ["-Cfie", self.dsymPath, params.first ?? ""])
        return result
    }
}
