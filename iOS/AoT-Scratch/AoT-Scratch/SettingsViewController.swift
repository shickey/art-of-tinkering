//
//  SettingsViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/21/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var relayServerUrlField: UITextField!
    @IBOutlet weak var relayServerValidation: UILabel!
    
    var originalRelayServerUrl : URL! = nil
    var updatedRelayServerUrl : URL! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalRelayServerUrl = UserDefaults.standard.url(forKey: USER_DEFAULTS_RELAY_SERVER_URL_KEY)!
        updatedRelayServerUrl = originalRelayServerUrl
        
        relayServerUrlField.text = originalRelayServerUrl.withoutScheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        relayServerValidation.isHidden = true
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        if updatedRelayServerUrl == nil {
            let alert = UIAlertController(title: "Invalid Server URL", message: "The relay server url is invalid. Would you like to discard your changes or fix the URL?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Discard", style: .default, handler: { _ in
                self.presentingViewController!.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Fix it", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        else {
            if originalRelayServerUrl != updatedRelayServerUrl {
                // Save the new URL
                UserDefaults.standard.set(updatedRelayServerUrl, forKey: USER_DEFAULTS_RELAY_SERVER_URL_KEY)
            }
            presentingViewController!.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let newUrlText = textField.text else {
            relayServerValidation.text = "Please enter a relay server URL"
            relayServerValidation.isHidden = false
            updatedRelayServerUrl = nil
            return
        }
        guard newUrlText != "" else {
            relayServerValidation.text = "Please enter a relay server URL"
            relayServerValidation.isHidden = false
            updatedRelayServerUrl = nil
            return
        }
        guard let newRelayUrl = URL(string: "http://\(newUrlText)") else {
            relayServerValidation.text = "Please enter a valid URL"
            relayServerValidation.isHidden = false
            updatedRelayServerUrl = nil
            return
        }
        updatedRelayServerUrl = newRelayUrl
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        relayServerValidation.isHidden = true
        return true
    }
    
    @IBAction func textFieldDidChange(_ sender: Any) {
        relayServerValidation.isHidden = true
    }
    
    @IBAction func resetProjectsFolderTapped(_ sender: Any) {
        /*
        @TODO: In case this comes in handy in the future:
         
        let alert = UIAlertController(title: "Reset Projects?", message: "Are you sure you want to reset the projects folder? This will delete all projects from the device. You cannot undo this action.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
            //AotStore.resetProjects()
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        */
    }
}
