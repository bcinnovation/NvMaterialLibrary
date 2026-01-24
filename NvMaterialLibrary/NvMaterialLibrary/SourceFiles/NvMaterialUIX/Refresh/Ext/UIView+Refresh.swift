import UIKit

extension UIView {
    var refresh_x: CGFloat {
        get {
            frame.origin.x
        }
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }

    var refresh_y: CGFloat {
        get {
            frame.origin.y
        }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }

    var refresh_width: CGFloat {
        get {
            frame.size.width
        }
        set {
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }

    var refresh_height: CGFloat {
        get {
            frame.size.height
        }
        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }

    var refresh_size: CGSize {
        get {
            frame.size
        }
        set {
            var frame = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }

    var refresh_origin: CGPoint {
        get {
            frame.origin
        }
        set {
            var frame = self.frame
            frame.origin = newValue
            self.frame = frame
        }
    }
}

extension UIScrollView {
    var refresh_inset: UIEdgeInsets {
        #if __IPHONE_11_0
            if adjustedContentInset != UIEdgeInsets.zero {
                return adjustedContentInset
            }
        #endif
        return contentInset
    }

    var refresh_insetT: CGFloat {
        get {
            refresh_inset.top
        }
        set {
            var inset = contentInset
            inset.top = newValue
            #if __IPHONE_11_0
                if adjustedContentInset != UIEdgeInsets.zero {
                    inset.top -= (adjustedContentInset.top - contentInset.top)
                }
            #endif
            contentInset = inset
        }
    }

    var refresh_insetB: CGFloat {
        get {
            refresh_inset.bottom
        }
        set {
            var inset = contentInset
            inset.bottom = newValue
            #if __IPHONE_11_0
                if adjustedContentInset != UIEdgeInsets.zero {
                    inset.bottom -= (adjustedContentInset.bottom - contentInset.bottom)
                }
            #endif
            contentInset = inset
        }
    }

    var refresh_insetL: CGFloat {
        get {
            refresh_inset.left
        }
        set {
            var inset = contentInset
            inset.left = newValue
            #if __IPHONE_11_0
                if adjustedContentInset != UIEdgeInsets.zero {
                    inset.left -= (adjustedContentInset.left - contentInset.left)
                }
            #endif
            contentInset = inset
        }
    }

    var refresh_insetR: CGFloat {
        get {
            refresh_inset.right
        }
        set {
            var inset = contentInset
            inset.right = newValue
            #if __IPHONE_11_0
                if adjustedContentInset != UIEdgeInsets.zero {
                    inset.right -= (adjustedContentInset.right - contentInset.right)
                }
            #endif
            contentInset = inset
        }
    }

    var refresh_offsetX: CGFloat {
        get {
            contentOffset.x
        }
        set {
            var offset = contentOffset
            offset.x = newValue
            contentOffset = offset
        }
    }

    var refresh_offsetY: CGFloat {
        get {
            contentOffset.y
        }
        set {
            var offset = contentOffset
            offset.y = newValue
            contentOffset = offset
        }
    }

    var refresh_contentW: CGFloat {
        get {
            contentSize.width
        }
        set {
            var size = contentSize
            size.width = newValue
            contentSize = size
        }
    }

    var refresh_contentH: CGFloat {
        get {
            contentSize.height
        }
        set {
            var size = contentSize
            size.height = newValue
            contentSize = size
        }
    }
}

extension UILabel {
    static func refresh_label() -> UILabel {
        let label = UILabel()
        label.font = NvRefreshConst.LabelFont
        label.textColor = NvRefreshConst.LabelTextColor
        label.textAlignment = .center
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        return label
    }

    func refresh_textWidth() -> CGFloat {
        var stringWidth = 0.0
        let size = CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))
        if let attriText = attributedText {
            guard attriText.length != 0 else {
                return stringWidth
            }
            stringWidth = attriText.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil).size.width
        }

        if let title = text, let titleFont = font {
            guard !title.isEmpty else {
                return stringWidth
            }
            stringWidth = title.boundingRect(with: size,
                                             options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions
                                                 .usesLineFragmentOrigin.rawValue | NSStringDrawingOptions
                                                 .usesFontLeading
                                                 .rawValue | NSStringDrawingOptions.truncatesLastVisibleLine.rawValue),
                                             attributes: [NSAttributedString.Key.font: titleFont],
                                             context: nil).size.width
        }
        return stringWidth
    }
}
