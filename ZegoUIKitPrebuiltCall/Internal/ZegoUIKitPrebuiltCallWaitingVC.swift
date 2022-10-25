//
//  ZegoUIKitPrebuiltCallWaitingVC.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZegoUIKitSDK

class ZegoUIKitPrebuiltCallWaitingVC: UIViewController {
    
    private let help: ZegoUIKitPrebuiltCallWaitingVC_Help = ZegoUIKitPrebuiltCallWaitingVC_Help()
    
    @IBOutlet weak var backgroundImage: UIImageView! {
        didSet {
            backgroundImage.image = ZegoUIKitCallIconSetType.call_waiting_bg.load()
        }
    }
    
    @IBOutlet weak var videoPreviewView: ZegoAudioVideoView! {
        didSet {
            if self.isInviter && self.callInvitationData?.type == .videoCall {
                videoPreviewView.userID = self.callInvitationData?.inviter?.userID
            }
        }
    }
    
    @IBOutlet weak var headLabel: UILabel! {
        didSet {
            headLabel.layer.masksToBounds = true
            headLabel.layer.cornerRadius = 50
            if !self.isInviter {
                self.setHeadUserName(callInvitationData?.inviter?.userName)
            } else {
                
            }
        }
    }
    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            userNameLabel.text = callInvitationData?.inviter?.userName
        }
    }
    @IBOutlet weak var callStatusLabel: UILabel!
    
    @IBOutlet weak var declineView: UIView! {
        didSet {
            declineView.isHidden = self.isInviter
        }
    }
    @IBOutlet weak var acceptView: UIView! {
        didSet {
            acceptView.isHidden = self.isInviter
        }
    }
    
    @IBOutlet weak var declineButton: ZegoRefuseInvitationButton! {
        didSet {
            declineButton.delegate = self.help
            if let inviter = callInvitationData?.inviter {
                declineButton.inviterID = inviter.userID
            }
        }
    }
    
    @IBOutlet weak var cancelInviationButton: ZegoCancelInvitationButton! {
        didSet {
            cancelInviationButton.delegate = self.help
            cancelInviationButton.isHidden = !self.isInviter
            if let invitees = callInvitationData?.invitees {
                for user in invitees {
                    guard let userID = user.userID else { return }
                    cancelInviationButton.invitees.append(userID)
                }
            }
            
        }
    }
    
    @IBOutlet weak var acceptButton: ZegoAcceptInvitationButton! {
        didSet {
            acceptButton.delegate = self.help
            if let inviter = callInvitationData?.inviter {
                acceptButton.inviterID = inviter.userID
            }
        }
    }
    
    @IBOutlet weak var switchFacingCameraButton: ZegoSwitchCameraButton! {
        didSet {
            switchFacingCameraButton.iconBackFacingCamera = ZegoUIKitCallIconSetType.icon_camera_overturn.load()
            switchFacingCameraButton.iconFrontFacingCamera = ZegoUIKitCallIconSetType.icon_camera_overturn.load()
        }
    }
    
    
    var callInvitationData: ZegoCallInvitationData? {
        didSet {
            if !self.isInviter {
                self.userNameLabel.text = callInvitationData?.inviter?.userName
                self.setHeadUserName(callInvitationData?.inviter?.userName)
            } else {
                self.userNameLabel.text = callInvitationData?.invitees?.first?.userName
                self.setHeadUserName(callInvitationData?.invitees?.first?.userName)
            }
            if let invitees = callInvitationData?.invitees {
                for user in invitees {
                    guard let userID = user.userID else { return }
                    self.cancelInviationButton.invitees.append(userID)
                }
            }
            
            let refuseData: [String : AnyObject] = ["reason": "decline" as AnyObject, "invitationID": callInvitationData?.invitationID as AnyObject]
            declineButton.data = refuseData.jsonString
            
            if let inviter = callInvitationData?.inviter {
                declineButton.inviterID = inviter.userID
                acceptButton.inviterID = inviter.userID
                
                if callInvitationData?.type == .videoCall {
                    acceptButton.icon = ZegoUIKitCallIconSetType.call_video_icon.load()
                } else {
                    acceptButton.icon = ZegoUIKitCallIconSetType.call_accept_icon.load()
                }
            }
            if self.isInviter && callInvitationData?.type == .videoCall {
                videoPreviewView.userID = callInvitationData?.inviter?.userID
                videoPreviewView.isHidden = false
                switchFacingCameraButton.isHidden = false
            } else {
                videoPreviewView.isHidden = true
                switchFacingCameraButton.isHidden = true
            }
        }
    }
    
    var isInviter: Bool = false {
        didSet {
            if isInviter {
                self.cancelInviationButton.isHidden = false
                self.acceptView.isHidden = true
                self.declineView.isHidden = true
            } else {
                self.cancelInviationButton.isHidden = true
                self.acceptView.isHidden = false
                self.declineView.isHidden = false
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoUIKit.shared.addEventHandler(self.help)
        self.help.waitingVC = self
    }
    
    private func setHeadUserName(_ userName: String?) {
        guard let userName = userName else { return }
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
    }

}

class ZegoUIKitPrebuiltCallWaitingVC_Help: NSObject, ZegoAcceptInvitationButtonDelegate, ZegoCancelInvitationButtonDelegate, ZegoRefuseInvitationButtonDelegate, ZegoUIKitEventHandle {
    
    weak var waitingVC: ZegoUIKitPrebuiltCallWaitingVC?
    
    func onRefuseInvitationButtonClick() {
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
        ZegoCallAudioPlayerTool.stopPlay()
        waitingVC?.dismiss(animated: true, completion: nil)
    }
    
    func onAcceptInvitationButtonClick() {
        ZegoCallAudioPlayerTool.stopPlay()
        guard let callInvitationData = self.waitingVC?.callInvitationData else { return }
        self.waitingVC?.dismiss(animated: false, completion: {
            var nomalConfig = ZegoUIKitPrebuiltCallConfig(.oneOnOneVideoCall)
            if callInvitationData.invitees?.count ?? 0 > 1 {
                //group call
                nomalConfig = ZegoUIKitPrebuiltCallConfig(callInvitationData.type == .videoCall ? .groupVideoCall : .groupVoiceCall)
            } else {
                //one on one call
                nomalConfig = ZegoUIKitPrebuiltCallConfig(callInvitationData.type == .videoCall ? .oneOnOneVideoCall : .oneOnOneVoiceCall)
            }
            let config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(callInvitationData) ?? nomalConfig
            let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(callInvitationData, config: config)
            callVC.modalPresentationStyle = .fullScreen
            callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
            currentViewController()?.present(callVC, animated: false, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
        })
    }
    
    func onCancelInvitationButtonClick() {
        ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoCallAudioPlayerTool.stopPlay()
        waitingVC?.dismiss(animated: true, completion: nil)
    }
    
    func onInvitationAccepted(_ invitee: ZegoUIkitUser, data: String?) {
        guard let callInvitationData = self.waitingVC?.callInvitationData else { return }
        self.waitingVC?.dismiss(animated: false, completion: {
            let config = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(callInvitationData)
            let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(callInvitationData, config: config)
            callVC.modalPresentationStyle = .fullScreen
            callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
            currentViewController()?.present(callVC, animated: false, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
        })
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIkitUser, data: String?) {
        if self.waitingVC?.callInvitationData?.inviter?.userID == inviter.userID {
            self.waitingVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func onInvitationRefused(_ invitee: ZegoUIkitUser, data: String?) {
        let curInvitee = self.waitingVC?.callInvitationData?.invitees?.first
        if curInvitee?.userID == invitee.userID {
            self.waitingVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func onInvitationTimeout(_ inviter: ZegoUIkitUser, data: String?) {
        if inviter.userID == self.waitingVC?.callInvitationData?.inviter?.userID {
            self.waitingVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIkitUser], data: String?) {
        let curInvitee = self.waitingVC?.callInvitationData?.invitees?.first
        let timeoutInvitee = invitees.first
        if curInvitee?.userID == timeoutInvitee?.userID {
            self.waitingVC?.dismiss(animated: true, completion: nil)
        }
    }
    
}
