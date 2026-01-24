import UIKit
import Foundation

open class NvRefreshAutoTrailer: NvRefreshTrailer {
    public private(set) weak var stateLabel: UILabel?
    public private(set) weak var arrowView: UIImageView?
    

    open class func trailer(forTarget target: AnyObject, action: Selector) -> NvRefreshAutoTrailer {
        let refreshView = NvRefreshAutoTrailer(frame: .zero)
        refreshView.configRefreshEvent(target: target, action: action)
        refreshView.stateLabel?.text = refreshView.stateTitles[refreshView.state.rawValue]
        return refreshView
    }

    override open func prepare() {
        super.prepare()
        isAutomaticallyChangeAlpha = false
        // 初始化控件
        initCustomControl()
        // 初始化文字
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.TrailerIdleText, comment: ""), state: .idel)
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.TrailerPullingText, comment: ""), state: .pulling)
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.TrailerNoMoreDataText, comment: ""), state: .noMoreData)
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.TrailerRefreshingText, comment: ""), state: .refreshing)
    }

    override open func placeSubviews() {
        super.placeSubviews()

        guard let stateLabel = stateLabel, let arrowView = arrowView else { return }
        guard !stateLabel.isHidden else { return }
        
        var refreshHeightWithInset = refresh_height
        
        var insetTop: CGFloat = 0
        var insetBottom: CGFloat = 0
        
        if let sv = scrollView {
            insetTop = sv.contentInset.top
            insetBottom = sv.contentInset.bottom
        }
        refreshHeightWithInset -= insetTop + insetBottom
        
        let refreshCenterY = refreshHeightWithInset * 0.5

        let noConstrainsOnStatusLabel = stateLabel.constraints.count == 0
        let stateLabelW = ceilf(Float(stateLabel.font.pointSize ?? 0))

        if noConstrainsOnStatusLabel {
            stateLabel.center = CGPoint(x: refresh_width * 0.5, y: refreshCenterY)
            stateLabel.refresh_size = CGSize(width: CGFloat(stateLabelW), height: refreshHeightWithInset)
        }

        let arrowSize = arrowView.image?.size ?? .zero
        // 箭头的中心点
        let selfCenter = CGPoint(x: refresh_width * 0.5, y: refreshCenterY)
        let arrowCenter = CGPoint(x: arrowSize.width * 0.5 + 5, y: refreshCenterY)

        let stateHidden = stateLabel.isHidden

        if arrowView.constraints.isEmpty == true {
            arrowView.refresh_size = arrowSize
            arrowView.center = stateHidden == true ? selfCenter : arrowCenter
        }
        arrowView.tintColor = stateLabel.textColor

        if stateHidden { return }

        // 状态
        if noConstrainsOnStatusLabel {
            let arrowHidden = arrowView.isHidden
            let stateCenterX = (refresh_width + arrowSize.width) * 0.5
            stateLabel.center = arrowHidden == true ? selfCenter : CGPoint(x: stateCenterX, y: refreshCenterY)
            stateLabel.refresh_size = CGSize(width: CGFloat(stateLabelW), height: refreshHeightWithInset)
        }
    }

    override open func updateRefreshState(for lastState: NvRefreshComponent.NvRefreshState) {
        super.updateRefreshState(for: lastState)
        stateLabel?.text = stateTitles[state.rawValue]
        if state == .idel {
            self.arrowView?.alpha = 1
            if lastState == .refreshing {
                UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
                    self.arrowView?.transform = CGAffineTransform(rotationAngle: .pi)
                }, completion: {
                    if $0 { self.arrowView?.transform = .identity }
                })
            } else {
                UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
                    self.arrowView?.transform = .identity
                })
            }
        } else if state == .pulling {
            self.arrowView?.alpha = 1
            UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
                self.arrowView?.transform = CGAffineTransform(rotationAngle: .pi)
            })
        } else if state == .noMoreData {
            self.arrowView?.alpha = 0
        }
    }

    private var stateTitles: [Int: String] = [:]
}

extension NvRefreshAutoTrailer {
    private func initCustomControl() {
        let sLabel = UILabel.refresh_label()
        let imageView = UIImageView(image: NvMaterialUIXEnvs.image(named: "trail_arrow"))
        addSubview(sLabel)
        addSubview(imageView)
        stateLabel = sLabel
        arrowView = imageView
    }

    private func setTitle(_ title: String?, state: NvRefreshComponent.NvRefreshState) {
        guard let text = title else { return }
        stateTitles[state.rawValue] = text
    }
}
