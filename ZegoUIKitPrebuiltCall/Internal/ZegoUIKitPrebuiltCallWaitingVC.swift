//
//  ZegoUIKitPrebuiltCallWaitingVC.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZegoUIKit

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
    
    @IBOutlet weak var declineButtonLabel: UILabel!
    
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
    
    @IBOutlet weak var acceptButtonLabel: UILabel!
    
    @IBOutlet weak var switchFacingCameraButton: ZegoSwitchCameraButton! {
        didSet {
            switchFacingCameraButton.iconBackFacingCamera = ZegoUIKitCallIconSetType.icon_camera_overturn.load()
            switchFacingCameraButton.iconFrontFacingCamera = ZegoUIKitCallIconSetType.icon_camera_overturn.load()
        }
    }
    
    @IBOutlet weak var userAvatarView: UIImageView!
    
    var callInvitationData: ZegoCallInvitationData? {
        didSet {
            let config = ZegoUIKitPrebuiltCallInvitationService.shared.config
            var userNameTextFormat = "%@"
            
            if !self.isInviter {
                if callInvitationData?.type == .videoCall {
                    userNameTextFormat = callInvitationData?.invitees?.count ?? 0 > 1 ? config?.translationText.incomingGroupVideoCallPageTitle ?? "%@" : config?.translationText.incomingVideoCallPageTitle ?? "%@"
                } else {
                    userNameTextFormat = callInvitationData?.invitees?.count ?? 0 > 1 ? config?.translationText.incomingGroupVoiceCallPageTitle ?? "@" : config?.translationText.incomingVoiceCallPageTitle ?? "%@"
                }
                self.userNameLabel.text = String(format: userNameTextFormat , callInvitationData?.inviter?.userName ?? "")
                self.setHeadUserName(callInvitationData?.inviter?.userName)
                self.callStatusLabel.text = callInvitationData?.invitees?.count ?? 0 > 1 ? (callInvitationData?.type == .videoCall ? config?.translationText.incomingGroupVideoCallPageMessage : config?.translationText.incomingGroupVoiceCallPageMessage) : (callInvitationData?.type == .videoCall ? config?.translationText.incomingVideoCallPageMessage : config?.translationText.incomingVoiceCallPageMessage)
            } else {
                //self.userNameLabel.text = callInvitationData?.invitees?.first?.userName
                userNameTextFormat = callInvitationData?.type == .videoCall ? config?.translationText.outgoingVideoCallPageTitle ?? "%@" : config?.translationText.outgoingVoiceCallPageTitle ?? "%@"
                self.userNameLabel.text = String(format: userNameTextFormat, callInvitationData?.invitees?.first?.userName ?? "")
                self.setHeadUserName(callInvitationData?.invitees?.first?.userName)
                self.callStatusLabel.text = callInvitationData?.type == .videoCall ? config?.translationText.outgoingVideoCallPageMessage : config?.translationText.outgoingVoiceCallPageMessage
            }
            
            if let invitees = callInvitationData?.invitees {
                for user in invitees {
                    guard let userID = user.userID else { return }
                    self.cancelInviationButton.invitees.append(userID)
                }
            }
            
            let refuseData: [String : AnyObject] = ["reason": "decline" as AnyObject, "invitationID": callInvitationData?.invitationID as AnyObject]
            declineButton.data = refuseData.call_jsonString
            
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
                if let videoConfig = ZegoUIKitPrebuiltCallInvitationService.shared.config?.videoConfig {
                    ZegoUIKit.shared.setVideoConfig(config: videoConfig.resolution)
                }
                videoPreviewView.userID = callInvitationData?.inviter?.userID
                videoPreviewView.isHidden = false
                switchFacingCameraButton.isHidden = false
            } else {
                videoPreviewView.isHidden = true
                switchFacingCameraButton.isHidden = true
            }
            self.acceptButtonLabel.text = config?.translationText.incomingCallPageAcceptButton
            self.declineButtonLabel.text = config?.translationText.incomingCallPageDeclineButton
            if let inviter = callInvitationData?.inviter {
                let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: inviter) ?? "") as String
                if userAvatar != "" {
                    loadImage(imageUrl: (userAvatar))
                    videoPreviewView.avatarUrl = userAvatar
                }
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
    
    var showDeclineButton: Bool = true {
        didSet {
            if showDeclineButton == false {
                self.declineView.isHidden = true
                let acceptRect: CGRect = self.acceptView.frame
                let x: CGFloat = (self.view.frame.width - acceptRect.width)/2
                self.trailingConstraint.constant = x
            }
        }
    }
    
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ZegoUIKit.shared.addEventHandler(self.help)
        self.help.waitingVC = self
    }
    
    private func loadImage(imageUrl:String) {
        let url = URL(string: imageUrl)
        let session = URLSession.shared
        let task = session.dataTask(with: url!) { (data, response, error) in
            if let error = error {
                print("加载图片出错: \(error)")
                return
            }
            if let data = data {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {[weak self] in
                        guard let self = self else { return }
                        self.userAvatarView.isHidden = false
                        self.headLabel.isHidden = true
                        self.userAvatarView.image = image
                    }
                }
            }
        }
        task.resume()
        
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
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallDeclineButtonPressed?()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        ZegoCallAudioPlayerTool.stopPlay()
        waitingVC?.dismiss(animated: true, completion: nil)
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let reportData = ["call_id": String(describing: ZegoUIKitPrebuiltCallInvitationService.shared.callID) as AnyObject,
                          "action": "refuse" as AnyObject,
                          "app_state":  appState as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: reportData)

    }
    
    func onAcceptInvitationButtonClick() {
        ZegoCallAudioPlayerTool.stopPlay()
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let reportData = ["call_id": String(describing: ZegoUIKitPrebuiltCallInvitationService.shared.callID) as AnyObject,
                          "action": "accept" as AnyObject,
                          "app_state":  appState as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: reportData)
        
        guard let callInvitationData = self.waitingVC?.callInvitationData else { return }
        self.waitingVC?.dismiss(animated: false, completion: {
            var normalConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            if callInvitationData.invitees?.count ?? 0 > 1 {
                //group call
                normalConfig = callInvitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.groupVideoCall() : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            } else {
                //one on one call
                normalConfig =  callInvitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() :  ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
            }
            let config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(callInvitationData) ?? normalConfig
            let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(callInvitationData, config: config)
            callVC.modalPresentationStyle = .fullScreen
            callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
            currentViewController()?.present(callVC, animated: false, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallAcceptButtonPressed?()
        })
    }
    
    func onCancelInvitationButtonClick() {
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallCancelButtonPressed?()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        ZegoCallAudioPlayerTool.stopPlay()
        waitingVC?.dismiss(animated: true, completion: nil)
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let reportData = ["call_id": String(describing: ZegoUIKitPrebuiltCallInvitationService.shared.callID) as AnyObject,
                          "action": "cancel" as AnyObject,
                          "app_state":  appState as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: reportData)
    }
    
    func onInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {

        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            guard let callInvitationData = self.waitingVC?.callInvitationData else { return }
            self.waitingVC?.dismiss(animated: false, completion: {
                ZegoCallAudioPlayerTool.stopPlay()
                var normalConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                if callInvitationData.invitees?.count ?? 0 > 1 {
                    //group call
                    normalConfig = callInvitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.groupVideoCall() : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
                } else {
                    //one on one call
                    normalConfig =  callInvitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() :  ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
                }
                let config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(callInvitationData) ?? normalConfig
                
                let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(callInvitationData, config: config)
                callVC.modalPresentationStyle = .fullScreen
                callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
                currentViewController()?.present(callVC, animated: false, completion: nil)
                ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
                let callee = self.getCallUser(invitee)
                let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallAccepted?(callID ?? "", callee: callee)
                ZegoUIKitPrebuiltCallInvitationService.shared.state = .accept
            })
        }
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        if self.waitingVC?.callInvitationData?.inviter?.userID == inviter.userID {
            self.waitingVC?.dismiss(animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        }
    }
    
    func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
      
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let refuseData = ["call_id": ZegoUIKitPrebuiltCallInvitationService.shared.callID as AnyObject,
                          "invitee": invitee.userID as AnyObject,
                          "app_state":  appState as AnyObject,
                          "action": "refused" as AnyObject,
                          "is_group_call" : (ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall == true ? 1 : 0)  as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callInvitationResponseReportString, paramsDict: refuseData)
        
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            let callee = getCallUser(invitee)
            let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
            let callData: [String: AnyObject]? = data?.call_convertStringToDictionary()
            if let callData = callData, callData["reason"] as? String ?? "" == "busy" {
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallRejectedCauseBusy?(callID ?? "", callee: callee)
            } else {
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallDeclined?(callID ?? "", callee: callee)
            }
            
            if let invitationInvitees = ZegoUIKitPrebuiltCallInvitationService.shared.invitees
            {
                for invitationUser in invitationInvitees {
                    if invitee.userID == invitationUser.user?.userID {
                        invitationUser.state = .refuse
                    }
                }
            }
            self.waitingVC?.dismiss(animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
            ZegoCallAudioPlayerTool.stopPlay()
        }
    }
    
    func onInvitationTimeout(_ inviter: ZegoUIKitUser, data: String?) {
        if inviter.userID == self.waitingVC?.callInvitationData?.inviter?.userID {
            
            let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
            let caller = getCallUser(inviter)
            if caller.id == nil {
              caller.id = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID
            }
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallTimeout?(callID ?? "", caller: caller)
            
            self.waitingVC?.dismiss(animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
            ZegoCallAudioPlayerTool.stopPlay()
        }
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        let curInvitee = self.waitingVC?.callInvitationData?.invitees?.first
        let timeoutInvitee = invitees.first
        if curInvitee?.userID == timeoutInvitee?.userID {
            
            let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
           
            var callees: [ZegoCallUser]? = []
                for callee in invitees {
                    let calleeUser: ZegoCallUser = getCallUser(callee)
                    callees?.append(calleeUser)
                }
            
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallTimeout?(callID ?? "", callees: callees ?? [])

            
            self.waitingVC?.dismiss(animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        }
    }
    
    func getCallUser(_ user: ZegoUIKitUser) -> ZegoCallUser {
        let callUser: ZegoCallUser = ZegoCallUser()
        callUser.id = user.userID
        callUser.name = user.userName
        return callUser
    }
}
