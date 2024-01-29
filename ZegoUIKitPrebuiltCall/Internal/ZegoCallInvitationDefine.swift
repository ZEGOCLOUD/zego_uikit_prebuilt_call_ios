//
//  ZegoCallInvitationDefine.swift
//  ZegoUIKitCallWithInvitation
//
//  Created by zego on 2022/10/17.
//

import Foundation
import ZegoUIKit

enum ZegoCallInvitationState: Int {
    case error
    case wating
    case accept
    case refuse
    case cancel
    case timeout
}

class ZegoCallPrebuiltInvitationUser: NSObject {
    
    var user: ZegoUIKitUser?
    var state: ZegoCallInvitationState = .error
    
    init(_ user: ZegoUIKitUser, state: ZegoCallInvitationState) {
        self.user = user
        self.state = state
    }
    
}
