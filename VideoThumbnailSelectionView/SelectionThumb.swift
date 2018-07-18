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
        previewImageView = UIImageView(frame: CGRect.init(x: 2, y: 2, width: frame.size.width - 2, height: frame.size.height - 4))
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(previewImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
