//
//  CustomSlider.swift
//  Mixer
//
//  Created by Edward on 6/9/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit

@IBDesignable
class CustomSlider: UISlider {

    @IBInspectable var trackWidth: CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultBounds = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultBounds.origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height/2 - trackWidth/2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }

}
