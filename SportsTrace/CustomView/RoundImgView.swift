//
//  RoundImgView.swift
//  SportsTrace
//
//  Created by Nishant Shah on 29/09/20.
//  Copyright © 2020 MF. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class RoundImageView: UIImageView {
    private var _round = false
    private var _borderColor = UIColor.clear
    private var _borderWidth: CGFloat = 0

@IBInspectable var round: Bool {
    set {
        _round = newValue
        makeRound()
    }
    get {
        return self._round
    }
}

@IBInspectable var borderColor: UIColor {
    set {
        _borderColor = newValue
        setBorderColor()
    }
    get {
        return self._borderColor
    }
}

@IBInspectable var borderWidth: CGFloat {
    set {
        _borderWidth = newValue
        setBorderWidth()
    }
    get {
        return self._borderWidth
    }
}

    override internal var frame: CGRect {
        set {
            super.frame = newValue
            makeRound()
        }
        get {
            return super.frame
        }
    }

    private func makeRound() {
        if self.round {
            self.clipsToBounds = true
            self.layer.cornerRadius = (self.frame.width + self.frame.height) / 4
        } else {
            self.layer.cornerRadius = 0
        }
    }

    private func setBorderColor() {
        self.layer.borderColor = self._borderColor.cgColor
    }

    private func setBorderWidth() {
        self.layer.borderWidth = self._borderWidth
    }

}
