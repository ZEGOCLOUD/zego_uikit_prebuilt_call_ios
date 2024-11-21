//
//  CallInvitationServiceDelegate.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2024/1/18.
//

import Foundation
import ZegoUIKit

@objc public protocol ZegoUIKitPrebuiltCallInvitationServiceDelegate: AnyObject {
    @objc func requireConfig(_ data: ZegoCallInvitationData) -> ZegoUIKitPrebuiltCallConfig
    @objc optional func onPressed(_ errorCode: Int, errorMessage: String?, errorInvitees: [ZegoCallUser]?)
    // update User Avatar
    @objc optional func onUserIDUpdated(user: ZegoUIKitUser) -> NSString?
    @objc optional func onIncomingCallDeclineButtonPressed()
    @objc optional func onIncomingCallAcceptButtonPressed()
    @objc optional func onOutgoingCallCancelButtonPressed()
    @objc optional func onIncomingCallReceived(_ callID: String, caller: ZegoCallUser, callType: ZegoCallType, callees: [ZegoCallUser]?)
    @objc optional func onIncomingCallCanceled(_ callID: String, caller: ZegoCallUser)
    @objc optional func onOutgoingCallAccepted(_ callID: String, callee: ZegoCallUser)
    @objc optional func onOutgoingCallRejectedCauseBusy(_ callID: String, callee: ZegoCallUser)
    @objc optional func onOutgoingCallDeclined(_ callID: String, callee: ZegoCallUser)
    @objc optional func onIncomingCallTimeout(_ callID: String,  caller: ZegoCallUser)
    @objc optional func onOutgoingCallTimeout(_ callID: String, callees: [ZegoCallUser])
    
    @objc optional func onCallTimeUpdate(_ duration: Int)
    
}
