//
//  ScrollOptions.swift
//  VideoThumbnailSelectionView
//
//  Created by Sarp Solakoğlu on 02/06/16.
//  Copyright © 2016 Sarp Solakoğlu. All rights reserved.
//

import UIKit

struct ScrollOptions {
    
    var startPoint: CGFloat = 0.0
    var endPoint: CGFloat = 0.0
    
    var currentlyScrolling = false
    var thumbStartLocation: CGFloat = 0.0
    var scrollStartLocation: CGFloat = 0.0
    var currentLocation: CGFloat = 0.0
    
    var scrollPercent: CGFloat {
        get {
            return (currentLocation - startPoint) / (endPoint - startPoint)
        }
    }
    
    init(startPoint: CGFloat, endPoint: CGFloat) {
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    mutating func getNewLocationAccordingToPoint(x: CGFloat) -> CGFloat {
        let change = x - scrollStartLocation
        var newPoint = thumbStartLocation + change
        if newPoint < startPoint {
            newPoint = startPoint
        }
        if newPoint > endPoint {
            newPoint = endPoint
        }
        currentLocation = newPoint
        return newPoint
    }
    
    mutating func reset() {
        scrollStartLocation = 0.0
        currentlyScrolling = false
        thumbStartLocation = 0.0
        currentLocation = 0.0
    }
}