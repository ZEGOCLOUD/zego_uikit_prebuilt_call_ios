//
//  CallAcceptTipView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit
import ZegoUIKit

protocol CallAcceptTipViewDelegate: AnyObject {
//    func tipViewDeclineCall(_ userInfo: UserInfo, callType: CallType)
//    func tipViewAcceptCall(_ userInfo: UserInfo, callType: CallType)
//    func tipViewDidClik(_ userInfo: UserInfo, callType: CallType)
}

class ZegoCallInvitationDialog: UIView {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var acceptButton: ZegoAcceptInvitationButton! {
        didSet {
            acceptButton.delegate = self
        }
    }
    
    @IBOutlet weak var refuseButton: ZegoRefuseInvitationButton! {
        didSet {
            refuseButton.delegate = self
        }
    }
    
    
    @IBOutlet weak var headLabel: UILabel! {
        didSet {
            headLabel.layer.masksToBounds = true
            headLabel.layer.cornerRadius = 21
            headLabel.textAlignment = .center
        }
    }
    
    weak var delegate: CallAcceptTipViewDelegate?
//    static var showDeclineButton: Bool = true
    private var invitationData: ZegoCallInvitationData? {
        didSet {
            self.acceptButton.inviterID = invitationData?.inviter?.userID
            self.refuseButton.inviterID = invitationData?.inviter?.userID
            let refuseData: [String : AnyObject] = ["reason": "decline" as AnyObject, "invitationID": invitationData?.invitationID as AnyObject]
            self.refuseButton.data = refuseData.call_jsonString
        }
    }
    
    private var type: ZegoInvitationType = .voiceCall
    
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(viewTap))
        self.addGestureRecognizer(tapClick)
    }
    
    public static func show(_ callInvitationData: ZegoCallInvitationData) -> ZegoCallInvitationDialog {
        return showTipView(callInvitationData)
    }
    
    private static func showTipView(_ callInvitationData: ZegoCallInvitationData) -> ZegoCallInvitationDialog {
        
        let tipView: ZegoCallInvitationDialog = UINib(nibName: "ZegoCallInvitationDialog", bundle: Bundle(for: ZegoCallInvitationData.self)).instantiate(withOwner: nil, options: nil).first as! ZegoCallInvitationDialog
        let y = KeyWindow().safeAreaInsets.top
        tipView.frame = CGRect.init(x: 8, y: y + 8, width: UIScreen.main.bounds.size.width - 16, height: 80)
        tipView.invitationData = callInvitationData
        tipView.layer.masksToBounds = true
        tipView.layer.cornerRadius = 8
        tipView.type = callInvitationData.type
        tipView.setHeadUserName(callInvitationData.inviter?.userName)
        tipView.userNameLabel.text = callInvitationData.inviter?.userName
        tipView.refuseButton.isHidden = !(ZegoUIKitPrebuiltCallInvitationService.shared.config?.showDeclineButton ?? true)
        let innerText: ZegoTranslationText? = ZegoUIKitPrebuiltCallInvitationService.shared.config?.translationText
        switch callInvitationData.type {
        case .voiceCall:
//            tipView.messageLabel.text = callInvitationData.invitees?.count ?? 0 > 1 ? "Group voice call" : "Voice call"
            tipView.messageLabel.text = callInvitationData.invitees?.count ?? 0 > 1 ? innerText?.incomingGroupVoiceCallDialogMessage : innerText?.incomingVoiceCallDialogMessage
            tipView.userNameLabel.text = callInvitationData.invitees?.count ?? 0 > 1 ? String(format: innerText?.incomingGroupVoiceCallDialogTitle ?? "%@", callInvitationData.inviter?.userName ?? "") : String(format: innerText?.incomingVoiceCallDialogTitle ?? "%@", callInvitationData.inviter?.userName ?? "")
            tipView.acceptButton.icon = ZegoUIKitCallIconSetType.call_accept_icon.load()
        case .videoCall:
            tipView.messageLabel.text = callInvitationData.invitees?.count ?? 0 > 1 ? innerText?.incomingGroupVideoCallDialogMessage : innerText?.incomingVideoCallDialogMessage
            tipView.userNameLabel.text = callInvitationData.invitees?.count ?? 0 > 1 ? String(format: innerText?.incomingGroupVideoCallDialogTitle ?? "%@", callInvitationData.inviter?.userName ?? "") : String(format: innerText?.incomingVideoCallDialogTitle ?? "%@", callInvitationData.inviter?.userName ?? "")
            tipView.acceptButton.icon  = ZegoUIKitCallIconSetType.call_video_icon.load()
        }
        tipView.showTip()
        return tipView
    }
    
    private func setHeadUserName(_ userName: String?) {
        guard let userName = userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }
        
    public static func hide() {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is ZegoCallInvitationDialog {
                    let view: ZegoCallInvitationDialog = subview as! ZegoCallInvitationDialog
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func showTip()  {
        KeyWindow().addSubview(self)
    }
    
    @objc func viewTap() {
        let vc = UINib.init(nibName: "ZegoUIKitPrebuiltCallWaitingVC", bundle: Bundle(for: ZegoUIKitPrebuiltCallWaitingVC.self)).instantiate(withOwner: nil, options: nil).first as! ZegoUIKitPrebuiltCallWaitingVC
        vc.isInviter = false
        vc.callInvitationData = self.invitationData
        vc.modalPresentationStyle = .fullScreen
        currentViewController()?.present(vc, animated: true, completion: nil)
        vc.showDeclineButton = ZegoUIKitPrebuiltCallInvitationService.shared.config?.showDeclineButton ?? true
        ZegoCallInvitationDialog.hide()
    }
    
}

extension ZegoCallInvitationDialog: ZegoAcceptInvitationButtonDelegate {
    public func onAcceptInvitationButtonClick() {
        guard let invitationData = invitationData else {
            return
        }
        var normalConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
        if invitationData.invitees?.count ?? 0 > 1 {
            //group call
//            nomalConfig = ZegoUIKitPrebuiltCallConfig(invitationData.type == .videoCall ? .groupVideoCall : .groupVoiceCall)
            normalConfig = invitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.groupVideoCall() : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
        } else {
            //one on one call
//            nomalConfig = ZegoUIKitPrebuiltCallConfig(invitationData.type == .videoCall ? .oneOnOneVideoCall : .oneOnOneVoiceCall)
            normalConfig =  invitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
        }
        let config = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(invitationData) ?? normalConfig
        let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(invitationData, config: config)
        callVC.modalPresentationStyle = .fullScreen
        callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
        currentViewController()?.present(callVC, animated: true, completion: nil)
        ZegoCallInvitationDialog.hide()
        ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallAcceptButtonPressed?()
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        
    }
}

extension ZegoCallInvitationDialog: ZegoRefuseInvitationButtonDelegate {
    func onRefuseInvitationButtonClick() {
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallDeclineButtonPressed?()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoCallInvitationDialog.hide()
    }
}
