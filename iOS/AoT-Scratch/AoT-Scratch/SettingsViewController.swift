//
//  SettingsViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/21/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit

private let backgroundReuseIdentifier = "BackgroundCell"
class BackgroundCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var checkIcon: UIImageView!
}

class SettingsViewController: UIViewController, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    struct Background {
        var isSelected : Bool
        let filename : String
        let image : UIImage
    }
    
    @IBOutlet weak var relayServerUrlField: UITextField!
    @IBOutlet weak var relayServerValidation: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var originalRelayServerUrl : URL! = nil
    var updatedRelayServerUrl : URL! = nil
    
    var backgrounds : [Background]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalRelayServerUrl = UserDefaults.standard.url(forKey: USER_DEFAULTS_RELAY_SERVER_URL_KEY)!
        updatedRelayServerUrl = originalRelayServerUrl
        
        relayServerUrlField.text = originalRelayServerUrl.withoutScheme()
        
        let localAssetsUrl = LOCAL_WEB_FOLDER_URL.appendingPathComponent("assets", isDirectory: true)
        let assetFolderContents = try! FileManager.default.contentsOfDirectory(at: localAssetsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var backgroundPaths : [String] = []
        for url in assetFolderContents {
            if url.pathExtension == "png" {
                backgroundPaths.append(url.lastPathComponent)
            }
        }
        backgroundPaths.sort { (a, b) -> Bool in
            // Always put the white and black backgrounds first
            if a == "739b5e2a2435f6e1ec2993791b423146.png" { return true }
            if b == "739b5e2a2435f6e1ec2993791b423146.png" { return false}
            if a == "105e0d26858aba223d0e8f759e36db38.png" { return true }
            if b == "105e0d26858aba223d0e8f759e36db38.png" { return false}
            return a < b
        }
        
        let currentSelectedBackgroundPath = UserDefaults.standard.string(forKey: USER_DEFAULTS_BACKGROUND_KEY)!
        for path in backgroundPaths {
            let image = UIImage(contentsOfFile: localAssetsUrl.appendingPathComponent(path).path)!
            var background = Background(isSelected: false, filename: path, image: image)
            if path == currentSelectedBackgroundPath {
                background.isSelected = true
            }
            backgrounds.append(background)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        for (idx, background) in backgrounds.enumerated() {
            if background.isSelected {
                collectionView.selectItem(at: IndexPath(item: idx, section: 0), animated: false, scrollPosition: .top)
            }
        }
        relayServerValidation.isHidden = true
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        if relayServerUrlField.isEditing {
            relayServerUrlField.endEditing(false)
        }
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
            if let selectedItemIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let selectedBackground = backgrounds[selectedItemIndexPath.item]
                UserDefaults.standard.set(selectedBackground.filename, forKey: USER_DEFAULTS_BACKGROUND_KEY)
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
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backgrounds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let background = backgrounds[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: backgroundReuseIdentifier, for: indexPath) as! BackgroundCell
        cell.imageView.image = background.image
        if background.isSelected {
            cell.checkIcon.isHidden = false
        }
        else {
            cell.checkIcon.isHidden = true
        }
    
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? BackgroundCell {
            cell.checkIcon.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? BackgroundCell {
            cell.checkIcon.isHidden = true
        }
    }
    
    // MARK: Debug Stuff
    
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
