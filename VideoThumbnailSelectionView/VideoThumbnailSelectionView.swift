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
                generator!.requestedTimeToleranceBefore = kCMTimeZero
                generator!.requestedTimeToleranceAfter = kCMTimeZero
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
    public var cornerColor: UIColor = .whiteColor() {
        didSet {
            view.backgroundColor = cornerColor
        }
    }
    
    /**
     The corner thickness.
     */
    public var cornerInsets: UIEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0) {
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
    
    override init(frame: CGRect) {
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
    @objc public func snapshot(forSecond second: Float64, completion:(UIImage)->(), failure:(()->())?) {
        guard let generator = generator else {
            if failure != nil {
                failure!()
            }
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            if let image = self.generateThumbnail(generator: generator, second: second) {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(image)
                })
                return
            } else {
                if failure != nil {
                    failure!()
                }
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
        
        guard let assetVideoTrack : AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] else { return }
        
        self.asset = asset
        
        activityIndicator.startAnimating()
        
        dispatch_async(dispatch_get_main_queue()) {
            let size = assetVideoTrack.naturalSize
            let thumbnailHeight = self.thumbnailView.bounds.size.height
            let videoAspect = size.width / size.height
            let thumbnailWidth = thumbnailHeight * videoAspect
            
            let generator = AVAssetImageGenerator(asset: asset)
            generator.requestedTimeToleranceBefore = kCMTimeZero
            generator.requestedTimeToleranceAfter = kCMTimeZero
            
            let thumbnailCount = Int(ceil(self.thumbnailView.bounds.size.width / thumbnailWidth))
            let videoDuration = CMTimeGetSeconds(asset.duration)
            let sampleInterval = videoDuration / Float64(thumbnailCount)
            
            self.selectionThumb = SelectionThumb(frame: CGRectMake(self.thumbnailView.frame.origin.x, self.thumbnailView.frame.origin.y, thumbnailWidth, thumbnailHeight))
            
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
                let imageView = UIImageView(frame: CGRectMake(currentX, 0.0, thumbnailWidth, thumbnailHeight))
                imageView.contentMode = .ScaleAspectFill
                imageView.image = image
                self.thumbnailView.addSubview(imageView)
                self.thumbnails.append(imageView)
                currentX += thumbnailWidth
                currentTime += sampleInterval
            }
            self.activityIndicator.stopAnimating()
            self.videoLoaded = true
            self.videoLoading = false
            self.didScrollToPercent(0, override: true)
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
    
    private func generateThumbnail(generator generator: AVAssetImageGenerator, second: Float64) -> UIImage? {
        let time = CMTimeMake(Int64(second * 60), 60)
        do {
            let imgRef = try generator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imgRef)
        } catch {
            return nil
        }
    }
    
    //MARK: - Private loader functions
    private func setup(frame frame: CGRect?) {
        loadNib()
        if frame != nil {
            view.frame = CGRectMake(0, 0, CGRectGetWidth(frame!), CGRectGetHeight(frame!))
        }
        addSubview(view)
        pinView()
        thumbnailView.layer.masksToBounds = true
    }
    
    private func loadNib() {
        NSBundle(forClass: VideoThumbnailSelectionView.self).loadNibNamed("VideoThumbnailSelectionView", owner: self, options: nil)
    }
    
    private func pinView() {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self , attribute: .Leading, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0).active = true
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    //MARK: - Touches
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrollOptions == nil { return }
        guard let selectionThumb = selectionThumb else { return }
        if let touch = touches.first {
            let loc = touch.locationInView(thumbnailView)
            if CGRectContainsPoint(selectionThumb.frame, loc) {
                scrollOptions!.thumbStartLocation = selectionThumb.center.x
                scrollOptions!.scrollStartLocation = loc.x
                scrollOptions!.currentlyScrolling = true
                
                if zoomAnimationScale > 1.0 {
                    selectionThumb.layer.removeAllAnimations()
                    UIView.animateWithDuration(0.2, animations: {
                        selectionThumb.layer.transform = CATransform3DScale(CATransform3DIdentity, self.zoomAnimationScale, self.zoomAnimationScale, 1.0)
                    })
                }
            }
        }

    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrollOptions == nil { return }
        if !(scrollOptions!.currentlyScrolling) { return }
        guard let selectionThumb = selectionThumb else { return }
        if let touch = touches.first {
            let loc = touch.locationInView(thumbnailView)
            let newX = scrollOptions!.getNewLocationAccordingToPoint(loc.x)
            selectionThumb.center.x = newX
            //call view
            didScrollToPercent(scrollOptions!.scrollPercent, override: false)
        }
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrollOptions == nil { return }
        if !(scrollOptions!.currentlyScrolling) { return }
        guard let selectionThumb = selectionThumb else { return }
        didScrollToPercent(scrollOptions!.scrollPercent, override: true)
        if zoomAnimationScale > 1.0 {
            selectionThumb.layer.removeAllAnimations()
            UIView.animateWithDuration(0.2, animations: {
                selectionThumb.layer.transform = CATransform3DIdentity
            })
        }
        scrollOptions!.reset()
    }
    
}
