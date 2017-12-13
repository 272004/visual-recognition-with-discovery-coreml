//
//  ViewController.swift
//  Core Ml Vision Simple
//
//  Created by Iain McCown on 11/29/17.
//  Copyright © 2017 Iain McCown. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO
import VisualRecognitionV3
import DiscoveryV1

class ImageClassificationViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var displayContainer: UIView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    
    let visualRecognitionApiKey = ""
    let visualRecognitionClassifierID = ""
    let discoveryUsername = ""
    let discoveryPassword = ""
    let discoveryEnvironmentID = ""
    let discoveryCollectionID = ""
    let version = "2017-11-10"
    
    var visualRecognition: VisualRecognition!
    var discovery: Discovery!
    
    var classifications: [VisualRecognitionV3.Classification] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.visualRecognition = VisualRecognition(apiKey: visualRecognitionApiKey, version: version, apiKeyTestServer: visualRecognitionApiKey)
        self.discovery = Discovery(username: discoveryUsername, password: discoveryPassword, version: version)
        // Pull down updated model if one is available
        visualRecognition.updateLocalModel(classifierID: visualRecognitionClassifierID)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - Pulley Library methods
    
    private var pulleyViewController: PulleyViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PulleyViewController {
            self.pulleyViewController = controller
        }
    }
    
    // MARK: - Display Methods
    
    func displayImage( image: UIImage ) {
        if let pulley = self.pulleyViewController {
            if let display = pulley.primaryContentViewController as? ImageDisplayViewController {
                display.image.contentMode = UIViewContentMode.scaleAspectFit
                display.image.image = image
            }
        }
    }
    
    // Convenience method for pushing data to the TableView.
    func getTableController(run: (_ tableController: ResultsTableViewController, _ drawer: PulleyViewController) -> Void) {
        if let drawer = self.pulleyViewController {
            if let tableController = drawer.drawerContentViewController as? ResultsTableViewController {
                run(tableController, drawer)
                tableController.tableView.reloadData()
            }
        }
    }
    
    // Convenience method for pushing classification data to TableView
    func displayResults() {
        getTableController { tableController, drawer in
            var classification = ""
            if self.classifications.isEmpty {
                classification = "Unrecognized"
            } else {
                classification = prettifyLabel(label: self.classifications[0].classification)
            }
            tableController.classificationLabel = classification
            
            if classification != "Unrecognized" {
                print("fetching discovery")
                fetchDiscoveryResults(query: classification)
            }
            
            self.dismiss(animated: false, completion: nil)
            //            drawer.setDrawerPosition(position: .collapsed, animated: true)
        }
    }
    
    // Remove any underscores from classification label
    func prettifyLabel(label: String) -> String {
        return label.components(separatedBy: "_").joined(separator: " ")
    }
    
    // MARK: - Discovery Methods
    
    // Convenience method for pushing discovery data to TableView
    func displayDiscoveryResults(data: String, title: String = "", subTitle: String = "") {
        getTableController { tableController, drawer in
            tableController.discoveryResult = data
            tableController.discoveryResultTitle = title
            tableController.discoveryResultSubtitle = subTitle
            self.dismiss(animated: false, completion: nil)
            //            drawer.setDrawerPosition(position: .collapsed, animated: true)
        }
    }

    
    // Method for querying Discovery
    func fetchDiscoveryResults(query: String) {
        DispatchQueue.main.async {
            self.displayDiscoveryResults(data: "Retrieving more information on " + query + "...")
        }
        
        let failure = { (error: Error) in
            print(error)
        }
        
        let queryItem = query.components(separatedBy: " ")[0]
        let generalQuery = "extracted_metadata.title%3A%22What%20is%20" + queryItem + "%3F%22"
        let filter = "text%3A%21%22faulty%22"
        self.discovery.queryDocumentsInCollection(
            withEnvironmentID: discoveryEnvironmentID,
            withCollectionID: discoveryCollectionID,
            withFilter: filter,
            withQuery: generalQuery,
            failure: failure)
        {
            queryResponse in
            if let results = queryResponse.results {
                DispatchQueue.main.async() {
                    var truncatedString = ""
                    var sectionTitle = ""
                    var subTitle = ""
                    if results.count > 0 {
                        let text = results[0].text as! String
                        truncatedString = text.count >= 350 ? text.prefix(350) + "..." : text
                        sectionTitle = "Description"
                        subTitle = query
                    } else {
                        truncatedString = "No Discovery results found."
                    }
                    self.displayDiscoveryResults(data: truncatedString, title: sectionTitle, subTitle: subTitle)
                }
            }
        }
    }
    
    
    // MARK: - Photo Actions
    
    @IBAction func takePicture() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    // MARK: - Image Classification
    
    func classifyImage(for image: UIImage, localThreshold: Double = 0.0) {
        
        let failure = { (error: Error) in
            print(error)
        }
        
        self.visualRecognition.classifyWithLocalModel(image: image, classifierIDs: [visualRecognitionClassifierID], threshold: localThreshold, failure: failure) { classifiedImages in
            
            if classifiedImages.images.count > 0 && classifiedImages.images[0].classifiers.count > 0 {
                self.classifications = classifiedImages.images[0].classifiers[0].classes
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.displayResults()
            }
        }
    }
    
}

extension ImageClassificationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Handling Image Picker Selection
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        DispatchQueue.main.async {
            self.displayImage( image: image )
        }
        
        classifyImage(for: image, localThreshold: 0.3)
    }
}


