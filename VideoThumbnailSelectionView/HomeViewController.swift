//
//  HomeViewController.swift
//  VideoThumbnailSelectionView
//
//  Created by indianic on 18/07/18.
//  Copyright © 2018 Sarp Solakoğlu. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController {

     var videoThumbnailSelectionView: VideoThumbnailSelectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoThumbnailSelectionView = VideoThumbnailSelectionView(frame:CGRect.init(x: 20, y: 300, width: 325, height: 60))
        view.addSubview(videoThumbnailSelectionView)
        videoThumbnailSelectionView.shadeTintAlpha = 0.5
        //scale animation when thumb is dragged (1.0 for no animation).
        videoThumbnailSelectionView.zoomAnimationScale = 1.5
        //corner color
        videoThumbnailSelectionView.cornerColor = .white
        //corner radius
        videoThumbnailSelectionView.cornerRadius = 8.0
        //corner thickness
        videoThumbnailSelectionView.cornerInsets = UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0)
        //called when selection changes
        videoThumbnailSelectionView.onUpdatedImage = { image in
            //do stuff with the image
            print(image)
        };
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //after customization, call this to load your asset.
        let url = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        let asset: AVURLAsset = AVURLAsset(url: url!)
        videoThumbnailSelectionView.loadVideo(asset: asset)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
