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



class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var twisterSwitch: UISwitch!
    @IBOutlet weak var flashSwitch: UISwitch!
    @IBOutlet weak var convolutSwitch: UISwitch!

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
        
        
        self.slider.layer.cornerRadius = 15
        self.slider.layer.masksToBounds = true
        self.twisterSwitch.layer.cornerRadius = 15
        self.twisterSwitch.layer.masksToBounds = true
        self.convolutSwitch.layer.cornerRadius = 15
        self.convolutSwitch.layer.masksToBounds = true
        self.flashSwitch.layer.cornerRadius = 15
        self.flashSwitch.layer.masksToBounds = true
        
        
        self.videoButton.layer.borderColor = UIColor.systemYellow.cgColor
        self.videoButton.layer.borderWidth = 2.0
        self.videoButton.layer.cornerRadius = 14
        
        
        self.photoButton.layer.borderColor = UIColor.systemYellow.cgColor
        self.photoButton.layer.borderWidth = 2.0
        self.photoButton.layer.cornerRadius = 14
//        self.photoButton.layer.masksToBounds = true
        
        filters = [RCam06(),RCam01(),RCam02(), RCam03(), RCam04(), RCam05()]
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
    

    
    
    @IBAction func didToggleConvolut(_ sender: Any) {
        
           camera.stopCapture()
           camera.removeAllTargets()
           filters[selectedIndex].removeAllTargets()
           self.haze.removeAllTargets()
           self.convolut.removeAllTargets()
        updateActiveFilter(selected: filters[selectedIndex])
    }
    @IBAction func didToggleFlash(_ sender: Any) {
        
           camera.stopCapture()
           camera.removeAllTargets()
           filters[selectedIndex].removeAllTargets()
           self.haze.removeAllTargets()
            self.twister.removeAllTargets()
           self.convolut.removeAllTargets()
        updateActiveFilter(selected: filters[selectedIndex])
        
    }
    
    @IBAction func didToggleTwister(_ sender: Any) {
           camera.stopCapture()
           camera.removeAllTargets()
           filters[selectedIndex].removeAllTargets()
           self.haze.removeAllTargets()
           self.twister.removeAllTargets()
           self.convolut.removeAllTargets()
        updateActiveFilter(selected: filters[selectedIndex])
    }

    func updateActiveFilter(selected: RCamFilter) {
       
        if (loadedImageSource == nil) {
            

                 do {
                    camera = try Camera(sessionPreset: .high)
                     camera.runBenchmark = true

                     camera.startCapture()
                 } catch {
                     fatalError("Could not initialize rendering pipeline: \(error)")
                 }
                 guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
                 guard device.hasTorch else { print("Torch isn't available"); return }

                 do {
                     try device.lockForConfiguration()
                     if (flashSwitch.isOn) {
                         device.torchMode = .on
                     } else {
                         device.torchMode = .off
                     }

                     device.unlockForConfiguration()
                 } catch {
                     print("Torch can't be used")
                 }
                 camera.addTarget(selected)
    


                 
                 if (twisterSwitch.isOn) {
                     selected.addTarget(self.twister)
                     
                     if (convolutSwitch.isOn) {
                         
                         self.twister.addTarget(self.convolut)
                         self.convolut.addTarget(renderView)
                         
                     } else {
                         
                         if (selected.name == "rcam01" || selected.name == "rcam02" || selected.name == "rcam03") {
                             
                               self.twister.addTarget(self.haze)
                             self.haze.addTarget(renderView)
                             
                         } else {
                             self.twister.addTarget(renderView)
                         }
                         
                     }
                     
                     
                 } else {
                     
                     
                     if (convolutSwitch.isOn) {
                         if (selected.name == "rcam01" || selected.name == "rcam02" || selected.name == "rcam03") {
                             
                             selected.addTarget(self.convolut)
                             self.convolut.addTarget(haze)
                             self.haze.addTarget(renderView)
                             
                         } else {
                             selected.addTarget(self.convolut)
                             self.convolut.addTarget(renderView)
                         }

                         
                     } else {
                         
                         if (selected.name == "rcam01" || selected.name == "rcam02" || selected.name == "rcam03") {
                             selected.addTarget(self.haze)
                             self.haze.addTarget(renderView)
                         } else {
                              selected.addTarget(renderView)
                         }
                         
                     }
                     
                    
                 }

            
            
        } else {
            
            loadedImageSource.addTarget(selected)
            
            
            if (twisterSwitch.isOn) {
                selected.addTarget(self.twister)
                
                if (convolutSwitch.isOn) {
                    
                    self.twister.addTarget(self.convolut)
                    self.convolut.addTarget(renderView)
                    
                } else {
                    
                    if (selected.name == "rcam01" || selected.name == "rcam02" || selected.name == "rcam03") {
                        
                          self.twister.addTarget(self.haze)
                        self.haze.addTarget(renderView)
                        
                    } else {
                        self.twister.addTarget(renderView)
                    }
                    
                }
                
                
            } else {
                
                
                if (convolutSwitch.isOn) {
                    if (selected.name == "rcam01" || selected.name == "rcam02" || selected.name == "rcam03") {
                        
                        selected.addTarget(self.convolut)
                        self.convolut.addTarget(haze)
                        self.haze.addTarget(renderView)
                        
                    } else {
                        selected.addTarget(self.convolut)
                        self.convolut.addTarget(renderView)
                    }

                    
                } else {
                    
                    if (selected.name == "rcam01" || selected.name == "rcam02" || selected.name == "rcam03") {
                        selected.addTarget(self.haze)
                        self.haze.addTarget(renderView)
                    } else {
                         selected.addTarget(renderView)
                    }
                    
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
        
        if (twisterSwitch.isOn) {
            
            if (convolutSwitch.isOn) {

                    filters[selectedIndex] --> self.twister --> self.convolut --> pictureOutput
                
            } else {
                filters[selectedIndex] -->  self.haze -->  twister --> pictureOutput
            }
            
            
        } else {
            
            
            
            if (convolutSwitch.isOn) {
                
                
                    filters[selectedIndex] --> self.convolut -->  pictureOutput
                
                
            } else {
                filters[selectedIndex] --> self.haze --> pictureOutput
                
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
                            
                            
                            
                            
                            
                            
                            if (twisterSwitch.isOn) {
                                
                                if (convolutSwitch.isOn) {

                                        filters[selectedIndex] --> self.twister --> self.convolut --> movieOutput!
                                    
                                } else {
                                    filters[selectedIndex] --> self.twister --> movieOutput!
                                }
                                
                                
                            } else {
                                
                                
                                
                                if (convolutSwitch.isOn) {
                                    
                                    
                                        filters[selectedIndex] --> self.convolut -->  movieOutput!
                                    
                                    
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
    
    
//        @IBAction func pauseCapture(_ sender: AnyObject) {
//            if (isRecording) {
//                movieOutput?.finishRecording{
//                    self.isRecording = false
//                    DispatchQueue.main.async {
//                        (sender as! UIButton).tintColor = UIColor.systemYellow
//                    }
//    //                self.camera.audioEncodingTarget = nil
//                    self.movieOutput = nil
//                }
//            }
//        }



    
}

