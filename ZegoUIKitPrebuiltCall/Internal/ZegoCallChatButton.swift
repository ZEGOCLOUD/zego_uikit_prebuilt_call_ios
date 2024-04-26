//
//  ZegoCallChatButton.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/10/18.
//

import UIKit

class ZegoCallChatButton: UIButton {
    
    public var iconChat: UIImage = ZegoUIKitCallIconSetType.icon_message_normal.load() {
        didSet {
            self.setImage(iconChat, for: .normal)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(ZegoUIKitCallIconSetType.icon_message_normal.load(), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
