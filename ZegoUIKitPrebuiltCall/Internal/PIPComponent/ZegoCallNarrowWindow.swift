//
//  ZegoCallNarrowWindow.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/11/17.
//

import UIKit

class ZegoCallNarrowWindow: UIView {
    
    let kBerthRegionWidth: CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.masksToBounds = true
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func panGesture(gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let translation: CGPoint = gesture.translation(in: self)
            center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
            gesture.setTranslation(.zero, in: self)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            var toFrame: CGRect = self.frame
            if (self.center.x < UIScreen.main.bounds.width / 2.0) {
                toFrame.origin.x = kBerthRegionWidth;
            } else {
                toFrame.origin.x = UIScreen.main.bounds.width - kBerthRegionWidth - self.bounds.width;
            }
            if self.frame.origin.y < ZegoCallNarrowWindow.getStatusBarHight() {
                toFrame.origin.y = ZegoCallNarrowWindow.getStatusBarHight()
            } else if (self.frame.origin.y + self.frame.size.height) > (UIScreen.main.bounds.height - ZegoCallNarrowWindow.getVirtualHomeHeight()) {
                toFrame.origin.y = UIScreen.main.bounds.height - ZegoCallNarrowWindow.getStatusBarHight() - self.bounds.height
            }
            UIView.animate(withDuration: 0.65, delay: 0.0, usingSpringWithDamping: 0.59, initialSpringVelocity: 0, options: .curveLinear) {
                self.frame = toFrame
            }completion: { finished in
                
            }
            
        }
    }
    
    static func getVirtualHomeHeight() -> CGFloat {
        var virtualHomeHeight: CGFloat = 0
        if #available(iOS 11.0, *) {
            let keyWindow: UIWindow? = UIApplication.shared.keyWindow
            virtualHomeHeight = keyWindow?.safeAreaInsets.bottom ?? 100
        }
        return virtualHomeHeight
    }
    
    static func getStatusBarHight() -> CGFloat {
        var statusBarHeight: CGFloat = 0
        if #available(iOS 13.0, *) {
            let statusBarManager: UIStatusBarManager? = UIApplication.shared.windows.last?.windowScene?.statusBarManager
            statusBarHeight = statusBarManager?.statusBarFrame.size.height ?? 200
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        }
        return statusBarHeight
    }
    
    func showNarrowWindow(contentView: UIView, desFrame: CGRect) {
        self.frame = UIScreen.main.bounds
        UIApplication.shared.keyWindow?.addSubview(self)
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.25) {
            self.frame = desFrame
            self.layer.cornerRadius = 10
            self.layer.borderWidth = 1
            self.layer.borderColor = UIColor.colorWithHexString("#565A60").cgColor
            self.layoutIfNeeded()
        } completion: { finished in
            
        }
        
    }
    
    func closeNarrowWindow() {
        UIView.animate(withDuration: 0.25) {
            self.frame = UIScreen.main.bounds
            self.layer.cornerRadius = 0
            self.layer.borderWidth = 0
            self.layer.borderColor = UIColor.clear.cgColor
            self.layoutIfNeeded()
        } completion: { finished in
            self.removeFromSuperview()
        }
    }
}
