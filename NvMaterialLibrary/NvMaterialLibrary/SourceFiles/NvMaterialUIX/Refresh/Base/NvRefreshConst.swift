import Foundation
import UIKit

enum NvRefreshConst {
    static let ContentOffsetKeyPath: String = "contentOffset"
    static let ContentInsetKeyPath: String = "contentInset"
    static let ContentSizeKeyPath: String = "contentSize"
    static let PanStateKeyPath: String = "state"
    static let HeaderLastUpdatedTimeKey: String = "NvRefreshHeaderLastUpdatedTimeKey"

    static let HeaderHeight: CGFloat = 54.0
    static let FooterHeight: CGFloat = 44.0
    static let TrailWidth: CGFloat = 60.0
    static let LabelLeftInset: CGFloat = 25.0
    static let FastAnimationDuration: CGFloat = 0.25
    static let SlowAnimationDuration: CGFloat = 0.4

    static let LabelFont = UIFont.boldSystemFont(ofSize: 11)
    static let LabelTextColor = UIColor(red: 90.0 / 255.0, green: 90.0 / 255.0, blue: 90.0 / 255.0, alpha: 1.0)

    static let FooterIdleText: String = "NvRefreshFooterIdleText"
    static let FooterPullingText: String = "NvRefreshFooterPullingText"
    static let FooterRefreshingText: String = "NvRefreshFooterRefreshingText"
    static let FooterNoMoreDataText: String = "NvRefreshFooterNoMoreDataText"

    static let TrailerIdleText: String = "NvRefreshTrailerIdleText"
    static let TrailerPullingText: String = "NvRefreshTrailerPullingText"
    static let TrailerRefreshingText: String = "NvRefreshTrailerRefreshingText"
    static let TrailerNoMoreDataText: String = "NvRefreshTrailerNoMoreDataText"

    static var AssociatedHeaderKey: Bool = true
    static var AssociatedFooterKey: Bool = true
    static var AssociatedTrailerKey: Bool = true
}
