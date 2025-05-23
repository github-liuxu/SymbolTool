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
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"
        environment["LANG"] = "en_US.UTF-8"
        process.environment = environment
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

    enum ShellError: Error, CustomStringConvertible {
        case launchError(Error)
        case nonZeroExit(code: Int32, stderr: String?)
        
        var description: String {
            switch self {
            case .launchError(let error):
                return "启动失败: \(error)"
            case .nonZeroExit(let code, let stderr):
                return "退出码 \(code)，错误信息: \(stderr ?? "无")"
            }
        }
    }

    static func runShell(command: String,
                  arguments: [String] = [],
                  environment: [String: String]? = nil) -> Result<String, ShellError> {
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.environment = environment ?? ProcessInfo.processInfo.environment
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        do {
            try process.run()
        } catch {
            return .failure(.launchError(error))
        }
        
        process.waitUntilExit()
        
        let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if process.terminationStatus == 0 {
            return .success(output)
        } else {
            return .failure(.nonZeroExit(code: process.terminationStatus, stderr: errorOutput))
        }
    }
}
