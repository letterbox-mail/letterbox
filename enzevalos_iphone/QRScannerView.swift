//
//  QRScannerView.swift
//  enzevalos_iphone
//
//  Created by Joscha on 01.08.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//
//  https://www.appcoda.com/barcode-reader-swift/

import AVFoundation
import AudioToolbox // necessary only to vibrate on versions before iOS 10

class QRScannerView: ViewControllerPannable, AVCaptureMetadataOutputObjectsDelegate {
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
    var callback: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        topLabel.text = NSLocalizedString("verifyContact", comment: "")
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

        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)

            // Initialize the captureSession object.
            captureSession = AVCaptureSession()

            // Set the input device on the capture session.
            captureSession?.addInput(input)

            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)

            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
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
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {

        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.path = nil
            bottomLabel.text = NSLocalizedString("scanQRCode", comment: "")
            return
        }

        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject, metadataObj.type == AVMetadataObjectTypeQRCode {

            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            if let barCodeObject = barCodeObject as? AVMetadataMachineReadableCodeObject {
                let barcodeOverlayPath = barcodeOverlayPathWithCorners(barCodeObject.corners as! [CFDictionary])
                qrCodeFrameView?.path = barcodeOverlayPath
            }

            if let string = metadataObj.stringValue {
                if let fingerprint = fingerprint, string.hasPrefix("OPENPGP4FPR:") || string.hasPrefix("openpgp4fpr:") {
                    let seperated = string.components(separatedBy: ":")
                    if seperated[1] == fingerprint {
                        qrCodeFrameColor = UIColor.green
                        captureSession?.stopRunning()
                        bottomLabel.text = NSLocalizedString("verifySuccess", comment: "Fingerprint was successfully verified")
                        if #available(iOS 10.0, *) {
                            let feedbackGenerator = UINotificationFeedbackGenerator()
                            feedbackGenerator.notificationOccurred(.success)
                        } else {
                            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                        }
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                            self.dismiss(animated: true, completion: self.callback)
                        }
                    } else {
                        qrCodeFrameColor = UIColor.red
                        bottomLabel.text = NSLocalizedString("fingerprintMissmatch", comment: "Found fingerprint does not match")
                        // TODO: Add a more explicit warning?
                    }
                } else {
                    qrCodeFrameColor = UIColor.orange
                    bottomLabel.text = NSLocalizedString("wrongQRCode", comment: "The found QR Code is not compatible")
                }
            }
        }
    }

    // from: https://developer.apple.com/library/content/samplecode/AVCamBarcode/Listings/AVCamBarcode_CameraViewController_swift.html#//apple_ref/doc/uid/TP40017312-AVCamBarcode_CameraViewController_swift-DontLinkElementID_4
    private func barcodeOverlayPathWithCorners(_ corners: [CFDictionary]) -> CGMutablePath {
        let path = CGMutablePath()

        if !corners.isEmpty {
            guard let corner = CGPoint(dictionaryRepresentation: corners[0]) else { return path }
            path.move(to: corner, transform: .identity)

            for cornerDictionary in corners {
                guard let corner = CGPoint(dictionaryRepresentation: cornerDictionary) else { return path }
                path.addLine(to: corner)
            }

            path.closeSubpath()
        }

        return path
    }
}
