//
//  ViewController.swift
//  WhatFlower
//
//  Created by Seth Mosgin on 7/25/18.
//  Copyright © 2018 Seth Mosgin. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var extractLabel: UILabel!
    
    
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php?"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Simulator has no camera =(
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            
            let alertController = UIAlertController.init(title: nil, message: "Device has no camera.", preferredStyle: .alert)
            
            let okAction = UIAlertAction.init(title: "Alright", style: .default, handler: {(alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
        else{
            //other action
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Could not convert to VNClassificationObservation")
            }
            
            // We have a classification for the flower
            if let firstResult = results.first {
                print(firstResult.identifier)
                self.navigationItem.title = firstResult.identifier.capitalized
                
                self.getWikiInfo(for: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func getWikiInfo(for flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName, //.replacingOccurrences(of: " ", with: "%20"),
            "indexpageids" : "",
            "redirects" : "1",
            ]
        
        var requestURL = wikipediaURL
        
        for param in parameters {
            requestURL += "\(param.key)=\(param.value)&"
        }
        
        print(requestURL)
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                let flowerJSON : JSON = JSON(response.result.value!)
                print(flowerJSON)
                let pageID = flowerJSON["query"]["pageids"][0]
                print("PageID: \(pageID)")
                print("Extract: \(flowerJSON["query"]["pages"]["\(pageID)"]["extract"])")
                self.extractLabel.text = flowerJSON["query"]["pages"]["\(pageID)"]["extract"].stringValue
            }
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }

    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

