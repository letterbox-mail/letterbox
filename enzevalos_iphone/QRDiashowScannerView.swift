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
    
    
    var callback: (() -> ())?
    var seenCodes: [String?]?
    var maxCodes = 0
    var foundCodes = 0
    
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
        
        //TODO: LOG!
        //Logger.log(verify: self.keyId ?? "noKeyID", open: false, success: false)
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
                        if maxCodes != scannedCount {
                            seenCodes = nil
                        }
                        if seenCodes == nil {
                            maxCodes = scannedCount
                            foundCodes = 0
                            seenCodes = [String?] (repeatElement(nil, count: maxCodes))
                        }
                        let payload = string.suffix(string.count - seperated[0].count - 1) // consider ;
                        if seenCodes![index] == nil {
                            foundCodes = foundCodes + 1
                        }
                        seenCodes![index] = String(payload)
                        qrCodeFrameColor = UIColor.green
                        bottomLabel.text = "\(seenCodes?.count ?? 0) "+NSLocalizedString("of", comment: "")+" \(maxCodes) "+NSLocalizedString("scanned", comment: "")
                        if foundCodes == maxCodes {
                            //self.dismiss(animated: false, completion: nil)
                            let data = parseCodes()
                            handleData(user: data.user, name: data.name, mailaddr: data.mailaddr, pw: data.pw, imapServer: data.imapServer, imapPort: data.imapPort, imapAuth: data.imapAuth, imapTransport: data.imapTransport, smtpServer: data.smtpServer, smtpPort: data.smtpPort, smtpAuth: data.smtpAuth, smtpTransport: data.smtpTransport, keys: data.keys)
                            let validationController = self.storyboard?.instantiateViewController(withIdentifier: "validateSetup") as! OnboardingValidateSetupPageViewController
                            self.present(validationController, animated: false, completion: nil)
                        }
                        return
                    }
                }
                qrCodeFrameColor = UIColor.orange
                bottomLabel.text = NSLocalizedString("wrongQRCode", comment: "The found QR Code is not compatible")
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
    
    private func prepareCode() -> String{
        guard seenCodes != nil else {
            return ""
        }
        var message = ""
        
        for code in seenCodes! {
            if let payload = code {
                message = message + payload
            }
        }
        return message
        
    }
    
    
    private func parseCodes() -> (user: String?, name: String?, mailaddr: String?, pw: String?, imapServer: String?, imapPort: Int?, imapAuth: Int?, imapTransport: Int?, smtpServer: String?, smtpPort: Int?, smtpAuth: Int?, smtpTransport: Int?, keys: [String]){
        /* TODO: Testcases:
         password with ;, : and ;+:
         multiple keys
         no key
         no account data
         */

        guard seenCodes != nil else {
            return (user: nil, name: nil, mailaddr: nil, pw: nil, imapServer: nil, imapPort: nil, imapAuth: nil, imapTransport: nil, smtpServer: nil, smtpPort:nil, smtpAuth: nil, smtpTransport: nil, keys: [String] ())
        }
        // Extract PW with length
        // Tokenize message again.
        let msg = prepareCode()
        // Assumption: SeenCodes is sorted.
        var user: String?
        var name: String?
        var mailaddr: String?
        var passwordLength = -1
        var password: String?
        var imapServer: String?
        var imapPort: Int?
        var imapAuth: Int?
        var imapTransportType: Int?
        var smtpServer: String?
        var smtpPort: Int?
        var smtpAuth: Int?
        var smtpTransportType: Int?
        
        var keys = [String]()
        var leftTokens = ""
        
        let tokens = msg.split(separator: ";")
        for token in tokens {
            let pair = token.split(separator: ":", maxSplits: 1)
            if (pair.count >= 2) {
                let type = String(pair[0])
                let value = String(pair[1])
                switch type {
                case "U":
                    user = value
                case "N":
                    name = value
                case "EMAIL":
                    mailaddr = value
                case "PLENGTH":
                    if let pwl = Int(value) {
                        passwordLength = pwl
                    }
                    else {
                       passwordLength = 0
                    }
                case "PW":
                    password = value
                case "IMAPSERVER":
                    imapServer = value
                case "IMAPPORT":
                    if let port = Int(value) {
                        imapPort = port
                    }
                case "IMAPAUTH":
                    if let auth = Int(value) {
                        imapAuth = auth
                    }
                case "IMAPTRANS":
                    if let type = Int(value) {
                        imapTransportType = type
                    }
                case "SMTPSERVER":
                    smtpServer = value
                case "SMTPPORT":
                    if let port = Int(value) {
                        smtpPort = port
                    }
                case "SMTPAUTH":
                    if let type = Int(value) {
                        smtpAuth = type
                    }
                case "SMTPTRANS":
                    if let type = Int(value) {
                        smtpTransportType = type
                    }
                case "KEY", "key":
                    keys.append(value)
                default:
                    leftTokens = leftTokens + ";" + type + ":" + value
                }
            }
            else {
                leftTokens = leftTokens + ";" + String(token)
            }
        }
        if let pw = password, pw.count < passwordLength {
            password = pw + leftTokens
        }
        
        return (user: user, name: name, mailaddr: mailaddr, pw: password, imapServer: imapServer, imapPort: imapPort, imapAuth: imapAuth, imapTransport: imapTransportType, smtpServer: smtpServer, smtpPort: smtpPort, smtpAuth: smtpAuth, smtpTransport: smtpTransportType, keys: keys)
    }
    
    private func handleData (user: String?, name: String?, mailaddr: String?, pw: String?, imapServer: String?, imapPort: Int?, imapAuth: Int?, imapTransport: Int?, smtpServer: String?, smtpPort: Int?, smtpAuth: Int?, smtpTransport: Int?, keys: [String]){
        if let server = imapServer {
           // UserManager.storeServerConfig(type: .IMAP, server: server, port: UInt32(imapPort), authType: imapAuth, connectionType: imapTransport)
        }
        
        if let server = smtpServer {
           // UserManager.storeServerConfig(type: .SMTP, server: server, port: UInt32(smtpPort), authType: smtpAuth, connectionType: smtpTransport)
        }
        
        if let adr = mailaddr {
            UserManager.storeUserValue(adr as AnyObject, attribute: .userAddr)
        }
        if let pw = pw {
            UserManager.storeUserValue(pw as AnyObject, attribute: .userPW)
        }
        
        if let name = name {
            UserManager.storeUserValue(name as AnyObject, attribute: Attribute.userName)
        }
        else if let adr = mailaddr {
            UserManager.storeUserValue(adr as AnyObject as AnyObject, attribute: Attribute.userName)
        }
        else if let user = user {
            UserManager.storeUserValue(user as AnyObject, attribute: Attribute.userName)
        }
        
        
        if let user = user {
            UserManager.storeUserValue(user as AnyObject, attribute: Attribute.accountname)
        }
        else if let adr = mailaddr {
            UserManager.storeUserValue(adr as AnyObject, attribute: Attribute.accountname)
            
        }
        else if let name = name {
            UserManager.storeUserValue(name as AnyObject, attribute: Attribute.accountname)
            
        }
        let pgp = SwiftPGP()
        var keyIds = [String] ()
        for key in keys {
            do {
                let ids = try pgp.importKeys(key: key, pw: nil, isSecretKey: true, autocrypt: false)
                keyIds.append(contentsOf: ids)
                print(ids)
            } catch{
                print(error)
            }
        }
        for id in keyIds {
            _ = DataHandler.handler.newSecretKey(keyID: id)
        }
    }
}
