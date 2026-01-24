//
// UICollectionView+NvReusable.swift
//  MYVideo
//
//  Created by meishe on 2023/3/16.
//  Copyright © 2023 MEISHE. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol NvReusable: AnyObject {
  static var nvReuseIdentifier: String { get }
}

public extension NvReusable {
  static var nvReuseIdentifier: String {
    return String(describing: self)
  }
}

// MARK: -- Reusable support for UICollectionView
public extension UICollectionView {

  final func nvRegister<T: UICollectionViewCell>(cellType: T.Type)
    where T: NvReusable {
      self.register(cellType.self, forCellWithReuseIdentifier: cellType.nvReuseIdentifier)
  }

  final func nvDequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath, cellType: T.Type = T.self) -> T
    where T: NvReusable {
      let bareCell = self.dequeueReusableCell(withReuseIdentifier: cellType.nvReuseIdentifier, for: indexPath)
      guard let cell = bareCell as? T else {
          log.error("dequeueReusableCell error:\(cellType.nvReuseIdentifier)")
          return T(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
      }
      return cell
  }

}

public extension UITableView {

  final func nvRegister<T: UITableViewCell>(cellType: T.Type)
    where T: NvReusable {
        self.register(cellType.self, forCellReuseIdentifier: cellType.nvReuseIdentifier)
  }

  final func nvDequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath, cellType: T.Type = T.self) -> T
    where T: NvReusable {
      let bareCell = self.dequeueReusableCell(withIdentifier: cellType.nvReuseIdentifier, for: indexPath)
      guard let cell = bareCell as? T else {
          log.error("dequeueReusableCell error:\(cellType.nvReuseIdentifier)")
          return T(style: .default, reuseIdentifier: cellType.nvReuseIdentifier)
      }
      return cell
  }

}

#endif
