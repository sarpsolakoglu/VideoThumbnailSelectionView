//
//  SelectionThumb.swift
//  VideoThumbnailSelectionView
//
//  Created by Sarp Solakoğlu on 02/06/16.
//  Copyright © 2016 Sarp Solakoğlu. All rights reserved.
//

import UIKit

class SelectionThumb: UIView {
    var previewImageView: UIImageView!
    
    override init(frame: CGRect) {
        previewImageView = UIImageView(frame: CGRectMake(2, 2, frame.size.width - 4, frame.size.height - 4))
        super.init(frame: frame)
        backgroundColor = .whiteColor()
        addSubview(previewImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
