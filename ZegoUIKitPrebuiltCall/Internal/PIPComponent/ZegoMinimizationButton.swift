//
//  ZegoMinimizationButton.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/11/13.
//

import UIKit

protocol ZegoMinimizationButtonDelegate: AnyObject {
    func onMinimizationButtonDidClick()
}

extension ZegoMinimizationButtonDelegate {
    func onMinimizationButtonDidClick() {}
}

class ZegoMinimizationButton: UIButton {
    
    weak var delegate: ZegoMinimizationButtonDelegate?
    
    public var iconMinimize: UIImage = ZegoUIKitCallIconSetType.minimizing_icon.load() {
        didSet {
            self.setImage(iconMinimize, for: .normal)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(ZegoUIKitCallIconSetType.minimizing_icon.load(), for: .normal)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        if #available(iOS 15.0, *) {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            ZegoMinimizeManager.shared.isNarrow = true
            delegate?.onMinimizationButtonDidClick()
          }
        }
    }
    
}
