//
//  ViewController.swift
//  udpClient
//
//  Created by Mick on 2016/9/8.
//  Copyright © 2016年 ChengYang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var txtIPAddress: UITextField!
    @IBOutlet weak var txtPortNum: UITextField!
    @IBOutlet weak var txtSendMsg: UITextField!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var webView: UIWebView!
    
    private let log = NSMutableString()
    private var logMsg: String?
    
    // Prepare UDP socket
    private var udpSocket: GCDAsyncUdpSocket?
    private var tag:Int = 0
    private var packetTransferQueue: dispatch_queue_t?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupSocket()
        
        // Add Keyboard show and hide notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupSocket() {
        
        // Use main quese first
        packetTransferQueue = dispatch_queue_create("packetTransferQueue", DISPATCH_QUEUE_SERIAL)
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: packetTransferQueue)
        
        do {
            try udpSocket!.bindToPort(0)
        }
        catch let error {
            print("Error occur \(error)")
        }
        do {
            try udpSocket!.beginReceiving()
        }
        catch let error {
            print("Error occur \(error)")
        }
    }
    
    @IBAction func send(sender: AnyObject) {
        
        let host = txtIPAddress.text
        if host?.characters.count == 0{
            self.logError("Address required")
            return
        }
        
        if let port = Int(txtPortNum.text!) {
            
            if port <= 0 || port > 65535 {
                self.logError("Valid port required")
                return
            }
        }
        
        let sendMsg = txtSendMsg.text
        if sendMsg?.characters.count == 0{
            self.logError("Message required")
            return
        }
        
        // Try Send test status
        let data = sendMsg!.dataUsingEncoding(NSUTF8StringEncoding)
        self.udpSocket!.sendData(data!, toHost: txtIPAddress.text!, port: 8080, withTimeout: -1, tag: self.tag)
        self.logMessage("SENT \(tag): \(sendMsg)")
        
        tag += 1
    }
}

// Implement Log function
extension ViewController{
    
    func logError(msg: NSString) {
        
        let prefix = "<font color=\"#B40404\">"
        let suffix = "</font><br/>"
        log.appendFormat("%@%@%@\n", prefix, msg, suffix)
        
        let html = "<html><body>\n\(log)\n</body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func logInfo(msg: NSString) {
        
        let prefix = "<font color=\"#6A0888\">"
        let suffix = "</font><br/>"
        log.appendFormat("%@%@%@\n", prefix, msg, suffix)
        
        let html = "<html><body>\n\(log)\n</body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func logMessage(msg: NSString) {
        
        let prefix = "<font color=\"#000000\">"
        let suffix = "</font><br/>"
        log.appendFormat("%@%@%@\n", prefix, msg, suffix)
        
        let html = "<html><body>\n\(log)\n</body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }
}

extension ViewController: GCDAsyncUdpSocketDelegate{
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        
        // Check command string
        
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didConnectToAddress address: NSData) {
        print("did connect to address and data is \(address)")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didNotConnect error: NSError) {
        print("did not connect to address")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError) {
        print("Not send data")
    }
    
    @objc func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError) {
        print("Socket did close")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress address: NSData, withFilterContext filterContext: AnyObject?) {
        
        if let receiveMsg = String(data: data, encoding: NSUTF8StringEncoding) {
            
            self.logMessage("RECV: \(receiveMsg)")
        } else {
//            var host: NSString = ""
//            var port:UInt16 = 0
//            GCDAsyncUdpSocket.getHost(&host, port: &port, fromAddress: address)
            self.logInfo("RECV: Unknown message")
        }
    }
}

//MARK: Implement Keyboard notification handle function
extension ViewController {
    
    func keyboardWillShow(notification: NSNotification) {
        
        //Need to calculate keyboard exact size due to Apple suggestions
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        
        var webViewFrame = webView.frame
        webViewFrame.size.height -= keyboardSize!.height
        
        let animationDuration: Double = 0.0
        let animationBlock = {() -> Void in
            self.webView.frame = webViewFrame
        }
        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: UIViewAnimationOptions.LayoutSubviews, animations: animationBlock, completion: { _ in })

    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        //Once keyboard disappears, restore original positions
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        
        var webViewFrame = webView.frame
        webViewFrame.size.height += keyboardSize!.height
        
        let animationDuration: Double = 0.0
        let animationBlock = {() -> Void in
            self.webView.frame = webViewFrame
        }
        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: UIViewAnimationOptions.LayoutSubviews, animations: animationBlock, completion: { _ in })
    }
}



