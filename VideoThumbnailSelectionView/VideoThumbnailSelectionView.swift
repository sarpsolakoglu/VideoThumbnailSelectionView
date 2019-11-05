//
//  VideoThumbnailSelectionView.swift
//  VideoThumbnailSelectionView
//
//  Created by Sarp Solakoğlu on 30/05/16.
//  Copyright © 2016 Sarp Solakoğlu. All rights reserved.
//

import UIKit
import AVFoundation

@objc public class VideoThumbnailSelectionView: UIView {
    
    //MARK: - Private params
    
    @IBOutlet private var view: UIView!
    @IBOutlet weak private var thumbnailView: UIView!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak private var shadeView: UIView!
    @IBOutlet weak private var leftMargin: NSLayoutConstraint!
    @IBOutlet weak private var topMargin: NSLayoutConstraint!
    @IBOutlet weak private var rightMargin: NSLayoutConstraint!
    @IBOutlet weak private var bottomMargin: NSLayoutConstraint!
    
    private var selectionThumb: SelectionThumb?
    private var scrollOptions: ScrollOptions?
    private var thumbnails: [UIImageView] = []
    private var videoLoaded = false
    private var videoLoading = false
    private var shouldUpdateFrame = true
    private var generator: AVAssetImageGenerator?
    private var asset: AVAsset? {
        didSet {
            if asset != nil {
                generator = AVAssetImageGenerator(asset: asset!)
                generator!.requestedTimeToleranceBefore = CMTime.zero
                generator!.requestedTimeToleranceAfter = CMTime.zero
            } else {
                generator = nil
            }
        }
    }
    
    //MARK: - Public params & Customization
    
    /**
     View calls this block when selection changes. Should be set before loading video.
     */
    public var onUpdatedImage: (UIImage)->() = { _ in }
  
    
    /**
     The opacity of the black shade color on the thumbnails. Defaults to 0.5.
     */
    public var shadeTintAlpha: CGFloat = 0.5 {
        didSet {
            shadeView.alpha = shadeTintAlpha
        }
    }
    
    /**
     The zoom level when the thumbnail is selected. 1.0 can be given for no animation. Defaults to 1.5.
     */
    public var zoomAnimationScale: CGFloat = 1.5
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            view.layer.cornerRadius = cornerRadius
            thumbnailView.layer.cornerRadius = cornerRadius - 2
            shadeView.layer.cornerRadius = cornerRadius - 2
        }
    }
    
    /**
     The color of the corner of the view.
     */
    public var cornerColor: UIColor = .white {
        didSet {
            view.backgroundColor = cornerColor
        }
    }
    
    /**
     The corner thickness.
     */
    public var cornerInsets: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0) {
        didSet {
            topMargin.constant = cornerInsets.top
            leftMargin.constant = cornerInsets.left
            bottomMargin.constant = cornerInsets.bottom
            rightMargin.constant = cornerInsets.right
            layoutIfNeeded()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup(frame: nil)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup(frame: frame)
    }
    
    /**
     Returns the snapshot of the video at that second. "loadVideo" should have been called before.
     
     - parameters:
        - forSecond: The snapshot time in seconds.
        - completion: UIImage is returned in this block if succesful.
        - failure: This block is called in case of failure.
     */
    @objc public func snapshot(forSecond second: Float64, completion: @escaping (UIImage)->(), failure:(()->())?) {
        guard let generator = generator else {
            failure?()
            return
        }
        
        DispatchQueue.global().async {
           if let image = self.generateThumbnail(generator: generator, second: second) {
            DispatchQueue.main.async {
                    completion(image)
                }
                return
            } else {
                failure?()
                return
            }
        }
    }
    
    //MARK: - Video
    
    /**
     Loads the video and generates the thumbnails on the view. This should be called first.
     
     - parameters:
        - asset: AVAsset that should be loaded.
     */
    @objc public func loadVideo(asset: AVAsset) {
        
        if videoLoaded { return }
        if videoLoading { return }
        
        guard let assetVideoTrack : AVAssetTrack = asset.tracks(withMediaType: AVMediaType.video)[0] else { return }
        
        self.asset = asset
        
        activityIndicator.startAnimating()
        DispatchQueue.main.async {
            let size = assetVideoTrack.naturalSize
            let thumbnailHeight = self.thumbnailView.bounds.size.height
            let videoAspect = size.width / size.height
            let thumbnailWidth = thumbnailHeight * videoAspect
            
            let generator = AVAssetImageGenerator(asset: asset)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            let thumbnailCount = Int(ceil(self.thumbnailView.bounds.size.width / thumbnailWidth))
            let videoDuration = CMTimeGetSeconds(asset.duration)
            let sampleInterval = videoDuration / Float64(thumbnailCount)
            
            self.selectionThumb = SelectionThumb(frame: CGRect(x: self.thumbnailView.frame.origin.x, y: self.thumbnailView.frame.origin.y, width: thumbnailWidth, height: thumbnailHeight))
            
            self.scrollOptions = ScrollOptions(startPoint: self.leftMargin.constant + thumbnailWidth / 2, endPoint: self.view.bounds.size.width - thumbnailWidth / 2 - self.rightMargin.constant)
            
            var currentTime: Float64 = 0.0
            var currentX: CGFloat = 0.0
            for i in (0..<thumbnailCount) {
                if sampleInterval > videoDuration { break }
                let image = self.generateThumbnail(generator: generator, second: currentTime)
                if i == 0 {
                    self.selectionThumb!.previewImageView.image = image
                    self.view.addSubview(self.selectionThumb!)
                }
                let imageView = UIImageView(frame: CGRect(x: currentX, y: 0.0, width: thumbnailWidth, height: thumbnailHeight))
                imageView.contentMode = .scaleAspectFill
                imageView.image = image
                self.thumbnailView.addSubview(imageView)
                self.thumbnails.append(imageView)
                currentX += thumbnailWidth
                currentTime += sampleInterval
            }
            self.activityIndicator.stopAnimating()
            self.videoLoaded = true
            self.videoLoading = false
            self.didScrollToPercent(percent: 0, override: true)
            
        }
    }
    
    /**
     Deletes the video and returns the view to blank state. "loadVideo" should be called if view is going to be used again.
     */
    @objc public func deleteVideo() {
        if !videoLoaded { return }
        if videoLoading { return }
        
        for imageView in thumbnails {
            imageView.removeFromSuperview()
        }
        
        thumbnails.removeAll()
        
        selectionThumb!.removeFromSuperview()
        selectionThumb = nil
        scrollOptions = nil
        
        shouldUpdateFrame = true
        videoLoaded = false
        self.asset = nil
    }
    
    private func didScrollToPercent(percent: CGFloat, override: Bool) {
        
        if !shouldUpdateFrame && !override { return }
        
        guard let asset = asset else { return }
        
        shouldUpdateFrame = false
        let videoDuration = CMTimeGetSeconds(asset.duration)
        snapshot(forSecond: videoDuration * Float64(percent), completion: {[weak self] image in
            self?.selectionThumb?.previewImageView.image = image
            self?.onUpdatedImage(image)
            self?.shouldUpdateFrame = true
            }, failure: {[weak self] in
                self?.shouldUpdateFrame = true
            })
    }
    
    func generateThumbnail(generator: AVAssetImageGenerator, second: Float64) -> UIImage? {
        let time = CMTimeMake(value: Int64(second * 60), timescale: 60)
        do {
            let imgRef = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imgRef)
        } catch {
            return nil
        }
    }
    
    //MARK: - Private lounctions
    private func setup(frame: CGRect?) {
        loadNib()
        if frame != nil {
            view.frame = CGRect(x: 0, y: 0, width: frame!.width, height: frame!.height)
        }
        addSubview(view)
        pinView()
        thumbnailView.layer.masksToBounds = true
    }
    
    private func loadNib() {
        Bundle(for: VideoThumbnailSelectionView.self).loadNibNamed("VideoThumbnailSelectionView", owner: self, options: nil)
    }
    
    private func pinView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self , attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    //MARK: - Touches
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollOptions == nil { return }
        guard let selectionThumb = selectionThumb else { return }
        if let touch = touches.first {
            let loc = touch.location(in: thumbnailView)
            if selectionThumb.frame.contains(loc) {
                scrollOptions!.thumbStartLocation = selectionThumb.center.x
                scrollOptions!.scrollStartLocation = loc.x
                scrollOptions!.currentlyScrolling = true
                
                if zoomAnimationScale > 1.0 {
                    selectionThumb.layer.removeAllAnimations()
                    UIView.animate(withDuration: 0.2, animations: {
                        selectionThumb.layer.transform = CATransform3DScale(CATransform3DIdentity, self.zoomAnimationScale, self.zoomAnimationScale, 1.0)
                    })
                }
            }
        }

    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollOptions == nil { return }
        if !(scrollOptions!.currentlyScrolling) { return }
        guard let selectionThumb = selectionThumb else { return }
        if let touch = touches.first {
            let loc = touch.location(in: thumbnailView)
            let newX = scrollOptions!.getNewLocationAccordingToPoint(x: loc.x)
            selectionThumb.center.x = newX
            //call view
            didScrollToPercent(percent: scrollOptions!.scrollPercent, override: false)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollOptions == nil { return }
        if !(scrollOptions!.currentlyScrolling) { return }
        guard let selectionThumb = selectionThumb else { return }
        didScrollToPercent(percent: scrollOptions!.scrollPercent, override: true)
        if zoomAnimationScale > 1.0 {
            selectionThumb.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2, animations: {
                selectionThumb.layer.transform = CATransform3DIdentity
            })
        }
        scrollOptions!.reset()
    }
    
}
