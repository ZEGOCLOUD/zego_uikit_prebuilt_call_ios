//
//  ZegoUIKitPrebuiltCallInvitationService.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZegoUIKit
import ZegoPluginAdapter

@objc public protocol ZegoUIKitPrebuiltCallInvitationServiceDelegate: AnyObject {
    func requireConfig(_ data: ZegoCallInvitationData) -> ZegoUIKitPrebuiltCallConfig
    
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

public class ZegoUIKitPrebuiltCallInvitationService: NSObject {
    
    public static let shared = ZegoUIKitPrebuiltCallInvitationService()
    public weak var delegate: ZegoUIKitPrebuiltCallInvitationServiceDelegate?
    
    let help = ZegoUIKitPrebuiltCallInvitationService_Help()
    var config: ZegoUIKitPrebuiltCallInvitationConfig?
    var invitationData: ZegoCallInvitationData? {
        didSet {
            if invitationData == nil {
                invitees = nil
            }
            self.isGroupCall = invitationData?.invitees?.count ?? 0 > 1 ? true : false
        }
    }
    var isGroupCall: Bool = false
    var pluginConnectState: ZegoSignalingPluginConnectionState?
    var userID: String?
    var userName: String?
    weak var callVC: UIViewController?
    
    var invitees: [ZegoCallPrebuiltInvitationUser]?
    
    var isCallInviting = false
    
    var currentCallUUID: UUID?
    
    public override init() {
        ZegoUIKit.shared.addEventHandler(self.help)
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        // Application is back in the foreground
        guard let pluginConnectState = pluginConnectState else { return }
        if pluginConnectState == .disconnected {
            guard let userID = userID,
                  let userName = userName
            else { return }
            ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
        }
    }
    
    public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String, config: ZegoUIKitPrebuiltCallInvitationConfig) {
        self.config = config
        self.userID = userID
        self.userName = userName
        
        ZegoUIKit.getSignalingPlugin().enableNotifyWhenAppRunningInBackgroundOrQuit(config.notifyWhenAppRunningInBackgroundOrQuit, isSandboxEnvironment: config.isSandboxEnvironment, certificateIndex: config.certificateIndex)
        
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.enableCustomVideoRender(enable: true)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
    }
    
    public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String) {
        self.userID = userID
        self.userName = userName
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
    }
    
    public func unInit() {
        ZegoUIKit.shared.uninit()
        ZegoUIKitSignalingPluginImpl.shared.uninit()
        ZegoUIKit.shared.enableCustomVideoRender(enable: false)
        NotificationCenter.default.removeObserver(self)
    }
    
    public func getPrebuiltCallVC()-> ZegoUIKitPrebuiltCallVC? {
        if let vc = self.callVC, vc.isKind(of: ZegoUIKitPrebuiltCallVC.classForCoder()) {
            return vc as? ZegoUIKitPrebuiltCallVC
        } else {
            return nil
        }
    }
    
    public static func setRemoteNotificationsDeviceToken(_ deviceToken: Data) {
        ZegoUIKit.getSignalingPlugin().setRemoteNotificationsDeviceToken(deviceToken)
    }
    
    public func endCall() {
        if let vc = self.callVC, vc.isKind(of: ZegoUIKitPrebuiltCallVC.classForCoder()) {
            (vc as! ZegoUIKitPrebuiltCallVC).finish()
        }
        self.invitationData = nil
    }
    
    func startIncomingRing() {
        var ringResourcePath: String? = self.config?.incomingCallRingtone
        if ringResourcePath == nil {
            let musicBundle = self.getMusicBundle()
            ringResourcePath = musicBundle?.path(forResource: "zego_incoming", ofType: "mp3")
        }
        guard let ringResourcePath = ringResourcePath else { return }
        ZegoCallAudioPlayerTool.startPlay(ringResourcePath)
    }

    func startOutgoingRing() {
        var ringResourcePath: String? = self.config?.outgoingCallRingtone
        if ringResourcePath == nil {
            let musicBundle = self.getMusicBundle()
            ringResourcePath = musicBundle?.path(forResource: "zego_outgoing", ofType: "mp3")
        }
        guard let ringResourcePath = ringResourcePath else { return }
        ZegoCallAudioPlayerTool.startPlay(ringResourcePath)
    }
    
    func getMusicBundle() -> Bundle? {
        guard let resourcePath: String = Bundle.main.resourcePath else { return nil }
        let pathComponent = "/Frameworks/ZegoUIKitPrebuiltCall.framework/ZegoUIKitPrebuiltCall.bundle"
        let bundlePath = resourcePath + pathComponent
        let bundle = Bundle(path: bundlePath)
        return bundle
    }
    
}

class ZegoUIKitPrebuiltCallInvitationService_Help: NSObject, ZegoUIKitEventHandle, ZegoUIKitPrebuiltCallVCDelegate {
    
    private let uikitEventDelegates: NSHashTable<ZegoUIKitEventHandle> = NSHashTable(options: .weakMemory)
    
    func addEventHandler(_ eventHandle: ZegoUIKitEventHandle?) {
        self.uikitEventDelegates.add(eventHandle)
    }
    
    func onInvitationReceived(_ inviter: ZegoUIKitUser, type: Int, data: String?) {
        let dataDic: Dictionary? = data?.call_convertStringToDictionary()
        let pluginInvitationID: String? = dataDic?["invitationID"] as? String
        if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID != nil && ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID != pluginInvitationID {
            guard let userID = inviter.userID else { return }
            let dataDict: [String : AnyObject] = ["reason":"busy" as AnyObject,"invitationID": pluginInvitationID as AnyObject]
            ZegoUIKitSignalingPluginImpl.shared.refuseInvitation(userID, data: dataDict.call_jsonString)
        } else {
            
            let needReportCall = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID == nil
            
            let callData = buildCallInvitationData(type: type, invitationID: pluginInvitationID, dataDict: dataDic)
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
            
            if needReportCall {
                let uuid = UUID()
                ZegoUIKitPrebuiltCallInvitationService.shared.currentCallUUID = uuid
                ZegoPluginAdapter.signalingPlugin?.reportIncomingCall(with: uuid, title: inviter.userName ?? "", hasVideo: type == 1)
            }
            
            ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting = true
            
//            _ = ZegoCallInvitationDialog.show(callData)
//            ZegoUIKitPrebuiltCallInvitationService.shared.startIncomingRing()
            
            let callUser: ZegoCallUser = getCallUser(inviter)
            
            var callees: [ZegoCallUser]? = []
            if let invitees = callData.invitees {
                for callee in invitees {
                    let calleeUser: ZegoCallUser = getCallUser(callee)
                    callees?.append(calleeUser)
                }
            }
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallReceived?(callData.callID ?? "", caller: callUser, callType: ZegoCallType.init(rawValue: type) ?? .voiceCall, callees: callees)
        }
    }
    
    func onInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {
//        let callee = getCallUser(invitee)
//        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.callID
//        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallAccepted?(callID ?? "", callee: callee)
        ZegoCallAudioPlayerTool.stopPlay()
//        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        let callUser = getCallUser(inviter)
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallCanceled?(callID ?? "", caller: callUser)
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        reportCallEnded()
    }
    
    func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
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
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            ZegoCallAudioPlayerTool.stopPlay()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        } else {
            self.checkInviteesState()
        }
    }
    
    func onInvitationTimeout(_ inviter: ZegoUIKitUser, data: String?) {
        let caller = getCallUser(inviter)
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallTimeout?(callID ?? "", caller: caller)
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        reportCallEnded()
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        var calles: [ZegoCallUser] = []
        for user in invitees {
            let callee = getCallUser(user)
            calles.append(callee)
        }
        
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallTimeout?(callID ?? "", callees: calles)
        
        if let invitationInvitees = ZegoUIKitPrebuiltCallInvitationService.shared.invitees
        {
            for invitationUser in invitationInvitees {
                for user in invitees {
                    if user.userID == invitationUser.user?.userID
                    {
                        invitationUser.state = .timeout
                    }
                }
            }
            if invitationInvitees.count <= 1 {
                ZegoCallAudioPlayerTool.stopPlay()
                ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            } else {
                self.checkInviteesState()
            }
        }
    }
    
    func onSignalingPluginConnectionState(_ params: [String : AnyObject]) {
        let state: ZegoSignalingPluginConnectionState? = params["state"] as? ZegoSignalingPluginConnectionState
        ZegoUIKitPrebuiltCallInvitationService.shared.pluginConnectState = state
    }
    
    func onHangUp(_ isHandup: Bool) {
        reportCallEnded()
        if isHandup {
            ZegoCallAudioPlayerTool.stopPlay()
            guard let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData else { return }
            var needCancel: Bool = true
            if let invitees = ZegoUIKitPrebuiltCallInvitationService.shared.invitees {
                var cancelInvitees: [String] = []
                if invitationData.inviter?.userID == ZegoUIKit.shared.localUserInfo?.userID {
                    for user in invitees {
                        if user.state == .accept {
                            needCancel = false
                        }
                        cancelInvitees.append(user.user?.userID ?? "")
                    }
                }
                if needCancel {
                    ZegoUIKitSignalingPluginImpl.shared.cancelInvitation(cancelInvitees, data: nil, callback: nil)
                }
            }
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        }
    }
    
    func onOnlySelfInRoom() {
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            ZegoMinimizeManager.shared.stopPiP()
            ZegoMinimizeManager.shared.callVC = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC?.dismiss(animated: true, completion: nil)
            reportCallEnded()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        }
    }
    
    func onCallTimeUpdate(_ duration: Int) {
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onCallTimeUpdate?(duration)
    }
    
    func getInviteeList(_ invitees: [Dictionary<String,String>]) -> [ZegoUIKitUser] {
        var inviteeList = [ZegoUIKitUser]()
        for dict in invitees {
            if let userID = dict["user_id"],
               let userName = dict["user_name"]
            {
                let user = ZegoUIKitUser.init(userID, userName)
                inviteeList.append(user)
            }
        }
        return inviteeList
    }
    
    func getCallUser(_ user: ZegoUIKitUser) -> ZegoCallUser {
        let callUser: ZegoCallUser = ZegoCallUser()
        callUser.id = user.userID
        callUser.name = user.userName
        return callUser
    }
    
    func buildCallInvitationData(type: Int, invitationID: String?, dataDict: [String: AnyObject]?) -> ZegoCallInvitationData {
        let callData = ZegoCallInvitationData()
        if let dataDict = dataDict {
            callData.callID = dataDict["call_id"] as? String
            let invitees = dataDict["invitees"] as! Array<[String : String]>
            callData.invitees = self.getInviteeList(invitees)
            callData.customData = dataDict["customData"] as? String
            
            let inviter = dataDict["inviter"] as? [String: String]
            let inviterID = inviter?["id"] ?? ""
            let inviterName = inviter?["name"] ?? ""
            callData.inviter = ZegoUIKitUser(inviterID, inviterName)
        }
        callData.invitationID = invitationID
        callData.type = ZegoInvitationType.init(rawValue: type)
        
        return callData
    }
    
    func checkInviteesState() {
        guard let inviteesList = ZegoUIKitPrebuiltCallInvitationService.shared.invitees
        else { return }
        var needClear: Bool = true
        for user in inviteesList {
            if user.state == .wating {
                needClear = false
                break
            }
        }
        if needClear {
            ZegoCallAudioPlayerTool.stopPlay()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateUserState(_ state: ZegoCallInvitationState, userList: [String]) {
        guard let invitees = ZegoUIKitPrebuiltCallInvitationService.shared.invitees
        else { return }
        for user in invitees {
            for userID in userList {
                if user.user?.userID == userID {
                    user.state = state
                }
            }
        }
    }
    
    // MARK: CallKit
    func didReceiveIncomingPush(_ uuid: UUID, invitationID: String, data: String) {
        let dict = data.call_convertStringToDictionary()
        let type = dict?["type"] as? Int ?? 0
        let newData = data.call_convertStringToDictionary()?["data"] as? String
        let dataDict = newData?.call_convertStringToDictionary()
        
        let callData = buildCallInvitationData(type: type, invitationID: invitationID, dataDict: dataDict)
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
        ZegoUIKitPrebuiltCallInvitationService.shared.currentCallUUID = uuid
        ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting = true
    }
    
    func onCallKitAnswerCall(_ action: CallKitAction) {
        let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData
        let inviterUserID = invitationData?.inviter?.userID ?? ""
        let invitationID = invitationData?.invitationID
        ZegoUIKit.getSignalingPlugin().acceptInvitation(inviterUserID, invitationID: invitationID, data: nil) { data in
            defer {
                ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting = false
                action.fulfill()
            }
            
            let errorCode = data?["code"] as? Int
            if errorCode != 0 {
                self.reportCallEnded()
                return
            }
                        
            guard let invitationData = invitationData else { return }
            var nomalConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
            if invitationData.invitees?.count ?? 0 > 1 {
                nomalConfig = invitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.groupVideoCall() : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            } else {
                nomalConfig =  invitationData.type == .videoCall ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
            }
            let config = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(invitationData) ?? nomalConfig
            let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(invitationData, config: config)
            callVC.modalPresentationStyle = .fullScreen
            callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
            currentViewController()?.present(callVC, animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallAcceptButtonPressed?()
        }
    }
    
    func onCallKitEndCall(_ action: CallKitAction) {
        if ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting {
            // refuse
            let refuseData: [String : AnyObject] = ["reason": "decline" as AnyObject, "invitationID": ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID as AnyObject]
            let inviterID = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID ?? ""
            ZegoUIKit.getSignalingPlugin().refuseInvitation(inviterID, data: refuseData.call_jsonString)
            
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallDeclineButtonPressed?()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        } else {
            // hang up
            ZegoUIKitPrebuiltCallInvitationService.shared.endCall()
            reportCallEnded()
        }
        action.fulfill()
    }
    
    func onCallKitSetMutedCall(_ action: CallKitAction) {
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else { return }
        let isOn = ZegoUIKit.shared.isMicrophoneOn(userID)
        ZegoUIKit.shared.turnMicrophoneOn(userID, isOn: !isOn)
        action.fulfill()
    }
    
    func reportCallEnded() {
        if let uuid = ZegoUIKitPrebuiltCallInvitationService.shared.currentCallUUID {
            ZegoPluginAdapter.signalingPlugin?.reportCallEnded(with: uuid, reason: 2)
        }
    }
}
