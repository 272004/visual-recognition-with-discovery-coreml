# Visual Recognition and Discovery with Core ML starter kit

Classify images with [Watson Visual Recognition][vizreq] and [Core ML][core_ml], and then query [Watson Discovery][discovery] with the classification results. The images are classified offline using a deep neural network that is trained by Visual Recognition, and the results are sent to the Discovery service.

## Before you begin
- Consider downloading and configuring the [Visual Recognition with Core ML starter kit][vizreq_with_coreml] before using this starter. If you already completed that starter, skip the next sections and go to [Importing the frameworks from the SDK](#importing-the-frameworks-from-the-sdk)
- Make sure that you have installed [Xcode 9][xcode_download] or later and iOS 11.0 or later. These versions are required to support Core ML.

## Getting the files
Use GitHub to clone the repository locally, or download the .zip file of the repository and extract the files.

## Creating your Visual Recognition service
If you have an existing instance of the Visual Recognition service, you can use it. Otherwise, follow these steps to create an instance:

1.  <a href="https://console.bluemix.net/registration/trial/?target=%2Fdeveloper%2Fwatson%2Fcreate-project%3Fservices%3Dwatson_vision_combined%26action%3Dcreate%26hideTours%3Dtrue" target="_blank">Create an instance</a> of the Visual Recognition service. From that link you can create or log into an IBM Cloud account.
1.  In the project details page, click **Show** to reveal the API key, and then copy and save the `api_key` value.

**Tip:** To return to the project details page, go to **[Projects](https://console.bluemix.net/developer/watson/projects)** page and select the instance of Visual Recognition that you created.

## Training a Visual Recognition model
Use the [Visual Recognition Tool][vizreq_tooling] to upload images and train a custom model (also called a classifier). The .zip files contain sample images of HDMI and USB connectors.

1.  From the project details page in the earlier step, click **Launch tool** and enter the `api_key` that you copied earlier.
1.  Select **Create classifier** and name the classifier `Connectors`.
1.  Upload each .zip file of sample images from the `Training Images` directory onto a class.
1.  Enter `HDMI` as the class name for the `hdmi_male.zip` file and `USB` for the `usb_male.zip` file and click **Create**.
1.  After the classifier is created, copy and save the classifier ID. The classifier ID looks similar to `Connectors_424118776`.

## Installing the Watson Swift SDK
The Watson Swift SDK makes it easy to keep track of your custom Core ML models and to download your custom classifiers from IBM Cloud to your device.

Use the Carthage dependency manager to download and build the Watson Swift SDK.

1.  Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
1.  Open a terminal window and navigate to the `Core ML Vision Discovery` directory.
1.  Run the following command to download and build the Watson Swift SDK:

    ```bash
    carthage bootstrap --platform iOS
    ```

### Importing the frameworks from the SDK
Start here if you already downloaded and configured the [Visual Recognition with Core ML starter kit][vizreq_with_coreml].

1.  In the Watson Swift SDK, navigate to the Visual Recognition and Discovery frameworks in the `Carthage/Build/iOS` directory.
1.  Drag `VisualRecognitionV3.framework` and `DiscoveryV1.framework` into XCode in your `projects` directory.
1.  In Xcode, use the **Project Navigator** to select the `Core ML Vision Discovery.xcodeproj` project.
1.  In the General settings tab, scroll down to **Embedded Binaries** and click the `+` icon.
1.  Click **Add Other**, navigate to the `Carthage/Build/iOS` directory, and select **VisualRecognitionV3.framework**.
1.  Repeat to add **DiscoveryV1.framework**.

## Setting up Discovery
Next, you integrate Watson Discovery.

### Creating your Discovery service
If you have an existing instance of the Discovery service, you can use it. Otherwise, follow these steps to create an instance:

1. In the same Watson console where you created the Visual Recognition service, <a target="_blank" href="https://console.bluemix.net/developer/watson/create-project?services=discovery&action=create">create an instance</a> of the Discovery service.
1.  In the project details page, click **Show** to reveal the credentials.
1.  Copy and save the `username` and `password` values. You'll use them next in the Discovery Tool.

### Configuring your Discovery service
To set up Discovery, upload the sample documents that have information about the cables. The app queries your documents in the Discovery service and returns relevant information about the cable.

1.  From the project details page in the earlier step, click **Launch tool**.
1.  Create a data collection and name it `Connectors`. Accept the default configuration and click **Create**.
1.  Upload the HTML documents from the [Data/Discovery](../master/Data/Discovery) directory.
1.  Under Collection info, click **Use this collection in API**. Copy and save the `Collection Id` and  `Environment Id` values.

## Configuring the app

1.  In Xcode, open the [ImageClassificationViewController.swift](../master/Core%20ML%20Vision%20Discovery/ImageClassificationViewController.swift) file.
1.  Paste the values that you saved earlier into properties near the top of the file and save it:
    - Visual Recognition API key > **apiKey**.
    - Visual Recognition Classifier ID > **classifierID**.
    - Discovery credentials > **discoveryUsername** and **discoveryPassword**.
    - Collection info > **discoveryEnvironmentID** and **discoveryCollectionID**.

## Running the app
The app uses the Visual Recognition service and Core ML model on your device to classify the image. Then the app sends the classification to Watson Discovery service and displays more information about the cable.

When you run the app, the SDK makes sure that the version of the Visual Recognition model on your device is in sync with the latest version on IBM Cloud. If the local version is older, the SDK downloads the model to your device. With a local model, you can classify images offline. You need to be connected to the internet to communicate with the Discovery service.

1.  In Xcode, sSelect the `Core ML Vision Discovery` scheme.
1.  Run the app in the simulator or on a device.
1.  Classify an image by clicking the camera icon and selecting a photo from your photo library or by taking a picture of a USB or HDMI connector. To add your own images in the simulator, drag the image from Finder to the simulator window.

    If you're online, the application queries the Discovery service and displays information about the classification results in the bottom panel.

## What to do next

Try using your own data: Train a Visual Recognition classifier with your own images and add your own documents to Discovery. For details on those services, see the links in the Resources section.

## Resources

- [Visual Recognition docs](https://console.bluemix.net/docs/services/visual-recognition/getting-started.html) and [Discovery docs](https://console.bluemix.net/docs/services/discovery/getting-started-tool.html)
- [Watson Swift SDK](https://github.com/watson-developer-cloud/swift-sdk)
- [Apple machine learning][core_ml] and [Core ML documentation](https://developer.apple.com/documentation/coreml)
- [Watson console](https://bluemix.net/developer/watson) on IBM Cloud

[vizreq]: https://www.ibm.com/watson/services/visual-recognition/
[discovery]: https://www.ibm.com/watson/services/discovery/
[core_ml]: https://developer.apple.com/machine-learning/
[vizreq_with_coreml]: https://github.com/watson-developer-cloud/visual-recognition-coreml/
[vizreq_tooling]: https://watson-visual-recognition.ng.bluemix.net/
[xcode_download]: https://developer.apple.com/xcode/downloads/