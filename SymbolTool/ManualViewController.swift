//
//  ManualViewController.swift
//  SymbolTool
//
//  Created by Mac-Mini on 2025/4/27.
//

import Cocoa

class ManualViewController: NSViewController {

    var arch = "arm64"
    var dsymPath = ""
    var atosPath = ""
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var offset: NSTextField!
    @IBOutlet weak var symbleAddr: NSTextField!
    @IBOutlet weak var loadAddr: NSTextField!
    var logBlock: ((String) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func parseClick(_ sender: NSButton) {
        var symbleText = symbleAddr.stringValue
        if symbleAddr.stringValue.count == 0 {
            var hexStr = loadAddr.stringValue
            if hexStr.hasPrefix("0x") {
                hexStr = hexStr.replacingOccurrences(of: "0x", with: "")
            }
            if let decimalValue = Int64(hexStr, radix: 16) {
                let addr = decimalValue + (Int64(offset.stringValue) ?? 0)
                symbleText = "0x" + String(addr, radix: 16)
            }
        }
        
        let args: [String] = ["-arch",arch,"-o",dsymPath, "-l",loadAddr.stringValue, symbleText]
        logBlock?("atos args: \(args)")
        let txt = CmdUtil.executeCommand(atosPath, arguments: args)
        self.textView.string = txt
        logBlock?(txt)
    }
    
}
