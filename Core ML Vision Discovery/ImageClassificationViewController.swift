/**
 * Copyright IBM Corporation 2017, 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

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
    @IBOutlet weak var currentModelLabel: UILabel!
    @IBOutlet weak var updateModelButton: UIBarButtonItem!
    
    
    // Update these with your own Visual Recognition and discovery credentials
    let visualRecognitionApiKey = ""
    let visualRecognitionClassifierID = ""
    let discoveryUsername = ""
    let discoveryPassword = ""
    let discoveryEnvironmentID = ""
    let discoveryCollectionID = ""
    let version = "2017-11-10"
    
    var visualRecognition: VisualRecognition!
    var discovery: Discovery!
    
    var classifications: [VisualRecognitionV3.ClassResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.visualRecognition = VisualRecognition(apiKey: visualRecognitionApiKey, version: version)
        self.discovery = Discovery(username: discoveryUsername, password: discoveryPassword, version: version)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Pull down model if none on device
        let localModels = try? visualRecognition.listLocalModels()
        if localModels == nil {
            self.invokeModelUpdate()
        } else {
            self.currentModelLabel.text = "Current Model: \(self.visualRecognitionClassifierID)"
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Model Methods
    
    func invokeModelUpdate()
    {
        let failure = { (error: Error) in
            print(error)
            let descriptError = error as NSError
            DispatchQueue.main.async {
                self.currentModelLabel.text = descriptError.code == 401 ? "Error updating model: Invalid Credentials" : "Error updating model"
                SwiftSpinner.hide()
            }
        }
        
        let success = {
            DispatchQueue.main.async {
                self.currentModelLabel.text = "Current Model: \(self.visualRecognitionClassifierID)"
                SwiftSpinner.hide()
            }
        }

        SwiftSpinner.show("Compiling model...")
        visualRecognition.updateLocalModel(classifierID: visualRecognitionClassifierID, failure: failure, success: success)
    }
    
    
    @IBAction func updateModel(_ sender: UIBarButtonItem) {
        self.invokeModelUpdate()
    }
    
    // MARK: - Pulley Library methods
    
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
                classification = prettifyLabel(label: self.classifications[0].className)
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
        
        let queryItem = query.components(separatedBy: " ")[0]
        let generalQuery = "text%3A%22" + queryItem + "%22"
        self.discovery.queryDocumentsInCollection(
            withEnvironmentID: discoveryEnvironmentID,
            withCollectionID: discoveryCollectionID,
            withQuery: generalQuery,
            failure: discoveryFail)
        {
            queryResponse in
            if let results = queryResponse.results {
                DispatchQueue.main.async {
                    var text = ""
                    var sectionTitle = ""
                    var subTitle = ""
                    if results.count > 0 {
                        text = results[0].text ?? "No Discovery results found."
                        sectionTitle = "Description"
                        subTitle = query
                    } else {
                        text = "No Discovery results found."
                    }
                    self.displayDiscoveryResults(data: text, title: sectionTitle, subTitle: subTitle)
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
            self.showAlert("Could not classify image", alertMessage: error.localizedDescription)
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
    
    //MARK: - Error Handling
    
    // Function to show an alert with an alertTitle String and alertMessage String
    func showAlert(_ alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func modelUpdateFail(error: Error) {
        let descriptError = error as NSError
        print(error)
        let errorCode = descriptError.code
        var errorMessage = ""
        if errorCode == 401 {
            errorMessage = "Invalid credentials. Please check your Visual Recognition credentials and try again."
        }
        switch errorCode {
        case 401:
            errorMessage = "Invalid credentials. Please check your Visual Recognition credentials and try again."
        case 500:
            errorMessage = "Internal server error. Please try again."
        default:
            errorMessage = "Please try again."
        }
        showAlert("Unable to download model", alertMessage: errorMessage)
    }
    
    func discoveryFail(error: Error) {
        let descriptError = error as NSError
        let errorCode = descriptError.code
        var errorMessage = ""
        switch errorCode {
        case 401:
            errorMessage = "Invalid credentials. Please check your Discovery credentials and try again."
        case 500:
            errorMessage = "A problem occured when querying Discovery. Please try again."
        default:
            errorMessage = "Unable to reach Watson Discovery"
        }
        
        DispatchQueue.main.async {
            self.displayDiscoveryResults(data: errorMessage)
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


