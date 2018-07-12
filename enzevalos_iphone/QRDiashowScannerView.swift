//
//  QRScannerView.swift
//  enzevalos_iphone
//
//  Created by Jakob on 21.06.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//
//  https://www.appcoda.com/barcode-reader-swift/

import AVFoundation
import AudioToolbox // necessary only to vibrate on versions before iOS 10

class QRDiashowScannerView: ViewControllerPannable, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: CAShapeLayer?
    var qrCodeFrameColor: UIColor? {
        set {
            if let frame = qrCodeFrameView {
                frame.strokeColor = newValue?.cgColor
                frame.fillColor = newValue?.withAlphaComponent(0.4).cgColor
            }
        }
        get { return nil }
    }
    
    var fingerprint: String?
    var keyId: String? //used for logging
    var callback: (() -> ())?
    var seenCodes: [Int: [String]]?
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topLabel.text = NSLocalizedString("importSettings", comment: "")
        bottomLabel.text = NSLocalizedString("scanQRCode", comment: "")
        
        let topBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        let bottomBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        topBlurView.frame = topBar.bounds
        bottomBlurView.frame = bottomBar.bounds
        topBlurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bottomBlurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        topBar.addSubview(topBlurView)
        topBar.sendSubview(toBack: topBlurView)
        bottomBar.addSubview(bottomBlurView)
        bottomBar.sendSubview(toBack: bottomBlurView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.topBar.translatesAutoresizingMaskIntoConstraints = true
            self.bottomBar.translatesAutoresizingMaskIntoConstraints = true
            self.bottomLabel.translatesAutoresizingMaskIntoConstraints = true
            self.topLabel.translatesAutoresizingMaskIntoConstraints = true
        }
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            if let device = captureDevice {
                // Get an instance of the AVCaptureDeviceInput class using the previous device object.
                let input = try AVCaptureDeviceInput(device: device)
                
                // Initialize the captureSession object.
                captureSession = AVCaptureSession()
                
                // Set the input device on the capture session.
                captureSession?.addInput(input)
                
                // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession?.addOutput(captureMetadataOutput)
                
                // Set delegate and use the default dispatch queue to execute the call back
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                
                // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                
                // Initialize QR Code Frame to highlight the QR code
                qrCodeFrameView = CAShapeLayer()
                
                if let qrCodeFrameView = qrCodeFrameView {
                    qrCodeFrameColor = UIColor.orange
                    qrCodeFrameView.lineWidth = 2
                    qrCodeFrameView.lineJoin = kCALineJoinMiter
                    view.layer.addSublayer(qrCodeFrameView)
                }
                
                view.bringSubview(toFront: topBar)
                view.bringSubview(toFront: bottomBar)
                
                // Start video capture.
                captureSession?.startRunning()
            }
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppUtility.lockOrientation(.allButUpsideDown)
    }
    
    @IBAction func close(_ sender: Any) {
        //        Logger.queue.async(flags: .barrier) {
        Logger.log(verify: self.keyId ?? "noKeyID", open: false, success: false)
        //        }
        dismiss(animated: true, completion: nil)
    }
    
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.path = nil
            bottomLabel.text = NSLocalizedString("scanQRCode", comment: "")
            return
        }
        
        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject, metadataObj.type == AVMetadataObject.ObjectType.qr {
            
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            if let barCodeObject = barCodeObject as? AVMetadataMachineReadableCodeObject {
                let barcodeOverlayPath = barcodeOverlayPathWithCorners(barCodeObject.corners /*as! [CFDictionary]*/)
                qrCodeFrameView?.path = barcodeOverlayPath
            }
            
            if let string = metadataObj.stringValue {
                let seperated = string.components(separatedBy: ";")
                if seperated.count > 1 {
                    let header = seperated[0].components(separatedBy: ",")
                    if header.count == 2, let index = Int(header[0]), let scannedCount = Int(header[1]) {
                        if count != scannedCount {
                            seenCodes = nil
                        }
                        if seenCodes == nil {
                            seenCodes = [:]
                            count = scannedCount
                        }
                        seenCodes![index] = seperated
                        qrCodeFrameColor = UIColor.green
                        bottomLabel.text = "\(seenCodes?.count ?? 0) "+NSLocalizedString("of", comment: "")+" \(count) "+NSLocalizedString("scanned", comment: "")
                        if seenCodes?.count == count {
                            self.dismiss(animated: false, completion: nil)
                        }
                        return
                    }
                }
                qrCodeFrameColor = UIColor.orange
                bottomLabel.text = NSLocalizedString("wrongQRCode", comment: "The found QR Code is not compatible")
                
//                if let fingerprint = fingerprint, seperated[0].caseInsensitiveCompare("OPENPGP4FPR") == ComparisonResult.orderedSame {
//                    if seperated[1].caseInsensitiveCompare(fingerprint) == ComparisonResult.orderedSame {
//                        qrCodeFrameColor = UIColor.green
//                        captureSession?.stopRunning()
//                        bottomLabel.text = NSLocalizedString("verifySuccess", comment: "Fingerprint was successfully verified")
//                        if #available(iOS 10.0, *) {
//                            let feedbackGenerator = UINotificationFeedbackGenerator()
//                            feedbackGenerator.notificationOccurred(.success)
//                        } else {
//                            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
//                            self.dismiss(animated: true, completion: self.callback)
//                        }
//                    } else {
//                        qrCodeFrameColor = UIColor.red
//                        bottomLabel.text = NSLocalizedString("fingerprintMissmatch", comment: "Found fingerprint does not match")
//                        captureSession?.stopRunning()
//                        if #available(iOS 10.0, *) {
//                            let feedbackGenerator = UINotificationFeedbackGenerator()
//                            feedbackGenerator.notificationOccurred(.error)
//                        } else {
//                            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
//                            let alert = UIAlertController(title: NSLocalizedString("fingerprintMissmatchShort", comment: "Found fingerprint does not match"), message: NSLocalizedString("fingerprintMissmatchText", comment: "Found fingerprint does not match"), preferredStyle: .alert)
//                            alert.addAction(UIAlertAction(title: NSLocalizedString("MoreInformation", comment: "More Information"), style: .default, handler: {
//                                (action: UIAlertAction!) -> Void in
//                                UIApplication.shared.openURL(URL(string: "https://userpage.fu-berlin.de/letterbox/faq.html#headingWrongFingerprint")!)
//                                self.dismiss(animated: false, completion: nil)
//                            }))
//                            alert.addAction(UIAlertAction(title: NSLocalizedString("scanDifferentCode", comment: ""), style: .default, handler: {
//                                (action: UIAlertAction!) -> Void in
//                                self.qrCodeFrameView?.path = nil
//                                self.captureSession?.startRunning()
//                            }))
//                            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (action: UIAlertAction!) -> Void in self.dismiss(animated: true, completion: nil) }))
//                            self.present(alert, animated: true, completion: nil)
//                        }
//                    }
//                } else {
//                    qrCodeFrameColor = UIColor.orange
//                    bottomLabel.text = NSLocalizedString("wrongQRCode", comment: "The found QR Code is not compatible")
//                }
            }
        }
    }
    
    // from: https://developer.apple.com/library/content/samplecode/AVCamBarcode/Listings/AVCamBarcode_CameraViewController_swift.html#//apple_ref/doc/uid/TP40017312-AVCamBarcode_CameraViewController_swift-DontLinkElementID_4
    private func barcodeOverlayPathWithCorners(_ corners: [CGPoint]) -> CGMutablePath {
        let path = CGMutablePath()
        
        if !corners.isEmpty {
            let corner = corners[0]
            //guard let corner = CGPoint(dictionaryRepresentation: corners[0]) else { return path }
            path.move(to: corner, transform: .identity)
            
            for corner in corners {
                path.addLine(to: corner)
            }
            
            /*for cornerDictionary in corners {
                guard let corner = CGPoint(dictionaryRepresentation: cornerDictionary) else { return path }
                path.addLine(to: corner)
            }*/
            
            path.closeSubpath()
        }
        
        return path
    }
}
