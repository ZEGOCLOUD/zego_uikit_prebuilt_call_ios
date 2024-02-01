//
//  CallVCApi.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2024/1/18.
//

import Foundation

public protocol CallVCApi {
    
    func addButtonToBottomMenuBar(_ button: UIButton)
    
    func addButtonToTopMenuBar(_ button: UIButton)
    
    func finish()
}
