//
//  SettingViewController.swift
//  SymbolTool
//
//  Created by Mac-Mini on 2025/7/10.
//

import Cocoa

class SettingViewController: NSViewController {

    @IBOutlet weak var atosTextField: NSTextFieldCell!
    @IBOutlet weak var androidAddrField: NSTextFieldCell!
    @IBOutlet weak var harmonyAddrField: NSTextFieldCell!
    
    var saveComplate: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        atosTextField.stringValue = UserDefaults().string(forKey: "AtosPath") ?? ""
        if atosTextField.stringValue.count == 0 {
            atosTextField.stringValue = CmdUtil.executeCommand("/usr/bin/which", arguments: ["atos"]).replacingOccurrences(of: "\n", with: "")

        }
        androidAddrField.stringValue = UserDefaults().string(forKey: "AndroidAddr") ?? ""
        harmonyAddrField.stringValue = UserDefaults().string(forKey: "HarmonyAddr") ?? ""
    }
    
    @IBAction func atosOpen(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select file"
        openPanel.prompt = "Select"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["public.unix-executable","public.executable"]
        if openPanel.runModal() == .OK {
            if let selectedFile = openPanel.url {
                atosTextField.stringValue = selectedFile.path
            }
        } else {
            print("用户取消选择")
        }
    }
    
    @IBAction func androidAddrOpen(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select file"
        openPanel.prompt = "Select"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["public.unix-executable","public.executable"]
        if openPanel.runModal() == .OK {
            if let selectedFile = openPanel.url {
                androidAddrField.stringValue = selectedFile.path
            }
        } else {
            print("用户取消选择")
        }
    }
    
    @IBAction func harmonyAddrOpen(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select file"
        openPanel.prompt = "Select"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["public.unix-executable","public.executable"]
        if openPanel.runModal() == .OK {
            if let selectedFile = openPanel.url {
                harmonyAddrField.stringValue = selectedFile.path
            }
        } else {
            print("用户取消选择")
        }
    }
    
    @IBAction func saveClick(_ sender: NSButton) {
        UserDefaults().set(atosTextField.stringValue, forKey: "AtosPath")
        UserDefaults().set(androidAddrField.stringValue, forKey: "AndroidAddr")
        UserDefaults().set(harmonyAddrField.stringValue, forKey: "HarmonyAddr")
        if let saveComplate = self.saveComplate {
            saveComplate()
        }
    }
    
}
