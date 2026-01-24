//
//  NvMaterialEmptyView.swift
//  MYVideo
//
//  Created by chengww on 2022/1/26.
//

import UIKit

extension NvMaterialEmptyView {
    public enum StateType: Int {
        case all
        case netError
    }
}

open class NvMaterialEmptyView: UIView {
    public var callback: (() -> Void)?
    public var listParam: NvMaterialListParam

    public let imageView = UIImageView()
    public let titleLabel = UILabel()
    public let containerView = UIView()
    public private(set) var state: StateType = .all

    public init(frame: CGRect,
                listParam: NvMaterialListParam,
                state: StateType,
                responseError: NvRequestError?) {
        self.listParam = listParam
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        self.state = state
        setupBaseUI()
        configure(state: state, responseError: responseError)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 基础 UI 初始化
    private func setupBaseUI() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = NvMaterialUIXEnvs.font(size: 10 * NvMaterialUIXEnvs.scale)
        titleLabel.textColor = NvMaterialUIXEnvs.hexColor(hex: "#808080")
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - 配置方法（开放给子类或外部刷新）
    open func configure(state: StateType, responseError: NvRequestError?) {
        // 清空旧视图和手势
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.gestureRecognizers?.forEach { containerView.removeGestureRecognizer($0) }

        let info = viewInfo(state, responseError: responseError)
        titleLabel.text = info.infoString

        if let image = info.image {
            imageView.image = image
            containerView.addSubview(imageView)
            containerView.addSubview(titleLabel)

            if info.canRetry {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(nv_didTapEvent))
                containerView.addGestureRecognizer(tapGesture)
                containerView.isUserInteractionEnabled = true
            } else {
                containerView.isUserInteractionEnabled = false
            }

            layoutWithImage()
        } else {
            containerView.addSubview(titleLabel)
            containerView.isUserInteractionEnabled = false
            layoutWithoutImage()
        }
    }

    // MARK: - 开放的布局方法
    open func layoutWithImage() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    open func layoutWithoutImage() {
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    // MARK: - 点击事件
    @objc
    private func nv_didTapEvent() {
        callback?()
    }

    // MARK: - 信息配置
    open func viewInfo(_ type: StateType,
                       responseError: NvRequestError?) -> (image: UIImage?, infoString: String, canRetry: Bool) {
        switch type {
        case .netError:
            return (
                NvMaterialUIXEnvs.image(named: "material_reload_data"),
                NvMaterialUIXEnvs.localizedString(key: "material_list_network_error", comment: "网络错误，请重新刷新"),
                true   // 网络错误允许点击重试
            )
        case .all:
            return (
                nil,
                NvMaterialUIXEnvs.localizedString(key: "material_list_empty", comment: "暂无可用素材"),
                false  // 空列表不需要点击
            )
        }
    }
}
