//
//  ManualViewController.swift
//  SymbolTool
//
//  Created by Mac-Mini on 2025/4/27.
//

import Cocoa

class ManualViewController: NSViewController {

    var parser: ParserProtocol?
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
        if parser?.type() == "iOS" {
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
            
            let txt = parser?.parser(params: [loadAddr.stringValue, symbleText]) ?? ""
            self.textView.string = txt
            logBlock?(txt)
        } else if parser?.type() == "Android" {
            var symbleText = symbleAddr.stringValue
            if symbleAddr.stringValue.count == 0 {
                var hexStr = loadAddr.stringValue
//                if hexStr.hasPrefix("0x") {
//                    hexStr = hexStr.replacingOccurrences(of: "0x", with: "")
//                }
                let txt = parser?.parser(params: [hexStr]) ?? ""
                self.textView.string = txt
                logBlock?(txt)
            }
        } else if parser?.type() == "Harmony" {
            var symbleText = symbleAddr.stringValue
            if symbleAddr.stringValue.count == 0 {
                var hexStr = loadAddr.stringValue
                if hexStr.hasPrefix("0x") {
                    hexStr = hexStr.replacingOccurrences(of: "0x", with: "")
                }
                let txt = parser?.parser(params: [hexStr]) ?? ""
                self.textView.string = txt
                logBlock?(txt)
            }
        }
        
    }
    
}
