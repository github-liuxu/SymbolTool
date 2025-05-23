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
    @IBOutlet weak var uuid: NSTextField!
    var arch = "arm64"
    var parsequeue = DispatchQueue.global()
    var logText = ""
    var parser: ParserProtocol?
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

    @IBAction func didSelectedArch(_ sender: NSComboBox) {
        arch = sender.objectValueOfSelectedItem as! String
        if dsymPath.stringValue.count > 0 {
            uuid.stringValue = "UUID: " + (parser?.getUUID(arch: arch) ?? "")
        }
        logText += arch + "\n"
        logText += uuid.stringValue + "\n"
    }
    
    @IBAction func didSelectedPlatform(_ sender: NSComboBox) {
        if sender.stringValue == "iOS" {
            parser = Parser()
        } else if sender.stringValue == "Android" {
            parser = AndroidParser()
        } else if sender.stringValue == "Harmony" {
            parser = HarmonyParser()
        }
        logText += sender.stringValue + "\n"
        parser?.setArch(arch: arch)
        parser?.setDsymPath(path: dsymPath.stringValue)
        uuid.stringValue = "UUID: " + (parser?.getUUID(arch: arch) ?? "")
    }
    
    @IBAction func openDSYMFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select file"
        openPanel.prompt = "Select"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["dSYM", "so"]
        if openPanel.runModal() == .OK {
            if let selectedFile = openPanel.url {
                dsymPath.stringValue = selectedFile.path
                parser?.setDsymPath(path: selectedFile.path)
                parser?.setArch(arch: arch)
                uuid.stringValue = "UUID: " + (parser?.getUUID(arch: arch) ?? "")
                logText += selectedFile.path + " " + arch  + " uuid " + uuid.stringValue + "\n"
            }
        } else {
            print("用户取消选择")
        }
    }
    
    @IBAction func parse(_ sender: NSButton) {
        self.parseText = ""
        parsequeue.async {
            let count = self.originText.split(separator: "\n").count
            var currentLine = 0
            self.originText.enumerateLines { line, _ in
                currentLine += 1
                self.parseText = self.parseText + (self.parser?.parser(text: line) ?? "")
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
    
    @IBAction func manualClick(_ sender: NSButton) {
        let manualVC = ManualViewController(nibName: "ManualViewController", bundle: Bundle.main)
        parser?.setArch(arch: arch)
        parser?.setDsymPath(path: dsymPath.stringValue)
        manualVC.parser = parser
        manualVC.logBlock = { [weak self] log in
            self?.logText += log + "\n"
        }
        presentAsModalWindow(manualVC)
    }
    
    @IBAction func logClick(_ sender: NSButton) {
        let logVC = LogViewController(nibName: "LogViewController", bundle: Bundle.main)
        presentAsModalWindow(logVC)
        logVC.textView.string = logText
    }
    
}

