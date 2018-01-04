# Core ML Vision Discovery Starter Kit
## Getting Started


1. You will need Carthage to download the Watson SDK framework, if you do not already have Carthage installed you can follow instructions [here](https://github.com/Carthage/Carthage#installing-carthage)

2. Once Carthage is set up, you can download the latest SDK by opening your terminal, navigating to your project directory and running the following command
```
carthage update --platform iOS
```
3. After the package is done installing, you will find the Visual Recognition and Discovery frameworks in the Carthage/Build/iOS directory. From this folder, drag `VisualRecognitionV3.framework` and `DiscoveryV1.framework` into XCode in your projects directory. The Watson Visual Recognition SDK makes it easy to keep track of your custom Core ML models and pull down new versions of custom classifiers from the IBM Cloud and store them on your device.

4. In the Embedded Binaries section of your project, add the two frameworks that you just dragged in.

## Setting up Visual Recognition

4. Next you will need to go to bluemix and provision a free instance of Visual recognition. Click [this](https://console.bluemix.net/registration/trial/?target=%2Fdeveloper%2Fwatson%2Fcreate-project%3Fservices%3Dwatson_vision_combined%26action%3Dcreate%26hideTours%3Dtrue) link to do so. You will need to create a bluemix account if you do not already have one.

5. On this page you can copy your `api_key` from the listed credentials and paste it at the top of the `ImageClassificationViewController.swift` file in your project, where it says `apiKey = ""`. Next we will begin training our custom model. You are welcome to use any training images of your choosing, or to make things easier, we have included some sample training images in this github repo.

6. On the page where you got your credentials, open the Visual Recogniton tooling by clicking the launch tool button.

7. Open the Visual Recognition tool and select ‘Create new classifier’

8. Call the classifier ‘Connectors’ and then take the images in the folder ‘Training Images’ and upload the zip folders to the tool. In each folder is 10 images of the corresponding connector. For instance, the usb_male folder contains training images of a USB cable

9. After uploading the images, you will see a new classifier available in your workspace. Copy the classifier ID paste it into the top of the ImageClassificationViewController.swift file in your project, where it says classifierID = “”

10. When the app is running, the SDK will look for new versions of the classifier and pull them from the cloud and store them to the device. Once a model is on the device it can do classifications without being connected to the internet.

## Setting up Discovery

11. Next step is to store documents into Discovery. We will upload several documents with information on the cables that we trained the custom VR model on. That way, whenever a cable is classified, the app will send a query to discovery saying ‘What is ____?’ and Discovery will send back the relevant document

12. In the IBM Cloud console, open the Discovery tool. Once in the tool, create a new collection and call it ‘Connectors’

13. Before uploading any documents, we need to upload a config file to Discovery that defines the way our documents will be parsed. The documents that we chose for this exercise came from a tech terms webiste in the form of HTML documents. We spent some time cleaning the documents and creating a config file that handles storing the files in the optimal way to Discovery. You can learn more about how this works here: (insert link). The config file is available in the data/Discovery directory of this project. You can upload it with the following command, replacing username, password, and environment id with your own:

```
curl -X POST -u "{username}":"{password}" -H "Content-Type: application/json" -d @Data/connector-config.json "https://gateway.watsonplatform.net/discovery/api/v1/environments/{environment_id}/configurations?version=2017-11-07"
```

Username and password can be found in the 'Service credentials' tab of the Discovery service on the IBM Cloud site. The environment_id can be found in the Discovery tooling, open your new collection, under 'Collection info,' click on 'Use this collection in API'

14. Now, in the Discovery tooling, you can switch your config from the default config to the 'Connectors Config' that you just uploaded.

15. Next you can upload the documents by clicking 'browse from computer' and selecting all of the documents in the data/Discovery directory.

16. Now all is needed is to copy the discovery credentials into the `ImageClassificationViewController.swift` file of our application, at the top of the file where there are a list of variables like `discoveryUsername = ""`. The Discovery username and password are located in the 'Service credentials' section of your Discovery service on IBM Cloud. The environment ID and collection ID are located in the Discovery tooling, in the 'Collection info' section of your collection. You can see them by clicking 'Use this collection in API'

## Running the app

17. The app is all ready now! Go ahead and run on your simulator or download onto your phone and run from there. When you take a picture (or choose from camera roll) of a usb connector or hdmi connector, the Visual recognition model will classify the image using the a Core ML model on the device. No internet or cell connection is needed. Once an image is classified, the application will send a query to Watson Discovery to retireve more information on the cable!
