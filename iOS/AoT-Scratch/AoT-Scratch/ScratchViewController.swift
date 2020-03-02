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
        
        let url = Bundle.main.url(forResource: "web/index", withExtension: "html")!
        let webFolderUrl = Bundle.main.url(forResource: "web", withExtension: nil)!
        webView.loadFileURL(url, allowingReadAccessTo: webFolderUrl)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Pass the URL to the assets folder within the bundle so scratch-storage can load from it
        let assetsFolderUrl = Bundle.main.url(forResource: "web/assets", withExtension: nil)!
        webView.evaluateJavaScript("Scratch.init('\(assetsFolderUrl)');", completionHandler: nil);
    }

}
