//
//  NvAnimatedImageView.swift
//  MYVideo
//
//  Created by chengww on 2022/2/25.
//
import UIKit
import SDWebImage
import SDWebImageWebPCoder
import ObjectiveC

open class NvAnimatedImageView: UIImageView {
    
    public static func configWebImageLib() {
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
    }
    
    // 自定义缓存目录，互通工程网络缩略图缓存
    fileprivate static var imageCache: SDImageCache = {
        let cachePath = NSHomeDirectory() + "/Documents/imageCache"
        return SDImageCache(namespace: "m3u8ImageCache", diskCacheDirectory: cachePath)
    }()
    
    public static func cache(image: UIImage, url: String) {
        NvAnimatedImageView.imageCache.store(image, forKey: url, completion: nil)
    }

    public static func fetchImageFromCache(imageUrl: String) -> UIImage? {
        return NvAnimatedImageView.imageCache.imageFromMemoryCache(forKey: imageUrl)
    }
}

private var nvExpectedImageURLKey: UInt8 = 0

extension UIImageView {
    
    private var nvExpectedImageURL: URL? {
        get {
            return objc_getAssociatedObject(self, &nvExpectedImageURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(self, &nvExpectedImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func nv_setImage(_ image: UIImage?) {
        self.sd_cancelCurrentImageLoad()
        // 设置 expectedURL 为 nil，以防旧图意外回调
        self.nvExpectedImageURL = nil
        
        self.image = image
    }
    // MARK: - NvWebImageDelegate

    public func nv_image(urlString: String, placeholderImage: UIImage? = nil, in bundle: Bundle?) {
        self.sd_cancelCurrentImageLoad()
        
        // 设置 expectedURL 为 nil，以防旧图意外回调
        self.nvExpectedImageURL = nil

        if !urlString.contains("/") {
            contentMode = .center
            let nImage = UIImage(named: urlString, in: bundle, compatibleWith: nil) ??
                nil
            if let nImage = nImage {
                image =  nImage.withRenderingMode(.alwaysOriginal)
            } else {
                image =  UIImage(named: urlString)?.withRenderingMode(.alwaysOriginal)
            }
        } else if urlString.hasPrefix("http") {
            contentMode = .scaleAspectFit
            guard let url = URL(string: urlString) else {
                image = nil
                return
            }
            
            // 记录当前正在加载的 URL
            self.nvExpectedImageURL = url

            let scale = UIScreen.main.scale
            let pixelSize = CGSize(width: self.frame.size.width * scale,
                                   height: self.frame.size.height * scale)
            
//            // 下采样 + 控制缓存类型
//            let context: [SDWebImageContextOption: Any] = [
//                .imageThumbnailPixelSize: pixelSize,           // 按显示尺寸解码
//                .imageScaleFactor: scale,
//                .imagePreserveAspectRatio: true,
//                .queryCacheType: SDImageCacheType.all.rawValue
//            ]
            
            // 关键选项
            let options: SDWebImageOptions = [
                .retryFailed,
//                .continueInBackground,
//                .highPriority,
//                .scaleDownLargeImages,
                .avoidAutoSetImage,        // 关闭自动赋值
                .matchAnimatedImageClass   // 自动检测动图类型
            ]

            self.sd_setImage(with: url,
                             placeholderImage: placeholderImage,
                             options: options,
                             context: nil,
                             progress: nil) { [weak self] image, error, cacheType, loadedURL in
                guard let self = self else { return }

                // 只赋值当前最新请求的 URL 返回的图片
                if self.nvExpectedImageURL == loadedURL {
                    self.image = image
                    if let img = image {
                        if img.size.width > 300 || img.size.height > 300 {
                            print("⚠️ \(urlString)\nImage too large，width: \(img.size.width)，height: \(img.size.height)")
                        }
                    }
                }

                if let error = error as? NSError, error.code != 2002 {
                    print("❌ Image loading failure: \(error.localizedDescription)")
                }
            }
        } else {
            // 本地文件路径
            contentMode = .scaleAspectFit
            let url = URL(fileURLWithPath: urlString)

            self.nvExpectedImageURL = url

//            let options: SDWebImageOptions = [.scaleDownLargeImages]
//
//            let context: [SDWebImageContextOption : Any] = [
//                .imageTransformer: SDImageResizingTransformer(size: self.frame.size, scaleMode: .aspectFit)
//            ]

            self.sd_setImage(with: url,
                             placeholderImage: nil,
//                             options: options,
//                             context: context,
                             progress: nil) { [weak self] image, error, _, loadedURL in
                guard let self = self else { return }

                if self.nvExpectedImageURL == loadedURL, let img = image {
                    self.image = img
                }

                if let error = error as? NSError, error.code != 2002 {
                    print("❌ Local image loading failure: \(error.localizedDescription)")
                }
            }
        }
    }
}
