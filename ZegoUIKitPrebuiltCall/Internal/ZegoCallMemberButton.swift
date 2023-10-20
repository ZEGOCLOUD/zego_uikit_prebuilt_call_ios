//
//  ZegoMemberListButton.swift
//  ZegoPrebuiltVideoConferenceDemoDemo
//
//  Created by zego on 2022/9/15.
//

import UIKit

class ZegoCallMemberButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(ZegoUIKitCallIconSetType.icon_member_normal.load(), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
