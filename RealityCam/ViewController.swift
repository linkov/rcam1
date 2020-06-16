//
//  ViewController.swift
//  RealityCam
//
//  Created by Alex Linkov on 6/3/20.
//  Copyright © 2020 SDWR. All rights reserved.
//

import UIKit
import GPUImage
import AudioKit
import JGProgressHUD

protocol FilterSelectionDelegate {
    func didSelectFilter1(_ filter: FilterOperationInterface)
    func didSelectFilter2(_ filter: FilterOperationInterface)
}

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate & FilterSelectionDelegate {
    
    @IBOutlet weak var videoButton: UIButton!

    @IBOutlet weak var fx1Slider: UISlider!
    @IBOutlet weak var fx2Sldier: UISlider!
    
    @IBOutlet weak var fiButton: UIButton!
    @IBOutlet weak var f2Button: UIButton!
    
    var F1: FilterOperationInterface?
    var F2: FilterOperationInterface?
    
    var FX1isOn = false;
    var FX2isOn = false;
    
    var mic: AKMicrophone!
    var tracker: AKAmplitudeTracker!
    var silence: AKBooster!
    var micBooster: AKBooster!

    var loadedImageSource: PictureInput!
    
    var isRecording = false
    
    var movieOutput: MovieOutput!
    
    var twister = SwirlDistortion()
    var haze = Haze()
    var convolut = Convolution3x3()
    
    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]


    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var renderView: RenderView!
    var camera:Camera!
//    var filter: RCamFilter!
    var filters = [RCamFilter]()
    
    var selectedIndex = 0
    
    
    var pictureOutput = PictureOutput()
    
    @IBOutlet weak var photoButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
//        let hud = JGProgressHUD(style: .dark)
//        hud.textLabel.text = "Swipe left to change filter, swipe top to change current filter variation"
//        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
//        hud.show(in: self.view)
//        hud.dismiss(afterDelay: 4.0)
        
        
//        self.slider.layer.cornerRadius = 15
//        self.slider.layer.masksToBounds = true
        
        
        self.fiButton.layer.cornerRadius = 15
        self.fiButton.layer.masksToBounds = true
        
        self.f2Button.layer.cornerRadius = 15
        self.f2Button.layer.masksToBounds = true
        
        self.videoButton.layer.borderColor = UIColor.systemYellow.cgColor
        self.videoButton.layer.borderWidth = 2.0
        self.videoButton.layer.cornerRadius = 14
        
        
        
        self.photoButton.layer.borderColor = UIColor.systemYellow.cgColor
        self.photoButton.layer.borderWidth = 2.0
        self.photoButton.layer.cornerRadius = 14
//        self.photoButton.layer.masksToBounds = true
        
        filters = [RCam05(), RCam06(),RCam01(),RCam02(), RCam03(), RCam04()]
        convolut.convolutionKernel = Matrix3x3(rowMajorValues:[
        3.0, -2.0, -8.0,
        -2.0, 2.1, 0.0,
        0.0, 3.0, -1.0])
        
        
//        twister.radius = 0.2
//        twister.angle = 0.4
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(moveToNextItem(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(moveToNextItem(_:)))

        leftSwipe.direction = .left
        rightSwipe.direction = .right

        renderView.addGestureRecognizer(leftSwipe)
        renderView.addGestureRecognizer(rightSwipe)
        
        
        
        let topSwipe = UISwipeGestureRecognizer(target: self, action: #selector(moveToNextVariation(_:)))
        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(moveToNextVariation(_:)))

        topSwipe.direction = .up
        bottomSwipe.direction = .down

        renderView.addGestureRecognizer(topSwipe)
        renderView.addGestureRecognizer(bottomSwipe)
        
        
        
        updateActiveFilter(selected: filters[selectedIndex])
       
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        micBooster = AKBooster(mic, gain: 5)
        tracker = AKAmplitudeTracker(micBooster)
  
        
        silence = AKBooster(tracker, gain: 0)
        
        
    }
    

    
    
    @IBAction func didToggleFX() {


        updateActiveFilter(selected: filters[selectedIndex])
    }
//    @IBAction func didToggleFlash(_ sender: Any) {
//
//           camera.stopCapture()
//           camera.removeAllTargets()
//           filters[selectedIndex].removeAllTargets()
//            self.haze.removeAllTargets()
//           self.F1?.filter.removeAllTargets()
//           self.F2?.filter.removeAllTargets()
//        updateActiveFilter(selected: filters[selectedIndex])
//
//    }
//
//    @IBAction func didToggleTwister(_ sender: Any) {
//
//
//
//           camera.stopCapture()
//           camera.removeAllTargets()
//           filters[selectedIndex].removeAllTargets()
//            self.haze.removeAllTargets()
//           self.F1?.filter.removeAllTargets()
//           self.F2?.filter.removeAllTargets()
//        updateActiveFilter(selected: filters[selectedIndex])
//    }

    func updateActiveFilter(selected: RCamFilter) {
       
        
        selected.time = 0.0
        
        
        if (loadedImageSource == nil) {
            

                 do {
                    camera = try Camera(sessionPreset: .high)
                     camera.runBenchmark = true

                     camera.startCapture()
                 } catch {
                     fatalError("Could not initialize rendering pipeline: \(error)")
                 }

                 camera.addTarget(selected)
    


                 
                 if (FX1isOn) {
                     selected.addTarget(self.F1!.filter)
                     
                     if (FX2isOn) {
                         
                         self.F1?.filter.addTarget(self.F2!.filter)
                         self.F2?.filter.addTarget(renderView)
                         
                     } else {
                         

                             self.F1?.filter.addTarget(renderView)
         
                         
                     }
                     
                     
                 } else {
                     
                     
                     if (FX2isOn) {

                             selected.addTarget(self.F2!.filter)
                             self.F2!.filter.addTarget(renderView)
       

                         
                     } else {
                         

                              selected.addTarget(renderView)
        
                         
                     }
                     
                    
                 }

            
            
        } else {
            
            loadedImageSource.addTarget(selected)
            
            
            if (FX1isOn) {
                selected.addTarget(self.F1!.filter)
                
                if (FX2isOn) {
                    
                    self.F1!.filter.addTarget(self.F2!.filter)
                    self.F2!.filter.addTarget(renderView)
                    
                } else {
                    

                        self.F1!.filter.addTarget(renderView)
            
                    
                }
                
                
            } else {
                
                
                if (FX2isOn) {

                        selected.addTarget(self.F2!.filter)
                        self.F2!.filter.addTarget(renderView)
       
                    
                } else {
                    
                         selected.addTarget(renderView)

            
                }
                
               
            }
            

            loadedImageSource.processImage()
        }

        
      
        
        //camera --> filter --> renderView
       
    }
    func selectPrevVariation() {
        
        let currentFilter = filters[selectedIndex]
        if (currentFilter.filterVariation != 1) {
            currentFilter.filterVariation -= 1
        }
        
    }
    
    func selectNexVariation() {
        
        let currentFilter = filters[selectedIndex]
        if (currentFilter.filterVariation < 6) {
            currentFilter.filterVariation += 1
        }

    }
    
    func resetFilterVariation() {
        let currentFilter = filters[selectedIndex]
        currentFilter.filterVariation = 1
    }
    
    func selectPrevFilter() {
        
        if (selectedIndex - 1 < 0) {
            return
        }
        
        camera.stopCapture()
        camera.removeAllTargets()
        filters[selectedIndex].removeAllTargets()
        self.haze.removeAllTargets()
        self.twister.removeAllTargets()
        self.convolut.removeAllTargets()
        
        selectedIndex -= 1
        

        let filter = filters[selectedIndex]
        updateActiveFilter(selected: filter)
    }
    
    func selectNextFilter() {
        
        if (selectedIndex + 1 > filters.count - 1) {
            return
        }
        
        
	        camera.stopCapture()
        camera.removeAllTargets()
        filters[selectedIndex].removeAllTargets()
        self.haze.removeAllTargets()
        self.convolut.removeAllTargets()
        selectedIndex += 1
        

        
        let filter = filters[selectedIndex]
        updateActiveFilter(selected: filter)
    }
    
    @objc func moveToNextItem(_ sender:UISwipeGestureRecognizer) {

       switch sender.direction{
        case .left: self.selectNextFilter()
        case .right:  self.selectPrevFilter()
        default:
        return
        }

    }
    
    @objc func moveToNextVariation(_ sender:UISwipeGestureRecognizer) {

       switch sender.direction{
       case .up: self.selectPrevVariation()
        case .down:  self.selectNexVariation()
        default:
        return
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AudioKit.output = silence
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }

        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)
    }
    
    @objc func updateUI() {
       if tracker.amplitude > 0.001 {
        //let trackerFrequency = Float(tracker.frequency )
           

//            guard trackerFrequency < 7_000 else {
//                // This is a bit of hack because of modern Macbooks giving super high frequencies
//                return
//            }
////
//            var frequency = trackerFrequency
//                   while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
//                       frequency /= 2.0
//                   }
//                   while frequency < Float(noteFrequencies[0]) {
//                       frequency *= 2.0
//                   }
//
//                   var minDistance: Float = 10_000.0
//                   var index = 0
//
//                   for i in 0..<noteFrequencies.count {
//                       let distance = fabsf(Float(noteFrequencies[i]) - frequency)
//                       if distance < minDistance {
//                           index = i
//                           minDistance = distance
//                       }
//                   }
//                   let octave = Int(log2f(trackerFrequency / frequency))
//
//        let trackerFrequency = Float(tracker.frequency)
//        var frequency = trackerFrequency
//                   while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
//                       frequency /= 2.0
//                   }
//                   while frequency < Float(noteFrequencies[0]) {
//                       frequency *= 2.0
//                   }
//
//        print(frequency)
        filters[selectedIndex].audioLevel = Float(tracker.amplitude * 2.0 )

       } else {
        filters[selectedIndex].audioLevel = Float(0.0)
        }
        
        if (loadedImageSource != nil) {
            loadedImageSource.processImage()
        }
    }
    
    @IBAction func fx1SldierValueDidChange(_ sender: Any) {
        
    
    }
    
    @IBAction func fx2SliderValueDidChange(_ sender: Any) {
        
        
    }
    
    
    @IBAction func mainSliderValueChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        filters[selectedIndex].filterIntensity = slider.value
        if (loadedImageSource != nil) {
            loadedImageSource.processImage()
        }
    }
    
    
    // Image save
    @IBAction func photoSaveDidTap(_ sender: Any) {
        
        self.photoButton.isEnabled = false
        pictureOutput.encodedImageFormat = .png
        pictureOutput.imageAvailableCallback = {image in
            self.saveImage(image: image)
            
        }
        
        
//        let filter1: BasicOperation = self.F1?.filter ?? nil
//        let filter2: BasicOperation = self.F2?.filter ?? nil
        
        if (FX1isOn) {
            
            if (FX2isOn) {

                filters[selectedIndex] -->  (self.F1!.filter as! BasicOperation) --> (self.F2!.filter as! BasicOperation) --> pictureOutput
                
            } else {
                filters[selectedIndex] -->  (self.F1!.filter as! BasicOperation) --> pictureOutput
            }
            
            
        } else {
            
            
            
            if (FX2isOn) {
                
                
                filters[selectedIndex] --> (self.F2!.filter as! BasicOperation) -->  pictureOutput
                
                
            } else {
                filters[selectedIndex] -->  pictureOutput
                
            }
            
             
        }
       
        
    }
    
    func saveImage(image: UIImage)  {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            self.loadedImageSource = nil
            self.photoButton.isEnabled = true
            let hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Image saved"
            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 2.0)
        }
    }
    
    @IBAction func startVideoCapture(_ sender: Any) {
                    if (!isRecording) {
                        do {
                            self.isRecording = true
                            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                            let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
                            do {
                                try FileManager.default.removeItem(at:fileURL)
                            } catch {
                            }

                            movieOutput = try MovieOutput(URL:fileURL, size:Size(width:Float(camera.inputCamera.activeFormat.formatDescription.dimensions.width), height:Float(camera.inputCamera.activeFormat.formatDescription.dimensions.height)), liveVideo:true)
            //                camera.audioEncodingTarget = movieOutput
                            
                            
                            
                            
                            
        //                    filters[selectedIndex] --> movieOutput!
        //
                            
                            
                            
                            
                            
                            
                            if (FX1isOn) {
                                
                                if (FX2isOn) {

                                        filters[selectedIndex] --> (self.F1!.filter as! BasicOperation)  --> (self.F2!.filter as! BasicOperation) --> movieOutput!
                                    
                                } else {
                                    filters[selectedIndex] --> (self.F1!.filter as! BasicOperation)  --> movieOutput!
                                }
                                
                                
                            } else {
                                
                                
                                
                                if (FX2isOn) {
                                    
                                    
                                        filters[selectedIndex] --> (self.F2!.filter as! BasicOperation)  -->  movieOutput!
                                    
                                    
                                } else {
                                        filters[selectedIndex] --> movieOutput!
                                    
                                }
                                
                                 
                            }
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            movieOutput!.startRecording()
                            DispatchQueue.main.async {
                                // Label not updating on the main thread, for some reason, so dispatching slightly after this
                                (sender as! UIButton).tintColor = UIColor.white
                                (sender as! UIButton).backgroundColor = UIColor.red
                                
                                (sender as! UIButton).layer.borderColor = UIColor.red.cgColor
                                (sender as! UIButton).layer.borderWidth = 10.0
                                
                                UIView.animate(withDuration: 0.150, animations: {
                                    self.videoButton.transform = CGAffineTransform.init(scaleX: 2, y: 2)



                                })

                            }
                        } catch {
                            fatalError("Couldn't initialize movie, error: \(error)")
                        }
                    }
        
    }
    
    @IBAction func stopCapture(_ sender: Any) {
        
                if (isRecording) {
                    movieOutput?.finishRecording{
                        self.isRecording = false
                        DispatchQueue.main.async {
                            (sender as! UIButton).tintColor = UIColor.systemYellow
                            (sender as! UIButton).backgroundColor = UIColor.lightText
                            
                            (sender as! UIButton).layer.borderColor = UIColor.systemYellow.cgColor
                            (sender as! UIButton).layer.borderWidth = 2.0
                            
                            
                            let hud = JGProgressHUD(style: .dark)
                            hud.textLabel.text = "Video saved"
                            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                            hud.show(in: self.view)
                            hud.dismiss(afterDelay: 2.0)
                            
                            UIView.animate(withDuration: 0.150, animations: {
                                    self.videoButton.transform = CGAffineTransform.init(scaleX: 1, y: 1)


                            })

                        }
        //                self.camera.audioEncodingTarget = nil
                        self.movieOutput = nil
                    }
                }
    }
    
    @IBAction func didTapF1(_ sender: Any) {
   
        
        let filterSelectionVC = FilterListViewController.init()
        filterSelectionVC.isFirstFilter = true;
        filterSelectionVC.selectionDelegate = self
        self.present(filterSelectionVC, animated: true) {
            
        }
        
    }
    
    
    @IBAction func didTapF2(_ sender: Any) {
    

        let filterSelectionVC = FilterListViewController.init()
        filterSelectionVC.isFirstFilter = false;
        filterSelectionVC.selectionDelegate = self
        self.present(filterSelectionVC, animated: true) {
            
        }
        
        
    }
    
    
    func didSelectFilter1(_ filter: FilterOperationInterface) {
        
        camera.stopCapture()
        camera.removeAllTargets()
        filters[selectedIndex].removeAllTargets()
         self.haze.removeAllTargets()
        self.F1?.filter.removeAllTargets()
        self.F2?.filter.removeAllTargets()
        
        
        if (filter.titleName == "None") {
            fiButton.titleLabel?.text = "Select FX1"
            FX1isOn = false
            didToggleFX()
            return
        }
        
        if (filter.titleName == "3x3")  {
            switch filter.filterOperationType {
                           case .singleInput:
                return
                           case .blend:
                return
                           case let .custom(filterSetupFunction:setupFunction):
                            filter.configureCustomFilter(setupFunction(camera,filter.filter,renderView))
                           }
        }
        
        FX1isOn = true
        F1 = filter
        fiButton.titleLabel?.text = filter.titleName
        
        didToggleFX()
        
        
    }
    func didSelectFilter2(_ filter: FilterOperationInterface) {
        
        
           camera.stopCapture()
           camera.removeAllTargets()
           filters[selectedIndex].removeAllTargets()
            self.haze.removeAllTargets()
           self.F1?.filter.removeAllTargets()
           self.F2?.filter.removeAllTargets()
        
        if (filter.titleName == "None") {
            f2Button.titleLabel?.text = "Select FX2"
            FX2isOn = false
            didToggleFX()
            return
        }
        
        if (filter.titleName == "3x3")  {
            switch filter.filterOperationType {
                           case .singleInput:
                return
                           case .blend:
                return
                           case let .custom(filterSetupFunction:setupFunction):
                            filter.configureCustomFilter(setupFunction(camera,filter.filter,renderView))
                           }
        }
        

        
        FX2isOn = true
        F2 = filter
        f2Button.titleLabel?.text = filter.titleName
        didToggleFX()
    }

    
}

@IBDesignable open class DesignableSlider: UISlider {

    @IBInspectable var trackHeight: CGFloat = 5

    @IBInspectable var roundImage: UIImage? {
        didSet{
            setThumbImage(roundImage, for: .normal)
        }
    }
    @IBInspectable var roundHighlightedImage: UIImage? {
        didSet{
            setThumbImage(roundHighlightedImage, for: .highlighted)
        }
    }
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        //set your bounds here
        return CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: trackHeight))
    }
}
