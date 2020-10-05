//
//  BtnView.swift
//  SportsTrace
//
//  Created by Nishant Shah on 29/09/20.
//  Copyright © 2020 MF. All rights reserved.
//

import Foundation
import UIKit
 
@IBDesignable
class DesignableButton: UIButton {
    
        @IBInspectable var borderWidth: CGFloat {
            set {
                layer.borderWidth = newValue
            }
            get {
                return layer.borderWidth
            }
        }

        @IBInspectable var cornerRadius: CGFloat {
            set {
                layer.cornerRadius = newValue
            }
            get {
                return layer.cornerRadius
            }
        }

        @IBInspectable var borderColor: UIColor? {
            set {
                guard let uiColor = newValue else { return }
                layer.borderColor = uiColor.cgColor
            }
            get {
                guard let color = layer.borderColor else { return nil }
                return UIColor(cgColor: color)
            }
        }
    
        @IBInspectable
        var shadowRadius: CGFloat = 0 {
            didSet {
                self.layer.shadowRadius = shadowRadius
            }
        }
    
        @IBInspectable
        var shadowOpacity: Float = 0 {
            didSet {
                self.layer.shadowOpacity = shadowOpacity
            }
        }

    
}
 
