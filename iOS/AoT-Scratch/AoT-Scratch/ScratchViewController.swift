//
//  ScratchViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 2/28/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import WebKit

class ScratchViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    var project : Project! = nil
    var urlSession = URLSession(configuration: .default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let webContentController = WKUserContentController()
        webContentController.add(self, name: "scratchOut")
        webConfiguration.userContentController = webContentController
        
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(webView)
        view.sendSubviewToBack(webView)

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let localWebFolderUrl = documents.appendingPathComponent("web", isDirectory: true)        
        let indexUrl = localWebFolderUrl.appendingPathComponent("index.html")
        webView.loadFileURL(indexUrl, allowingReadAccessTo: documents)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Pass the URL to the assets folder within the bundle so scratch-storage can load from it
        let defaultAssetsUrl = LOCAL_WEB_FOLDER_URL.appendingPathComponent("assets", isDirectory: true)
        
        let sprite3Data = createSprite3Archive(from: project)
        let spriteBase64String = sprite3Data.base64EncodedString()
        webView.evaluateJavaScript("""
            Scratch.init('\(defaultAssetsUrl)');
            Scratch.injectBase64Sprite3Data('\(spriteBase64String)');
        """, completionHandler: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let sprite3Payload = message.body as? String {
            var request = URLRequest(url: RELAY_SERVER_URL)
            request.httpMethod = "POST"
            request.httpBody = sprite3Payload.data(using: .utf8)
            let task = urlSession.dataTask(with: request) { (data, response, error) in
                // @TODO: Error handling, etc. here
            }
            task.resume()
        }
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        // @TODO: Block UI on saving
        webView.evaluateJavaScript("Scratch.vm.exportSpriteJson(Scratch.vm.editingTarget.id)") { (res, err) in
            if let json = res as? String {
                self.project.json = json
                writeProjectToDisk(self.project)
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func greenFlagTapped(_ sender: Any) {
        webView.evaluateJavaScript("Scratch.vm.greenFlag();", completionHandler: nil)
    }
    
    @IBAction func stopTapped(_ sender: Any) {
        webView.evaluateJavaScript("Scratch.vm.stopAll();", completionHandler: nil)
    }
    
    @IBAction func sendToProjectorTapped(_ sender: Any) {
        webView.evaluateJavaScript("Scratch.sendToProjector();", completionHandler: nil)
    }
}
