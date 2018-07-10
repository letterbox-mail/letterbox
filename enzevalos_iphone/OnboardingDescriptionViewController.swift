//
//  OnboardingDescriptionViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 27.06.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingDescriptionViewController: UIViewController {
    

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var iconHeight: NSLayoutConstraint!
    @IBOutlet weak var videoViewHeight: NSLayoutConstraint!
    @IBOutlet weak var underIconPadding: NSLayoutConstraint!
    @IBOutlet weak var underTitlePadding: NSLayoutConstraint!
    
    var viewModification: (() -> ())?
    var viewWillAppearBlock: (() -> ())?
    var viewWillDisappearBlock: (() -> ())?
    var layoutOptimization = true
    
    var videoPath: String?
    
    fileprivate var player: AVPlayer!
    fileprivate var avpController = AVPlayerViewController()
    
    var backgroundColor: UIColor? {
        get {
            return view.backgroundColor
        }
        set(newValue) {
            if let view = view {
                view.backgroundColor = newValue
                if let descriptionText = descriptionText {
                    descriptionText.backgroundColor = newValue
                }
                if let videoView = videoView {
                    videoView.backgroundColor = newValue
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let modification = viewModification {
            modification()
        }
        if layoutOptimization {
            optimizeLayout()
        }
        if let path = videoPath {
            let url = URL.init(fileURLWithPath: path)
            player = AVPlayer(url: url)
            //avpController = AVPlayerViewController()
            //avpController.player = player
            let playLayer = AVPlayerLayer(player: player)
            playLayer.frame = CGRect(x: 0, y: 0, width: 608*videoViewHeight.constant/1080, height: videoViewHeight.constant)
            playLayer.videoGravity = AVLayerVideoGravity.resize
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
                self.player?.seek(to: kCMTimeZero)
                self.player?.play()
            }
            videoView.layer.addSublayer(playLayer)
            player.play()
            
//            avpController.view.frame = videoView.frame
//            addChildViewController(avpController)
//            videoView.addSubview(avpController.view)
//            player.play()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let block = viewWillAppearBlock {
            block()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let block = viewWillDisappearBlock {
            block()
        }
    }
    
    func optimizeLayout() {
        let referenceSize: CGFloat = 812.0
        iconHeight.constant = view.frame.height*70/referenceSize
        underIconPadding.constant = view.frame.height*30/referenceSize
        underTitlePadding.constant = view.frame.height*25/referenceSize
        /*if icon.image == nil {
            iconHeight.constant = 0
        }*/
        titleLabel.font = UIFont(descriptor: titleLabel.font.fontDescriptor, size: view.frame.height*38/referenceSize)
        videoViewHeight.constant = view.frame.height*500/referenceSize
    }
}
