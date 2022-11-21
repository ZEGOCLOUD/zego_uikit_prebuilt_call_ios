//
//  ZegoStartCallInvitationButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/12.
//

import UIKit
import ZegoUIKitSDK

public class ZegoStartCallInvitationButton: ZegoStartInvitationButton {

    @objc public var isVideoCall: Bool = false {
        didSet {
            self.type = isVideoCall ? 1 : 0
        }
    }
    
    @objc public var inviteeList: [ZegoUIKitUser] = [] {
        didSet {
            self.invitees.removeAll()
            for user in inviteeList {
                if let userID = user.userID {
                    self.invitees.append(userID)
                }
            }
        }
    }
    
    @objc public var customData: String?
    
    @objc public override init(_ type: Int) {
        super.init(type)
        self.isVideoCall = type == 1 ? true : false
    }
    
//    @objc public override init(_ type: ZegoInvitationType) {
//        super.init(type)
//        self.isVideoCall = type == .videoCall ? true : false
//    }
    
    @objc required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc override open func buttonClick() {
        if ZegoUIKitPrebuiltCallInvitationService.shared.isCalling || invitees.count == 0 { return }
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else { return }
        let callData = ZegoCallInvitationData()
        callData.callID = String(format: "call_%@_%d", userID,getTimeStamp())
        callData.invitees = self.inviteeList
        callData.inviter = ZegoUIKit.shared.localUserInfo
        callData.type = isVideoCall ? .videoCall : .voiceCall
        self.data = ["call_id": callData.callID as AnyObject, "invitees": self.conversionInvitees() as AnyObject, "customData": self.customData as AnyObject].call_jsonString
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = self.buildInvitationData(callData)
        ZegoUIKitInvitationService.shared.sendInvitation(self.invitees, timeout: self.timeout, type: self.type, data: self.data) { data in
            guard let data = data else { return }
            if data["code"] as! Int == 0 {
                if let errorInvitees = data["errorInvitees"] as? [String] {
                    ZegoUIKitPrebuiltCallInvitationService.shared.help.updateUserState(.error, userList: errorInvitees)
                    if errorInvitees.count == self.invitees.count {
                        //all invitees offline
                        ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
                    } else {
                        ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = true
                        self.startCall(callData)
                    }
                    ZegoUIKitPrebuiltCallInvitationService.shared.help.checkInviteesState()
                } else {
                    ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = true
                    self.startCall(callData)
                }
                self.delegate?.onStartInvitationButtonClick(data)
            } else {
                self.delegate?.onStartInvitationButtonClick(data)
                ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
                ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            }
        }
    }
    
    private func startCall(_ callData: ZegoCallInvitationData) {
        if isVideoCall { ZegoUIKit.shared.turnCameraOn(ZegoUIKit.shared.localUserInfo?.userID ?? "", isOn: true) }
        if self.invitees.count > 1 {
            //group call
            let nomalConfig: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallConfig(isVideoCall ? .groupVideoCall : .groupVoiceCall)
            let config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(callData) ?? nomalConfig
            let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(callData, config: config)
            callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
            callVC.modalPresentationStyle = .fullScreen
            currentViewController()?.present(callVC, animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
        } else {
            // one on one call
            let vc = UINib.init(nibName: "ZegoUIKitPrebuiltCallWaitingVC", bundle: Bundle(for: ZegoUIKitPrebuiltCallWaitingVC.self)).instantiate(withOwner: nil, options: nil).first as! ZegoUIKitPrebuiltCallWaitingVC
            vc.isInviter = true
            vc.callInvitationData = callData
            vc.modalPresentationStyle = .fullScreen
            currentViewController()?.present(vc, animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = vc
        }
        ZegoUIKitPrebuiltCallInvitationService.shared.startOutgoingRing()
    }
    
    func conversionInvitees() -> [Dictionary<String,String>] {
        var newInvitees: [Dictionary<String,String>] = []
        for user in self.inviteeList {
            let userDict: Dictionary<String, String> = ["user_id": user.userID ?? "", "user_name": user.userName ?? ""]
            newInvitees.append(userDict)
        }
        return newInvitees
    }
    
    func buildInvitationData(_ callData: ZegoCallInvitationData) -> ZegoCallPrebuiltInvitationData? {
        guard let invitationID = callData.callID,
        let prebuiltInviter = callData.inviter,
        let invitees = callData.invitees
        else { return nil }
        var invitationUsers: [ZegoCallPrebuiltInvitationUser] = []
        for user in invitees {
            let invitationUser = ZegoCallPrebuiltInvitationUser.init(user, state: .wating)
            invitationUsers.append(invitationUser)
        }
        let invitationData: ZegoCallPrebuiltInvitationData = ZegoCallPrebuiltInvitationData.init(invitationID, inviter: prebuiltInviter, invitees: invitationUsers, type: callData.type ?? .voiceCall)
        return invitationData
    }
    
}
