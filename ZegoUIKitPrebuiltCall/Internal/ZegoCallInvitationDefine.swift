//
//  ZegoCallInvitationDefine.swift
//  ZegoUIKitCallWithInvitation
//
//  Created by zego on 2022/10/17.
//

import Foundation
import ZegoUIKitSDK

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

class ZegoCallPrebuiltInvitationData: NSObject {
    var pluginInvitationID: String? //is zim call id
    var invitationID: String? // is rtc roomID
    var inviter: ZegoUIKitUser?
    var invitees: [ZegoCallPrebuiltInvitationUser]?
    var type: ZegoInvitationType = .voiceCall
    var inviteesDict: [String : String] = [:]
    
    init(_ invitationID: String, inviter: ZegoUIKitUser, invitees: [ZegoCallPrebuiltInvitationUser], type: ZegoInvitationType) {
        super.init()
        self.invitationID = invitationID
        self.invitees = invitees
        self.inviter = inviter
        self.type = type
        for user in invitees {
            guard let userID = user.user?.userID else { continue }
            self.inviteesDict[userID] = invitationID
        }
    }
}
