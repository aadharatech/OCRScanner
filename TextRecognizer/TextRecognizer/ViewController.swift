//
//  ViewController.swift
//  TextRecognizer
//
//  Created by Aadhar Mathur on 8/12/19.
//  Copyright © 2019 Atechnos. All rights reserved.
//

import UIKit
import TesseractOCR
import AVFoundation

extension UIImage {
    func detectOrientationDegree () -> CGFloat {
        switch imageOrientation {
        case .right, .rightMirrored:    return 90
        case .left, .leftMirrored:      return -90
        case .up, .upMirrored:          return 180
        case .down, .downMirrored:      return 0
        }
    }
}

class ViewController: UIViewController, G8TesseractDelegate {
	
        // MARK: - Outlets
        @IBOutlet weak var cameraView: UIView!
       @IBOutlet var btnTap: UIButton!
    @IBOutlet weak var viewFinder: UIView!
    
    // MARK: - Private Properties
    fileprivate var stillImageOutput: AVCaptureStillImageOutput!
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let device  = AVCaptureDevice.default(for: AVMediaType.video)
    fileprivate var FirstVal : String = ""
    fileprivate var SecondVal : String = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
         self.view.addSubview(btnTap)
         self.view.bringSubviewToFront(btnTap)
       
         self.viewFinder.layer.borderWidth = 1.0
        self.viewFinder.layer.borderColor = UIColor.white.cgColor
         self.viewFinder.layer.cornerRadius = 20.0
         self.viewFinder.clipsToBounds = true
        
        self.btnTap.layer.borderWidth = 1.0
        self.btnTap.layer.borderColor = UIColor.white.cgColor
        
    
                 // start camera init
         DispatchQueue.global(qos: .userInitiated).async {
             if self.device != nil {
                 self.configureCameraForUse()
             }
         }
	}

	func recognizeImageWithTesserat(image: UIImage) {
		guard let tesseract  = G8Tesseract(language: "eng") else { return }
      
        tesseract.charWhitelist = "[A-Z0-9]{4}(-[A-Z0-9]{4}){3}"
        tesseract.charBlacklist = "\n"
        
        tesseract.engineMode = .lstmOnly
        tesseract.pageSegmentationMode = .sparseText
		tesseract.image = image
        tesseract.recognize()
        print(tesseract.recognizedText!)
        let recognizeVar = tesseract.recognizedText!
        if let match = recognizeVar.range(of: "[A-Z0-9]{4}(-[A-Z0-9]{4}){3}", options: .regularExpression) {
            ConstantVar.resultTxt = recognizeVar.substring(with: match)
            self.navigationController?.popViewController(animated: true)
        }else {
            ConstantVar.resultTxt = "No Alpha code found.....Scan Again"
            self.navigationController?.popViewController(animated: true)
        }
        
	}
	
	@IBAction func uploadImage(_ sender: Any) {
		//presentImagePicker()
        DispatchQueue.global(qos: .userInitiated).async {
            guard let capturedType = self.stillImageOutput.connection(with: AVMediaType.video) else {
                return
            }
            
            self.stillImageOutput.captureStillImageAsynchronously(from: capturedType) { [weak self] optionalBuffer, error -> Void in
                guard let buffer = optionalBuffer else {
                    return
                }
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let image = UIImage(data: imageData!)
                
                let croppedImage = self?.prepareImageForCrop(using: image!)
                self?.recognizeImageWithTesserat(image: croppedImage!)
            }
        }
	}
	
	
	
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController {
    // MARK: AVFoundation
    fileprivate func configureCameraForUse () {
        self.stillImageOutput = AVCaptureStillImageOutput()
        let fullResolution = UIDevice.current.userInterfaceIdiom == .phone && max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) < 568.0
        
        if fullResolution {
            self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        } else {
            self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        }
        
        self.captureSession.addOutput(self.stillImageOutput)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.prepareCaptureSession()
        }
    }
    
    private func prepareCaptureSession () {
        do {
            self.captureSession.addInput(try AVCaptureDeviceInput(device: self.device!))
        } catch {
            print("AVCaptureDeviceInput Error")
        }
        
        // layer customization
        DispatchQueue.main.async(execute: {
             let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
             previewLayer.frame.size = self.cameraView.frame.size
             previewLayer.frame.origin = CGPoint.zero
             previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
             
             // device lock is important to grab data correctly from image
             do {
                 try self.device?.lockForConfiguration()
                 self.device?.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                 self.device?.focusMode = .continuousAutoFocus
                 self.device?.unlockForConfiguration()
             } catch {
                 print("captureDevice?.lockForConfiguration() denied")
             }
             
             //Set initial Zoom scale
             do {
                 try self.device?.lockForConfiguration()
                 
                let zoomScale: CGFloat = 1.5
                 
                if zoomScale <= (self.device?.activeFormat.videoMaxZoomFactor)! {
                    self.device?.videoZoomFactor = zoomScale
                 }
                 
                self.device?.unlockForConfiguration()
             } catch {
                 print("captureDevice?.lockForConfiguration() denied")
             }
                 self.cameraView.layer.addSublayer(previewLayer)
                 self.captureSession.startRunning()
        })
    }
    
    // MARK: Image Processing
    fileprivate func prepareImageForCrop (using image: UIImage) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(Double.pi)
        }
        
        let imageOrientation = image.imageOrientation
        let degree = image.detectOrientationDegree()
        let cropSize = CGSize(width: 343, height: 121.5)
        print(viewFinder.bounds.width, viewFinder.bounds.height)
        
        //Downscale
        let cgImage = image.cgImage!
        //cropSize.width
        let width = cropSize.width
        let height = image.size.height / image.size.width * cropSize.width
        
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        let bitmapInfo = cgImage.bitmapInfo
        
        let context = CGContext(data: nil,
                                width: Int(width),
                                height: Int(height),
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace!,
                                bitmapInfo: bitmapInfo.rawValue)
        
        context!.interpolationQuality = CGInterpolationQuality.none
        // Rotate the image context
        context?.rotate(by: degreesToRadians(degree));
        // Now, draw the rotated/scaled image into the context
        context?.scaleBy(x: -1.0, y: -1.0)
        
        //Crop
        switch imageOrientation {
        case .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: -height, y: 0, width: height, height: width))
        case .left, .leftMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: -width, width: height, height: width))
        case .up, .upMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        case .down, .downMirrored:
            context?.draw(cgImage, in: CGRect(x: -width, y: -height, width: width, height: height))
        }
        
        let calculatedFrame = CGRect(x: 0, y: CGFloat((height - cropSize.height)/2.0), width: cropSize.width, height: cropSize.height)

        
        let scaledCGImage = context?.makeImage()?.cropping(to: calculatedFrame)
        
        return UIImage(cgImage: scaledCGImage!)
    }
    
}

// MARK: - UIImage extension
extension UIImage {
	func scaleImage(_ maxDimension: CGFloat) -> UIImage? {
		
		var scaledSize = CGSize(width: maxDimension, height: maxDimension)
		
		if size.width > size.height {
			let scaleFactor = size.height / size.width
			scaledSize.height = scaledSize.width * scaleFactor
		} else {
			let scaleFactor = size.width / size.height
			scaledSize.width = scaledSize.height * scaleFactor
		}
		
		UIGraphicsBeginImageContext(scaledSize)
		draw(in: CGRect(origin: .zero, size: scaledSize))
		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return scaledImage
	}
}

extension String {
    
    //[A-Z0-9]{4}(-[A-Z0-9]{4}){3}
    
    var containsSpecialCharacter: Bool {
       let regex = "[A-Z0-9]{4}(-[A-Z0-9]{4}){3}"
       let testString = NSPredicate(format:"SELF MATCHES %@", regex)
       return testString.evaluate(with: self)
    }
    
    func isAlphanumeric() -> Bool {
        return self.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil && self != ""
    }

    func isAlphanumeric(ignoreDiacritics: Bool = false) -> Bool {
        if ignoreDiacritics {
            return self.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && self != ""
        }
        else {
            return self.isAlphanumeric()
        }
    }
}
