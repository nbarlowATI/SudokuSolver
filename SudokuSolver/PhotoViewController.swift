//
//  PhotoViewController.swift
//  sudokuPrep5
//
//  Created by Nicholas Barlow on 04/02/2016.
//  Copyright © 2016 Nicholas Barlow. All rights reserved.
//

import UIKit

import AVFoundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



//-------------------------------------------------------------------------------------------------------
func delay(_ delay: Double, block:@escaping ()->()) {
    let nSecDispatchTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC);
    let queue = DispatchQueue.main
    
    queue.asyncAfter(deadline: nSecDispatchTime, execute: block)
}

func loadShutterSoundPlayer() -> AVAudioPlayer? {
    let theMainBundle = Bundle.main
    let filename = "Shutter sound"
    let fileType = "mp3"
    let soundfilePath: String? = theMainBundle.path(forResource: filename,
        ofType: fileType,
        inDirectory: nil)
    if soundfilePath == nil
    {
        return nil
    }
    //println("soundfilePath = \(soundfilePath)")
    let fileURL = URL(fileURLWithPath: soundfilePath!)
    var error: NSError?
    let result: AVAudioPlayer?
    do {
        result = try AVAudioPlayer(contentsOf: fileURL)
    } catch var error1 as NSError {
        error = error1
        result = nil
    }
    if let requiredErr = error
    {
        print("AVAudioPlayer.init failed with error \(requiredErr.debugDescription)")
    }
    if let settings = result?.settings
    {
        //println("soundplayer.settings = \(settings)")
    }
    result?.prepareToPlay()
    return result
}

////////////////////////////////////////////////////////////////////////////


class PhotoViewController: UIViewController,
    CroppableImageViewDelegateProtocol,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate {

    
    
    @IBOutlet weak var whiteView: UIView!
    
    @IBOutlet weak var cropView: CroppableImageView!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var splitImageView: UIView!
    @IBOutlet var splitImages: [UIImageView] = []
    var imagesToOCR: [UIImage] = []
    var mySudokuImage: UIImage = UIImage()
    var recognizedNumbers: [Int] = []

    
    
    var shutterSoundPlayer = loadShutterSoundPlayer()
    

    
    override func viewDidLoad() {
        print("In PhotoViewController viewDidLoad")

        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.whiteView.isHidden = true
        print("Finishing PhotoViewController viewDidLoad")

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getListOfNumbers() -> [Int] {
        if self.recognizedNumbers.count == 0 {
            for i in 0...80 {
                self.recognizedNumbers += [0]
            }
        }
        return self.recognizedNumbers
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    enum ImageSource: Int
    {
        case camera = 1
        case photoLibrary
    }
    
    func pickImageFromSource(
        _ theImageSource: ImageSource,
        fromButton: UIButton)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        switch theImageSource
        {
        case .camera:
            print("User chose take new pic button")
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            /////imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Front;
        case .photoLibrary:
            print("User chose select pic button")
            imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            if theImageSource == ImageSource.camera {
                self.present(
                    imagePicker,
                    animated: true)
                    {
                        //println("In image picker completion block")
                }
            } else {
                self.present(
                    imagePicker,
                    animated: true)
                    {
                        
                }
            }
        }
        else
        {
            self.present(
                imagePicker,
                animated: true)
                {
                    print("In image picker completion block")
            }
            
        }
    }
    
    func returnRecognizedNumbers() -> [Int] {
        return self.recognizedNumbers
    }
    

    @IBAction func handleCropButton(_ sender: AnyObject) {
        if let croppedImage = cropView.croppedImage() {
            self.whiteView.isHidden = false
            delay(0) {
                self.shutterSoundPlayer?.play()
                /////     UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
                
                delay(0.2) {
                    self.whiteView.isHidden = true
                    self.shutterSoundPlayer?.prepareToPlay()
                    self.shutterSoundPlayer?.play()
                }
            }
            self.mySudokuImage = croppedImage
            divideImageAndDoOCR(croppedImage)
        }
    }

    func scaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func divideImageAndDoOCR(_ image: UIImage) {
        ///// Divide the image up into 81:
        self.recognizedNumbers = []
        print("In divideImage")
        let tmpImage = image.cgImage
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let smallImageWidth = imageWidth/9.0
        let smallImageHeight = imageHeight/9.0
        self.splitImageView.isHidden = false
        print("imageHeight is \(imageHeight), width is \(imageWidth)")
        var count = 0
        for j in 0...8 {
            for i in 0...8 {
                let startX : CGFloat = CGFloat(i)*smallImageWidth+(smallImageWidth/7.0)
                let startY : CGFloat = CGFloat(j)*smallImageHeight+(smallImageHeight/6.6)
                
                let smallImage = tmpImage?.cropping(to: CGRect(x: startX,y: startY,width: CGFloat(0.72)*smallImageWidth, height: CGFloat(0.79)*smallImageHeight))
                self.imagesToOCR += [UIImage(cgImage: smallImage!)]
                self.splitImages[count].image = self.imagesToOCR[count]
                let imageForTesseract = scaleImage(UIImage(cgImage: smallImage!).g8_blackAndWhite(), maxDimension:200)
                //smallImageWidth*0.85,smallImageHeight*0.85)
        //        let imageForTesseract = scaleImage(UIImage(CGImage: smallImage!).g8_blackAndWhite(), maxDimension:200)
                
         
                print("Performing image recognition on image \(j*9+i)")
                print("Performing image recognition on image \(j*9+i)")
                let thisText = self.performImageRecognition(imageForTesseract)
                print(" ==> It's a \(thisText) length of string \(thisText.characters.count)")
                var foundNum: Bool = false
                for thisChar in thisText.characters {
                    if Int(String(thisChar)) > 0 && Int(String(thisChar)) < 10 {
                        print("setting square\(j*9+i) to \(thisChar)")
                        let thisNum: Int = Int(String(thisChar))!
                        print("List of recognized numbers now has length \(self.recognizedNumbers.count)")
                        self.recognizedNumbers += [thisNum]
                        foundNum = true
                    }
                }
                if (foundNum == false) {
                    self.recognizedNumbers += [0]
                }
                print("List of recognized numbers NOW has length \(self.recognizedNumbers.count)")
             //   let thisText = self.performImageRecognition(imageForTesseract)
               // print(" ==> It's a \(thisText) length of string \(thisText.characters.count)")
               // for thisChar in thisText.characters {
                 //   if Int(String(thisChar)) > 0 && Int(String(thisChar)) < 10 {
                   //     print("setting square\(j*9+i) to \(thisChar)")
                     //   self.mySquares[j*9+i].text = String(thisChar)
                //    }
                //}
                count += 1
            }
        }
        print("length of imagesToOCR and splitImages arrays \(self.imagesToOCR.count) \(self.splitImages.count)")
    }

    
    func performImageRecognition(_ image: UIImage) -> String {
        // 1
        let tesseract = G8Tesseract()
        
        // 2
        tesseract.language = "eng"
        tesseract.setVariableValue("123456789",forKey: "tessedit_char_whitelist")
        // 3
        tesseract.engineMode = .tesseractOnly
        // 4
        tesseract.pageSegmentationMode = .singleChar
        
        // 5
        tesseract.maximumRecognitionTime = 60.0
        
        // 6
        tesseract.image = image
        
        return tesseract.recognizedText
    }

    
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        let deviceHasCamera: Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        
        //Create an alert controller that asks the user what type of image to choose.
        let anActionSheet = UIAlertController(title: "Pick Image Source",
            message: nil,
            preferredStyle: UIAlertControllerStyle.actionSheet)
        
        
        
        //If the current device has a camera, add a "Take a New Picture" button
        var takePicAction: UIAlertAction? = nil
        if deviceHasCamera
        {
            takePicAction = UIAlertAction(
                title: "Snap that Sudoku",
                style: UIAlertActionStyle.default,
                handler:
                {
                    (alert: UIAlertAction)  in
                    self.pickImageFromSource(
                        ImageSource.camera,
                        fromButton: sender as! UIButton)
                }
            )
        }
        
        //Allow the user to select an amage from their photo library
        let selectPicAction = UIAlertAction(
            title:"Select Picture from library",
            style: UIAlertActionStyle.default,
            handler:
            {
                (alert: UIAlertAction)  in
                self.pickImageFromSource(
                    ImageSource.photoLibrary,
                    fromButton: sender as! UIButton)
            }
        )
        
        let cancelAction = UIAlertAction(
            title:"Cancel",
            style: UIAlertActionStyle.cancel,
            handler:
            {
                (alert: UIAlertAction)  in
                print("User chose cancel button")
            }
        )
        
        if let requiredtakePicAction = takePicAction
        {
            anActionSheet.addAction(requiredtakePicAction)
        }
        anActionSheet.addAction(selectPicAction)
        anActionSheet.addAction(cancelAction)
        
        let popover = anActionSheet.popoverPresentationController
        popover?.sourceView = sender as! UIView
        popover?.sourceRect = sender.bounds;
        
        self.present(anActionSheet, animated: true)
            {
                //println("In action sheet completion block")
        }
        
        
        
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : Any])
    {
        print("In \(#function)")
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            picker.dismiss(animated: true, completion: nil)
            cropView.imageToCrop = image
            print("setting image as cropView.imageToCrop")
        }
        //cropView.setNeedsLayout()
    }
    
    
    
    func haveValidCropRect(_ haveValidCropRect:Bool) {
        //println("In haveValidCropRect. Value = \(haveValidCropRect)")
        cropButton.isEnabled = haveValidCropRect
    }
    

    

}
