import UIKit

public extension UIScrollView {
    var nv_header: NvRefreshHeader? {
        get {
            objc_getAssociatedObject(self, &NvRefreshConst.AssociatedHeaderKey) as? NvRefreshHeader
        }
        set {
            if self.nv_header != newValue {
                self.nv_header?.removeFromSuperview()
                if let header = newValue {
                    insertSubview(header, at: 0)
                    willChangeValue(forKey: "nv_header")
                    objc_setAssociatedObject(self, &NvRefreshConst.AssociatedHeaderKey, header,
                                             .OBJC_ASSOCIATION_RETAIN)
                    didChangeValue(forKey: "nv_header")
                }
            }
        }
    }

    var nv_footer: NvRefreshFooter? {
        get {
            objc_getAssociatedObject(self, &NvRefreshConst.AssociatedFooterKey) as? NvRefreshFooter
        }
        set {
            if self.nv_footer != newValue {
                self.nv_footer?.removeFromSuperview()
                if let footer = newValue {
                    insertSubview(footer, at: 0)
                    willChangeValue(forKey: "nv_footer")
                    objc_setAssociatedObject(self, &NvRefreshConst.AssociatedFooterKey, footer,
                                             .OBJC_ASSOCIATION_RETAIN)
                    didChangeValue(forKey: "nv_footer")
                }
            }
        }
    }

    var nv_trailer: NvRefreshAutoTrailer? {
        get {
            objc_getAssociatedObject(self, &NvRefreshConst.AssociatedTrailerKey) as? NvRefreshAutoTrailer
        }
        set {
            if self.nv_trailer != newValue {
                self.nv_trailer?.removeFromSuperview()
                if let tailer = newValue {
                    insertSubview(tailer, at: 0)
                    willChangeValue(forKey: "nv_trailer")
                    objc_setAssociatedObject(self, &NvRefreshConst.AssociatedTrailerKey, tailer,
                                             .OBJC_ASSOCIATION_RETAIN)
                    didChangeValue(forKey: "nv_trailer")
                }
            }
        }
    }

    func nv_totalDataCount() -> Int {
        var totalCount = 0
        if let items = self as? UITableView {
            for section in 0 ..< items.numberOfSections {
                totalCount += items.numberOfRows(inSection: section)
            }
        } else if let items = self as? UICollectionView {
            for section in 0 ..< items.numberOfSections {
                totalCount += items.numberOfItems(inSection: section)
            }
        }
        return totalCount
    }
}
