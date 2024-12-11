//
//  ViewController.swift
//  SymbolTool
//
//  Created by Mac-Mini on 2024/12/11.
//

import Cocoa

@propertyWrapper
struct Atomic<Value> {
    
    private var value: Value
    private let lock = NSLock()
    
    init(wrappedValue value: Value) {
        self.value = value
    }
    
    var wrappedValue: Value {
        get { return load() }
        set { store(newValue: newValue) }
    }
    
    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    
    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}

class ViewController: NSViewController {
    @IBOutlet weak var dsymPath: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @Atomic var originText = ""
    @Atomic var parseText = ""
    var keyWorld = "NvStreamingSdkCore"
    var atosPath = "/usr/bin/atos"
    var parsequeue = DispatchQueue.global()
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.doubleValue = 0
        progressBar.minValue = 0
        progressBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)),
                                                       name: NSText.didChangeNotification,
                                                       object: textView)
        atosPath = executeCommand("/usr/bin/which", arguments: ["atos"]).replacingOccurrences(of: "\n", with: "")
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func textDidChange(_ notification: Notification) {
        self.originText = textView.string
    }

    @IBAction func openDSYMFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select file"
        openPanel.prompt = "Select"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["dSYM"]
        if openPanel.runModal() == .OK {
            if let selectedFile = openPanel.url {
                dsymPath.stringValue = selectedFile.path
                let fm = FileManager.default
                let content = try? fm.contentsOfDirectory(atPath: selectedFile.path + "/Contents/Resources/DWARF")
                if let name = content?.first {
                    keyWorld = name
                }
            }
        } else {
            print("用户取消选择")
        }
    }
    
    @IBAction func parse(_ sender: NSButton) {
        self.parseText = ""
        let dsymPathValue = dsymPath.stringValue
        parsequeue.async {
            let count = self.originText.split(separator: "\n").count
            var currentLine = 0
            self.originText.enumerateLines { line, _ in
                currentLine += 1
                if line.contains(self.keyWorld) {
                    self.parseText = self.parseText + self.atosSymbol(dsymPath: dsymPathValue ,text: line)
                } else {
                    self.parseText = self.parseText + line + "\n"
                }
                DispatchQueue.main.async {
                    self.progressBar.isHidden = false
                    self.progressBar.maxValue = Double(count)
                    self.progressBar.doubleValue = Double(currentLine)
                    self.textView.string = self.parseText
                    let range = NSRange(location: self.textView.string.count, length: 0)
                    self.textView.scrollRangeToVisible(range)
                }
            }
            DispatchQueue.main.async {
                self.progressBar.isHidden = true
                self.textView.string = self.parseText
            }
        }
        
    }
    
    func atosSymbol(dsymPath: String, text: String)-> String {
        let items = text.split(separator: " ")
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
        let args = ["-arch","arm64","-o",dsymPath + "/Contents/Resources/DWARF/" + keyWorld, "-l",addr1, addr0]
        return executeCommand(atosPath, arguments: args)
    }
    
    func executeCommand(_ command: String, arguments: [String] = []) -> String {
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

