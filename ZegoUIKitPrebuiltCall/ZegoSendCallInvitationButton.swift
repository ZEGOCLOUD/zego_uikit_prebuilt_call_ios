//
//  ZegoStartCallInvitationButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/12.
//

import UIKit
import ZegoUIKit
import ZegoPluginAdapter

@objc public protocol ZegoSendCallInvitationButtonDelegate: AnyObject{
    func onPressed(_ errorCode: Int, errorMessage: String?, errorInvitees: [ZegoCallUser]?)
}

extension ZegoSendCallInvitationButtonDelegate {
//    func onPressed(_ errorCode: Int, errorMessage: String?, errorInvitees: [ZegoCallUser?]?){ }
}

public class ZegoSendCallInvitationButton: UIButton {
    
    @objc public var icon: UIImage? {
        didSet {
            guard let icon = icon else {
                return
            }
            self.setImage(icon, for: .normal)
        }
    }
    @objc public var text: String? {
        didSet {
            self.setTitle(text, for: .normal)
        }
    }
    @objc public var invitees: [String] = []
    @objc public var data: String?
    @objc public var timeout: UInt32 = 60
    @objc public var type: Int = 0
    @objc public weak var delegate: ZegoSendCallInvitationButtonDelegate?
    
    @objc public var customData: String?
    
    @objc public var resourceID: String?

    @objc public init(_ type: Int) {
        super.init(frame: CGRect.zero)
        if type == 0 {
            self.setImage(ZegoUIKitCallIconSetType.user_phone_icon.load(), for: .normal)
        } else {
            self.setImage(ZegoUIKitCallIconSetType.user_video_icon.load(), for: .normal)
        }
        self.type = type
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        self.isVideoCall = type == 1 ? true : false
    }
        
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
    
    var callInvitationConfig: ZegoUIKitPrebuiltCallInvitationConfig?
//    @objc public override init(_ type: Int) {
//        super.init(type)
//        self.isVideoCall = type == 1 ? true : false
//    }
    
//    @objc public override init(_ type: ZegoInvitationType) {
//        super.init(type)
//        self.isVideoCall = type == .videoCall ? true : false
//    }
    
    @objc required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func buttonClick() {
        if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData != nil || invitees.count == 0 { return }
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else { return }
        let callData = ZegoCallInvitationData()
        callData.callID = String(format: "call_%@_%d", userID,getTimeStamp())
        callData.invitees = self.inviteeList
        callData.inviter = ZegoUIKit.shared.localUserInfo
        callData.type = isVideoCall ? .videoCall : .voiceCall
        self.data = ["call_id": callData.callID as AnyObject, 
                     "invitees": self.conversionInvitees() as AnyObject,
                     "inviter": self.conversionInviter() as AnyObject,
                     "customData": self.customData as AnyObject].call_jsonString
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
        ZegoUIKitPrebuiltCallInvitationService.shared.invitees = buildInvitationUserList(callData)
        
        let config: ZegoUIKitPrebuiltCallInvitationConfig? = ZegoUIKitPrebuiltCallInvitationService.shared.config
        let resourceID: String = self.resourceID ?? ""
        let notificationTitle: String = callData.type == .videoCall ? String(format: config?.translationText.incomingVideoCallDialogTitle ?? "%@", callData.inviter?.userName ?? "") : String(format: config?.translationText.incomingVoiceCallDialogTitle ?? "%@", callData.inviter?.userName ?? "")
        let notificationMessage: String = (callData.invitees?.count ?? 0 > 1 ? (callData.type == .videoCall ? config?.translationText.incomingGroupVideoCallDialogMessage : config?.translationText.incomingGroupVoiceCallDialogMessage) : (callData.type == .videoCall ? config?.translationText.incomingVideoCallDialogMessage : config?.translationText.incomingVoiceCallDialogMessage))!
        
        let notificationConfig: ZegoSignalingPluginNotificationConfig = ZegoSignalingPluginNotificationConfig.init(resourceID: resourceID, title: notificationTitle, message: notificationMessage)
        ZegoUIKitSignalingPluginImpl.shared.sendInvitation(self.invitees, timeout: self.timeout, type: self.type, data: self.data, notificationConfig: notificationConfig) { data in
            guard let data = data else { return }
            let code: Int = data["code"] as! Int
            let message: String? = data["messae"] as? String
            let errorInvitees: [AnyObject]? = data["errorInvitees"] as? [AnyObject]
            var errorUsers = []
            if let errorInvitees = errorInvitees {
                for user in errorInvitees {
                    let callUser: ZegoCallUser = ZegoCallUser()
                    callUser.id = user as? String
                    errorUsers.append(callUser)
                }
            }
            if code == 0 {
                if let errorInvitees = data["errorInvitees"] as? [String] {
                    ZegoUIKitPrebuiltCallInvitationService.shared.help.updateUserState(.error, userList: errorInvitees)
                    if errorInvitees.count == self.invitees.count {
                        //all invitees offline
                        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
                    } else {
                        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID = data["callID"] as? String
                        self.startCall(callData)
                    }
                    ZegoUIKitPrebuiltCallInvitationService.shared.help.checkInviteesState()
                } else {
                    self.startCall(callData)
                }
                self.delegate?.onPressed(code, errorMessage: message, errorInvitees: errorUsers as? [ZegoCallUser])
            } else {
                self.delegate?.onPressed(code, errorMessage: message, errorInvitees: errorUsers as? [ZegoCallUser])
                ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            }
        }
    }
    
    private func startCall(_ callData: ZegoCallInvitationData) {
        if isVideoCall { ZegoUIKit.shared.turnCameraOn(ZegoUIKit.shared.localUserInfo?.userID ?? "", isOn: true) }
        if self.invitees.count > 1 {
            //group call
//            let nomalConfig: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallConfig(isVideoCall ? .groupVideoCall : .groupVoiceCall)
            let nomalConfig: ZegoUIKitPrebuiltCallConfig = isVideoCall ? ZegoUIKitPrebuiltCallConfig.groupVideoCall() : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
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
    
    func conversionInviter() -> [String: String] {
        return [
            "id": ZegoUIKit.shared.localUserInfo?.userID ?? "",
            "name": ZegoUIKit.shared.localUserInfo?.userName ?? ""
        ]
    }
        
    func buildInvitationUserList(_ callData: ZegoCallInvitationData) -> [ZegoCallPrebuiltInvitationUser]? {
        guard let invitees = callData.invitees else {
            return nil
        }
        var invitationUsers: [ZegoCallPrebuiltInvitationUser] = []
        for user in invitees {
            let invitationUser = ZegoCallPrebuiltInvitationUser.init(user, state: .wating)
            invitationUsers.append(invitationUser)
        }
        return invitationUsers
    }
}
