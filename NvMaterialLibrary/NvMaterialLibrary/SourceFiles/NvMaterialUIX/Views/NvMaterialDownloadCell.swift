//
//  NvMaterialDownloadCell.swift
//  MYVideo
//
//  Created by chengww on 2021/11/26.
//  Copyright © 2021 MEISHE. All rights reserved.
//

import UIKit

open class NvMaterialDownloadCell: UICollectionViewCell, NvReusable {
    
    lazy var animation: UIView = {
        let itemSize = self.frame.size
        let height = itemSize.width > itemSize.height ? itemSize.height : itemSize.width
        let view = UIView(frame: CGRect(x: 0, y: 0, width: itemSize.width, height: height))
        view.backgroundColor = UIColor.black
        view.layer.cornerRadius = 3 * NvMaterialUIXEnvs.scale
        view.layer.masksToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required public init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func startDownload() {
        if let layer = aniLayer {
            layer.removeFromSuperlayer()
            aniLayer = nil
            animation.removeFromSuperview()
        }
        contentView.addSubview(animation)
        let nAniLayer = animationLayer()
        aniLayer = nAniLayer
        animation.layer.addSublayer(nAniLayer)
    }

    open func stopDownload() {
        if let layer = aniLayer {
            layer.removeFromSuperlayer()
            aniLayer = nil
            animation.removeFromSuperview()
        }
    }

    private var aniLayer: CALayer?
}

extension NvMaterialDownloadCell {
    
    private func animationLayer() -> CALayer {
        let between: CGFloat = 2.0
        let itemSize = frame.size
        let radius = (itemSize.width / 3 - 2 * between) / 3
        let replicatorLayerH = itemSize.width > itemSize.height ? itemSize.height : itemSize.width
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: (itemSize.width - 3 * radius - 2 * between) / 2,
                                  y: (replicatorLayerH - radius) / 2, width: radius, height: radius)
        shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: radius, height: radius)).cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.add(scaleAnimation(), forKey: "scaleAnimation")
        let replicatorLayer = CAReplicatorLayer()

        replicatorLayer.frame = CGRect(x: 0, y: 0, width: itemSize.width, height: replicatorLayerH)
        replicatorLayer.instanceDelay = 0.2
        replicatorLayer.instanceCount = 3
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(between * 2 + radius, 0, 0)
        replicatorLayer.addSublayer(shapeLayer)
        return replicatorLayer
    }

    private func scaleAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(caTransform3D: CATransform3DScale(CATransform3DIdentity, 1.0, 1.0, 0.0))
        animation.toValue = NSValue(caTransform3D: CATransform3DScale(CATransform3DIdentity, 0.4, 0.4, 0.0))
        animation.autoreverses = true
        animation.repeatCount = HUGE
        animation.duration = 0.4
        return animation
    }
}
