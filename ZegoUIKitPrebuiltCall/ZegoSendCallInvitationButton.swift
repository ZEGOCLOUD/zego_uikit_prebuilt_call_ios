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

@objc public class ZegoSendCallInvitationButton: UIButton {
    
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
    @objc public var callID: String?
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

    @objc required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func buttonClick() {
        if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData != nil || invitees.count == 0 { return }
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else { return }
        guard let resourceID = self.resourceID else { return }
      
        let inviteArr:[ZegoPluginCallUser] = inviteeList.map { model in
            ZegoPluginCallUser(userID: model.userID ?? "", userName:model.userName ?? "", avatar: "")
        }
        ZegoUIKitPrebuiltCallInvitationService.shared.callID = self.callID;
        ZegoUIKitPrebuiltCallInvitationService.shared.sendInvitation(inviteArr, invitationType: isVideoCall ? .videoCall : .voiceCall, timeout: 60, customerData: "", notificationConfig: ZegoSignalingPluginNotificationConfig(resourceID: resourceID, title: "", message: "")) { data in

        }
    }
    
}
