//
//  CmdUtil.swift
//  SymbolTool
//
//  Created by Mac-Mini on 2025/4/27.
//

import Cocoa

class CmdUtil: NSObject {
    
    static func executeCommand(_ command: String, arguments: [String] = []) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output
            }
        } catch {
            return "无法执行命令: \(error)"
        }
        return ""
    }

}
