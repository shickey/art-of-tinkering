//
//  ScratchViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 2/28/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import WebKit

class ScratchViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var webView: WKWebView!
    
    var imageHash : String! = nil
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let localWebFolderUrl = documents.appendingPathComponent("web", isDirectory: true)        
        let indexUrl = localWebFolderUrl.appendingPathComponent("index.html")
        webView.loadFileURL(indexUrl, allowingReadAccessTo: documents)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Pass the URL to the assets folder within the bundle so scratch-storage can load from it
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let localWebFolderUrl = documents.appendingPathComponent("web", isDirectory: true)
        let defaultAssetsUrl = localWebFolderUrl.appendingPathComponent("assets", isDirectory: true)
        let spriteImagesUrl = documents.appendingPathComponent("sprite-images", isDirectory: true)
        
        webView.evaluateJavaScript("Scratch.init('\(defaultAssetsUrl)', '\(spriteImagesUrl)', '\(imageHash!)');", completionHandler: nil)
    }

}
