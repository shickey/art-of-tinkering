//
//  ProjectsCollectionViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 2/28/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit

private let projectReuseIdentifier = "ProjectCell"
private let addReuseIdentifier = "AddProjectCell"

protocol ProjectManager {
    func projectWasCreated(project: Project)
}

class ProjectCell : UICollectionViewCell {
    @IBOutlet weak var projectThumbnail: UIImageView!
}

class AddProjectCell : UICollectionViewCell {}

class EqualSpacingFlowLayout : UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        let itemsPerRow = Int(collectionViewContentSize.width) / Int(itemSize.width)
        let leftoverPixels = Int(collectionViewContentSize.width) % Int(itemSize.width)
        
        let spacing = CGFloat(Int(CGFloat(leftoverPixels) / CGFloat(itemsPerRow + 1)))
        
        sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
    }
    
}

class ProjectsCollectionViewController: UICollectionViewController, ProjectManager {
    
    var projects : [Project]! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imageCaptureVC = segue.destination as? ImageCaptureViewController {
            imageCaptureVC.projectManager = self
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return projects.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("Adding cell at index path \(indexPath)")
        if indexPath.item == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: addReuseIdentifier, for: indexPath) as! AddProjectCell
        }
        
        let project = projects[indexPath.item - 1]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: projectReuseIdentifier, for: indexPath) as! ProjectCell
        cell.projectThumbnail.image = project.image
    
        return cell
    }
    
    // MARK: ProjectManager
    func projectWasCreated(project: Project) {
        projects.append(project)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let scratchVC = storyboard.instantiateViewController(withIdentifier: "Scratch") as! ScratchViewController
        scratchVC.project = project
        navigationController!.setViewControllers([navigationController!.viewControllers[0], scratchVC], animated: true)
    }

}
