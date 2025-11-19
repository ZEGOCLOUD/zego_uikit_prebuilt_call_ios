//
//  ZegoUIKitPrebuiltCallInvitationService.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import CallKit
import ZegoUIKit
import ZegoPluginAdapter
import ZegoPrebuiltLog

@objc public class ZegoUIKitPrebuiltCallInvitationService: NSObject {
    
    @objc public static let shared = ZegoUIKitPrebuiltCallInvitationService()

    @objc public weak var delegate: ZegoUIKitPrebuiltCallInvitationServiceDelegate? {
        didSet {
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][delegate] didSet:\(String(describing: delegate))")
        }
    }

    @objc public weak var callVCDelegate: ZegoUIKitPrebuiltCallVCDelegate? {
        didSet {
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][callVCDelegate] didSet:\(String(describing: callVCDelegate))")
        }
    }
    
    let help = ZegoUIKitPrebuiltCallInvitationService_Help()
    var config: ZegoUIKitPrebuiltCallInvitationConfig?
    var invitationData: ZegoCallInvitationData? {
        didSet {
            if invitationData == nil {
                invitees = nil
                state = .normal
                callID = nil
                ZegoCallAudioPlayerTool.stopPlay()
            }
            self.isGroupCall = invitationData?.invitees?.count ?? 0 > 1 ? true : false
        }
    }
    var isGroupCall: Bool = false
    var pluginConnectState: ZegoSignalingPluginConnectionState?
    var userID: String?
    // 加入RTC 房间的ID，不是 zim 的callID
    @objc public var callID: String?
    var userName: String?
    weak var callVC: UIViewController? {
        didSet {
            if callVC is ZegoUIKitPrebuiltCallWaitingVC {
                state = .waiting
            } else if callVC is ZegoUIKitPrebuiltCallVC {
                state = .accept
            }
        }
    }
    
    var invitees: [ZegoCallPrebuiltInvitationUser]?
    
    var isCallInviting = false
    
    var currentCallUUID: UUID?
    
    var inviteIDArray: [String] = []
    
    var inviteeList: [ZegoUIKitUser] = []
    
    var state: ZegoCallInvitationState = .normal
    public override init() {
        ZegoUIKit.shared.addEventHandler(self.help)
        ZegoPluginAdapter.callkitPlugin?.registerPluginEventHandler(self.help)
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
    
    private func startCall(_ callData: ZegoCallInvitationData, isVideoCall: Bool, source: String) {
        
        let reportData = ["call_id": callData.callID as AnyObject,
                          "room_id": callData.callID as AnyObject,
                          "source": source as AnyObject,
                          "is_video_call": (isVideoCall == true ? 1 : 0) as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callStartCallReportString, paramsDict: reportData)
        
        if isVideoCall { ZegoUIKit.shared.turnCameraOn(ZegoUIKit.shared.localUserInfo?.userID ?? "", isOn: true) }
        if let invitees = self.invitees {
            if invitees.count > 1 {
                //group call
                //            let normalConfig: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallConfig(isVideoCall ? .groupVideoCall : .groupVoiceCall)
                ZegoUIKit.shared.removeParticipantDic()
                let normalConfig: ZegoUIKitPrebuiltCallConfig = isVideoCall ? ZegoUIKitPrebuiltCallConfig.groupVideoCall() : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
                let config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.requireConfig(callData) ?? normalConfig
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
    }
    
  func conversionInvitees(list:[ZegoUIKitUser]) -> [Dictionary<String,String>] {
        var newInvitees: [Dictionary<String,String>] = []
        for user in list {
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
            let invitationUser = ZegoCallPrebuiltInvitationUser.init(user, state: .waiting)
            invitationUsers.append(invitationUser)
        }
        return invitationUsers
    }
}

extension ZegoUIKitPrebuiltCallInvitationService: CallInvitationServiceApi {
    @objc public func sendInRoomCommand(_ command: String, toUserIDs: [String], callback: ZegoSendInRoomCommandCallback?) {
        ZegoUIKit.shared.sendInRoomCommand(command: command, toUserIDs: toUserIDs, callback: callback)
    }
    
    @objc public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String, config: ZegoUIKitPrebuiltCallInvitationConfig, callback: ZegoCallInvitationInitCallback?)
    {
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] initWithAppID:\(appID), userID:\(userID), userName:\(userName), config:...")

        let bundleVerMap = logComponentsVersion()

        var reportData: [String: String] = ["user_id": userID,
                     "platform": "iOS",
                     "platform_version": UIDevice.current.systemVersion]
        reportData.merge(bundleVerMap) { current, new in
            return new
        }
        ReportUtil.sharedInstance().create(withAppID: appID, signOrToken: appSign, commonParams: reportData)
        
        // check params
        if (appSign.isEmpty) {
            let message = "appSign cannot be empty."
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] error, message: \(message)")
            callback?(-1, message)
            return
        }
        if (userID.isEmpty) {
            let message = "userID cannot be empty."
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] error, message: \(message)")
            callback?(-1, message)
            return
        }
        if (userName.isEmpty) {
            let message = "userName cannot be empty."
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] error, message: \(message)")
            callback?(-1, message)
            return
        }

        self.config = config
        self.userID = userID
        self.userName = userName
        // Update UIKit Language
        let zegoLanguage: ZegoUIKitLanguage = config.translationText.getLanguage()
        let zegoUIKitLanguage = ZegoUIKitLanguage(rawValue: zegoLanguage.rawValue)!
        ZegoUIKitTranslationTextConfig.shared.translationText = ZegoUIKitTranslationText(language: zegoUIKitLanguage);
      
        ZegoUIKit.getSignalingPlugin().enableNotifyWhenAppRunningInBackgroundOrQuit(config.notifyWhenAppRunningInBackgroundOrQuit, isSandboxEnvironment: config.isSandboxEnvironment, certificateIndex: config.certificateIndex)
        
        if config.notifyWhenAppRunningInBackgroundOrQuit {
//            try to enable voip if import
            ZegoPluginAdapter.callkitPlugin?.enableVoIP(isSandboxEnvironment: config.isSandboxEnvironment)
        }
        
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign, scenario: UInt(config.scenario.rawValue))
        ZegoUIKit.shared.enableCustomVideoRender(enable: true)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
        ReportUtil.sharedInstance().reportEvent(callInitReportString, paramsDict: [:])
        
        callback?(0, "")
    }
    
    @objc public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String, callback: ZegoCallInvitationInitCallback?) {
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] initWithAppID:\(appID), userID:\(userID), userName:\(userName)")
        
        let bundleVerMap = logComponentsVersion()

        var reportData: [String: String] = ["user_id": userID,
                     "platform": "iOS",
                     "platform_version": UIDevice.current.systemVersion]
        reportData.merge(bundleVerMap) { current, new in
            return new
        }
        ReportUtil.sharedInstance().create(withAppID: appID, signOrToken: appSign, commonParams: reportData)
        
        // check params
        if (appSign.isEmpty) {
            let message = "appSign cannot be empty."
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] error, message: \(message)")
            callback?(-1, message)
            return
        }
        if (userID.isEmpty) {
            let message = "userID cannot be empty."
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] error, message: \(message)")
            callback?(-1, message)
            return
        }
        if (userName.isEmpty) {
            let message = "userName cannot be empty."
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][initWithAppID] error, message: \(message)")
            callback?(-1, message)
            return
        }
        
        self.userID = userID
        self.userName = userName
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
        ReportUtil.sharedInstance().reportEvent(callInitReportString, paramsDict: [:])

        callback?(0, "")
    }
    
    @objc public func sendInvitation(_ invitees: [ZegoPluginCallUser], invitationType: ZegoPluginCallType,timeout: Int, customerData: String?, notificationConfig: ZegoSignalingPluginNotificationConfig,source: String = "button", callback: PluginCallBack?) {
        inviteIDArray = []
        if invitees.count == 0 { return }
        guard (ZegoUIKit.shared.localUserInfo?.userID) != nil else { return }
        if ZegoUIKitPrebuiltCallInvitationService.shared.pluginConnectState == .disconnected {
            
            ReportUtil.sharedInstance().reportEvent(callLoginReportString, paramsDict: [:])
            ZegoUIKitSignalingPluginImpl.shared.login(self.userID ?? "", userName: self.userName ?? "") { [self] data in
                let code = data?["code"] as! Int
                if code == 0 {
                    sendInvitationLogined(invitees, invitationType: invitationType, timeout: timeout, customerData: customerData, notificationConfig: notificationConfig, callback: callback)
                } else {
                    state = .normal
                    callback?(data)
                }
            }
        } else {
            sendInvitationLogined(invitees, invitationType: invitationType, timeout: timeout, customerData: customerData, notificationConfig: notificationConfig, callback: callback)
        }
        
    }
    
    private func sendInvitationLogined(_ invitees: [ZegoPluginCallUser], invitationType: ZegoPluginCallType,timeout: Int, customerData: String?, notificationConfig: ZegoSignalingPluginNotificationConfig, source: String = "button", callback: PluginCallBack?) {
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else {
            self.state = .normal
            return
        }

        let callData = ZegoCallInvitationData()
        if (self.callID != nil) {
            callData.callID = self.callID;
        }else{
            callData.callID = String(format: "call_%@_%d", userID,getTimeStamp())
        }


        callData.invitees = invitees.map { model in
            inviteIDArray.append(model.userID)
            return ZegoUIKitUser(model.userID, model.userName)
        }
        self.inviteeList = callData.invitees!
        callData.inviter = ZegoUIKit.shared.localUserInfo
        callData.type = (invitationType == .videoCall) ? .videoCall : .voiceCall
        let data = ["call_id": callData.callID as AnyObject,
                    "invitees": self.conversionInvitees(list: callData.invitees!) as AnyObject,
                     "inviter": self.conversionInviter() as AnyObject,
                     "custom_data": customerData as AnyObject].call_jsonString
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
        ZegoUIKitPrebuiltCallInvitationService.shared.invitees = buildInvitationUserList(callData)
        
        let config: ZegoUIKitPrebuiltCallInvitationConfig? = ZegoUIKitPrebuiltCallInvitationService.shared.config
        
        notificationConfig.title = notificationConfig.title.count > 0 ? notificationConfig.title : callData.type == .videoCall ? String(format: config?.translationText.incomingVideoCallDialogTitle ?? "%@", callData.inviter?.userName ?? "") : String(format: config?.translationText.incomingVoiceCallDialogTitle ?? "%@", callData.inviter?.userName ?? "")
        
        notificationConfig.message = notificationConfig.message.count > 0 ? notificationConfig.message : (callData.invitees?.count ?? 0 > 1 ? (callData.type == .videoCall ? config?.translationText.incomingGroupVideoCallDialogMessage : config?.translationText.incomingGroupVoiceCallDialogMessage) : (callData.type == .videoCall ? config?.translationText.incomingVideoCallDialogMessage : config?.translationText.incomingVoiceCallDialogMessage))!
        if !(currentViewController() is ZegoUIKitPrebuiltCallWaitingVC || currentViewController() is ZegoUIKitPrebuiltCallVC) {
            if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil {
                self.state = .normal
            }
        }
        if self.state != .normal {
            print("data:\(String(describing: ZegoUIKitPrebuiltCallInvitationService.shared.invitationData))")
            print("[log] 不在正常状态下:\(self.state)")
            return
        }
        state = .waiting
        ZegoUIKitSignalingPluginImpl.shared.sendInvitation(self.inviteIDArray, timeout: UInt32(timeout), type: invitationType.rawValue, data: data, notificationConfig: notificationConfig) { data in
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
                    if errorInvitees.count == self.inviteIDArray.count {
                        //all invitees offline
                        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
                        self.callID = nil
                    } else {
                        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID = data["callID"] as? String
                        self.startCall(callData,isVideoCall:(invitationType == .videoCall) ? true : false,source:  source)
                    }
                    ZegoUIKitPrebuiltCallInvitationService.shared.help.checkInviteesState()
                } else {
                    self.startCall(callData,isVideoCall:(invitationType == .videoCall) ? true : false, source: source)
                }
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onPressed?(code, errorMessage: message, errorInvitees: errorUsers as? [ZegoCallUser])
            } else {
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onPressed?(code, errorMessage: message, errorInvitees: errorUsers as? [ZegoCallUser])
                ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
                self.callID = nil
            }
            callback?(data)
        }
    }
    
    @objc public func sendInvitationNoStartCall(_ invitees: [ZegoPluginCallUser],
                                                invitationType: ZegoPluginCallType,
                                                timeout: Int,
                                                customerData: String?,
                                                notificationConfig: ZegoSignalingPluginNotificationConfig,
                                                source: String = "button",
                                                callback: PluginCallBack?) {
        
        if  invitees.count == 0 { return }
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else { return }
        let callData = ZegoCallInvitationData()
        if (self.callID != nil) {
            callData.callID = self.callID;
        }else{
            callData.callID = String(format: "call_%@_%d", userID,getTimeStamp())
        }

        callData.invitees = invitees.map { model in
            inviteIDArray.append(model.userID)
            return ZegoUIKitUser(model.userID, model.userName)
        }
        self.inviteeList = callData.invitees!
        callData.inviter = ZegoUIKit.shared.localUserInfo
        callData.type = (invitationType == .videoCall) ? .videoCall : .voiceCall
        let data = ["call_id": callData.callID as AnyObject,
                    "invitees": self.conversionInvitees(list: callData.invitees!) as AnyObject,
                     "inviter": self.conversionInviter() as AnyObject,
                     "custom_data": customerData as AnyObject].call_jsonString
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
        ZegoUIKitPrebuiltCallInvitationService.shared.invitees = buildInvitationUserList(callData)
        
        let config: ZegoUIKitPrebuiltCallInvitationConfig? = ZegoUIKitPrebuiltCallInvitationService.shared.config
        
        notificationConfig.title = notificationConfig.title.count > 0 ? notificationConfig.title : callData.type == .videoCall ? String(format: config?.translationText.incomingVideoCallDialogTitle ?? "%@", callData.inviter?.userName ?? "") : String(format: config?.translationText.incomingVoiceCallDialogTitle ?? "%@", callData.inviter?.userName ?? "")
        
        notificationConfig.message = notificationConfig.message.count > 0 ? notificationConfig.message : (callData.invitees?.count ?? 0 > 1 ? (callData.type == .videoCall ? config?.translationText.incomingGroupVideoCallDialogMessage : config?.translationText.incomingGroupVoiceCallDialogMessage) : (callData.type == .videoCall ? config?.translationText.incomingVideoCallDialogMessage : config?.translationText.incomingVoiceCallDialogMessage))!
            
        
        if !(currentViewController() is ZegoUIKitPrebuiltCallWaitingVC || currentViewController() is ZegoUIKitPrebuiltCallVC) {
            if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil {
                self.state = .normal
            }
        }
        if self.state != .normal {
            print("[log] 已经受到邀请")
            return
        }
        state = .waiting
        ZegoUIKitSignalingPluginImpl.shared.sendInvitation(self.inviteIDArray, timeout: UInt32(timeout), type: invitationType.rawValue, data: data, notificationConfig: notificationConfig) { data in
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
                    if errorInvitees.count == self.inviteIDArray.count {
                        //all invitees offline
                        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
                        self.callID = nil
                    } else {
                        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID = data["callID"] as? String
                    }
                    ZegoUIKitPrebuiltCallInvitationService.shared.help.checkInviteesState()
                } else {
                }
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onPressed?(code, errorMessage: message, errorInvitees: errorUsers as? [ZegoCallUser])
            } else {
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onPressed?(code, errorMessage: message, errorInvitees: errorUsers as? [ZegoCallUser])
                ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
                self.callID = nil
            }
            callback?(data)
        }
    }
    
    
    @objc public func unInit() {
        ZegoPrebuiltLog.shared.write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][unInit]")

        ZegoUIKit.shared.uninit()
        ZegoUIKitSignalingPluginImpl.shared.loginOut()
        ZegoUIKitSignalingPluginImpl.shared.uninit()
        ZegoUIKit.shared.enableCustomVideoRender(enable: false)
        NotificationCenter.default.removeObserver(self)
        ReportUtil.sharedInstance().reportEvent(callUnInitReportString, paramsDict: [:])
    }

    @objc public func getPrebuiltCallVC()-> ZegoUIKitPrebuiltCallVC? {
        if let vc = self.callVC, vc.isKind(of: ZegoUIKitPrebuiltCallVC.classForCoder()) {
            return vc as? ZegoUIKitPrebuiltCallVC
        } else {
            return nil
        }
    }
    

    @objc public static func setRemoteNotificationsDeviceToken(_ deviceToken: Data) {
        ZegoUIKit.getSignalingPlugin().setRemoteNotificationsDeviceToken(deviceToken)
    }
    
    
    @objc public func endCall() {
        if let vc = self.callVC, vc.isKind(of: ZegoUIKitPrebuiltCallVC.classForCoder()) {
            (vc as! ZegoUIKitPrebuiltCallVC).finish()
        }
        let endEvent:ZegoCallEndEvent = ZegoCallEndEvent()
        endEvent.reason = .localHangUp
        endEvent.kickerUserID = ZegoUIKitPrebuiltCallInvitationService.shared.userID ?? ""
        self.help.onCallEnd(endEvent)
        self.invitationData = nil
    }
  
    @objc public func setAudioOutputToSpeaker(outputToSpeaker: Bool) {
        ZegoUIKit.shared.setAudioOutputToSpeaker(enable: outputToSpeaker)
    }
  
    @objc public func getAudioRouteType() -> ZegoUIKitAudioOutputDevice {
        ZegoUIKit.shared.getAudioRouteType()
    }
    
    private func logComponentsVersion() -> [String: String] {
        let bundleMap: [String: String] = ["UIKit": "com.zegocloud.uikit",
                                           "Call": "org.cocoapods.ZegoUIKitPrebuiltCall",
                                           "CallKitPlugin": "org.cocoapods.ZegoUIKitAppleCallKitPlugin"]
        var bundleVerMap: [String: String] = [:]
        for (name, bundleID) in bundleMap {
            let bundle = Bundle(identifier: bundleID)
            if (bundle != nil) {
                var version = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayVersion") as? String
                if (version == nil) {
                    version = bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                }
                bundleVerMap[name+"_version"] = (version ?? "UNKNOWN")

                var nameAlias = name
                if (nameAlias == "Call") {
                    nameAlias = "PrebuiltCall"
                }
                LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][logComponentsVersion] \(nameAlias) version: \(version ?? "UNKNOWN")")
            }
        }

        return bundleMap
    }
}

class ZegoUIKitPrebuiltCallInvitationService_Help: NSObject, ZegoUIKitEventHandle, ZegoUIKitPrebuiltCallVCDelegate,ZegoCallKitPluginEventHandler {

    
    private let uikitEventDelegates: NSHashTable<ZegoUIKitEventHandle> = NSHashTable(options: .weakMemory)
    
    func addEventHandler(_ eventHandle: ZegoUIKitEventHandle?) {
        self.uikitEventDelegates.add(eventHandle)
    }
    
    func onInvitationReceived(_ inviter: ZegoUIKitUser, type: Int, data: String?) {
        let appState = (UIApplication.shared.applicationState == .active ? "active" : "background")
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onInvitationReceived] inviter:\(inviter.userID ?? "UNKNOWN"), type:\(type), data:\(data ?? ""), appState:\(appState)")
        
        // call invitation type, 0 - audio, 1 - video
        if type != 0 && type != 1 {
            return
        }
        let dataDic: Dictionary? = data?.call_convertStringToDictionary()
        let pluginInvitationID: String? = dataDic?["invitationID"] as? String

        let reportData = ["call_id": dataDic?["call_id"] as AnyObject,
                          "inviter": inviter.userID as AnyObject,
                          "app_state": appState as AnyObject,
                          "extended_data": dataDic?["custom_data"] as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callReceiveCallReportString, paramsDict: reportData)
        
        if ZegoUIKitPrebuiltCallInvitationService.shared.state != .normal {
            guard let userID = inviter.userID else { return }
            let dataDict: [String : AnyObject] = ["reason":"busy" as AnyObject,"invitationID": pluginInvitationID as AnyObject]
            // 多人同时呼叫一人，保留一个ZegoCallInvitationDialog
            if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID == inviter.userID {
                ZegoCallInvitationDialog.hide()
            }
            ZegoCallAudioPlayerTool.stopPlay()
            //FIXME: 
            ZegoUIKitSignalingPluginImpl.shared.refuseInvitation(userID, data: dataDict.call_jsonString) { data in
                
            }
            let refuseData = ["call_id": dataDic?["call_id"] as AnyObject,
                              "inviter": inviter.userID as AnyObject,
                              "state":  appState as AnyObject,
                              "action": "refuse" as AnyObject,
                              "currentCallID": ZegoUIKitPrebuiltCallInvitationService.shared.callID as AnyObject]
            ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: refuseData)

        } else {
            ZegoUIKitPrebuiltCallInvitationService.shared.state = .waiting
            let needReportCall = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID == nil
            
            let callData = buildCallInvitationData(type: type, invitationID: pluginInvitationID, dataDict: dataDic)
            let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: inviter) ?? "") as String
            callData.userAvatar = userAvatar
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
            
            if needReportCall {
                    let uuid = UUID()
                    ZegoUIKitPrebuiltCallInvitationService.shared.currentCallUUID = uuid
                    let callIdentifier = (pluginInvitationID?.isEmpty == false) ? pluginInvitationID! : uuid.uuidString

                    ZegoPluginAdapter.callkitPlugin?.reportIncomingCall(with: uuid, title: inviter.userName ?? "", hasVideo: type == 1, identifier: callIdentifier)
                    if ZegoPluginAdapter.callkitPlugin != nil {
                        let voipData = ["call_id": dataDic?["call_id"] as AnyObject,
                                        "app_state": appState as AnyObject,
                                        "is_voip": 1 as AnyObject,]
                        ReportUtil.sharedInstance().reportEvent(callReceiveCallAlertReportString, paramsDict: voipData)
                    }
            }
            
            ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting = true
            
            if (ZegoPluginAdapter.callkitPlugin == nil){
                _ = ZegoCallInvitationDialog.show(callData)
                ZegoUIKitPrebuiltCallInvitationService.shared.startIncomingRing()
                ReportUtil.sharedInstance().reportEvent(callReceiveCallAlertReportString, paramsDict: reportData)
            }

            // notify onIncomingCallReceived
            if (ZegoUIKitPrebuiltCallInvitationService.shared.delegate == nil) {
                LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onInvitationReceived] delegate is not configured")
            } else if (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallReceived == nil) {
                LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onInvitationReceived] delegate-onIncomingCallReceived is not configured")
            } else {
                let callUser: ZegoCallUser = getCallUser(inviter)
                var callees: [ZegoCallUser]? = []
                if let invitees = callData.invitees {
                    for callee in invitees {
                        let calleeUser: ZegoCallUser = getCallUser(callee)
                        callees?.append(calleeUser)
                    }
                }
                
                LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onInvitationReceived] delegate-onIncomingCallReceived will notify")

                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallReceived?(callData.callID ?? "", caller: callUser, callType: ZegoCallType.init(rawValue: type) ?? .voiceCall, callees: callees)

                LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onInvitationReceived] delegate-onIncomingCallReceived did notify")
            }
        }
    }
    
    func onInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let refuseData = ["call_id": ZegoUIKitPrebuiltCallInvitationService.shared.callID as AnyObject,
                          "invitee": invitee.userID as AnyObject,
                          "app_state":  appState as AnyObject,
                          "action": "accepted" as AnyObject,
                          "is_group_call" : (ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall == true ? 1 : 0)  as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callInvitationResponseReportString, paramsDict: refuseData)
        
      
        let dataDic: Dictionary? = data?.call_convertStringToDictionary()
        let pluginInvitationID: String? = dataDic?["invitationID"] as? String
        // 同一个邀请的事件
      if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID != nil && ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID == pluginInvitationID) {
        // 房主
        if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID == ZegoUIKitPrebuiltCallInvitationService.shared.userID {
              ZegoCallAudioPlayerTool.stopPlay()
              ZegoUIKitPrebuiltCallInvitationService.shared.state = .accept
        }
      }
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let refuseData = ["call_id": ZegoUIKitPrebuiltCallInvitationService.shared.callID as AnyObject,
                          "inviter": inviter.userID as AnyObject,
                          "app_state":  appState as AnyObject,
                          "action": "inviterCancel" as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: refuseData)
        
        let callUser = getCallUser(inviter)
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallCanceled?(callID ?? "", caller: callUser)
        
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        reportCallEnded()
    }
    
    func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
        print("onInvitationRefused data:\(String(describing: data))")
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        
        let callee = getCallUser(invitee)
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        let callData: [String: AnyObject]? = data?.call_convertStringToDictionary()
        
        let callInviteID = callData?["invitationID"] as! String
        if callInviteID != ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID {
            return
        }
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            ZegoUIKit.shared.removeParticipantDic()
            if let callData = callData, callData["reason"] as? String ?? "" == "busy" {
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallRejectedCauseBusy?(callID ?? "", callee: callee)
            } else {
                ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallDeclined?(callID ?? "", callee: callee)
            }
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
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        let dataDic: Dictionary? = data?.call_convertStringToDictionary()
        let pluginInvitationID: String? = dataDic?["invitationID"] as? String
        // 防止旧的超时回调取消当前的弹窗
        
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")
        let refuseData = ["call_id": ZegoUIKitPrebuiltCallInvitationService.shared.callID as AnyObject,
                          "inviter": inviter.userID as AnyObject,
                          "app_state":  appState as AnyObject,
                          "action": "timeout" as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: refuseData)
        
        if pluginInvitationID != ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID {
            return
        }
        let caller = getCallUser(inviter)
        if caller.id == nil {
          caller.id = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID
        }
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallTimeout?(callID ?? "", caller: caller)
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        reportCallEnded()
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")
        let refuseData = ["call_id": ZegoUIKitPrebuiltCallInvitationService.shared.callID as AnyObject,
                          "app_state":  appState as AnyObject,
                          "action": "timeout" as AnyObject,
                          "is_group_call" : (ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall == true ? 1 : 0)  as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callInvitationResponseReportString, paramsDict: refuseData)
        
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
                ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
            } else {
                self.checkInviteesState()
            }
        }
    }
    
    func onSignalingPluginConnectionState(_ params: [String : AnyObject]) {
        let state: ZegoSignalingPluginConnectionState? = params["state"] as? ZegoSignalingPluginConnectionState
        ZegoUIKitPrebuiltCallInvitationService.shared.pluginConnectState = state
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")
        let reportData = ["connect_state": String(describing: state?.rawValue) as AnyObject,
                          "app_state" : appState as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callConnectStateReportString, paramsDict: reportData)
    }
    
    // MARK: ZegoUIKitPrebuiltCallVCDelegate
    func requireRoomForegroundView() -> UIView? {
        return ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.requireRoomForegroundView?()
    }
    
    func getForegroundView(_ userInfo: ZegoUIKitUser?) -> ZegoBaseAudioVideoForegroundView? {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getForegroundView?(userInfo)
    }
    
    func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell? {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getMemberListItemView?(tableView, indexPath: indexPath, userInfo: userInfo)
    }
    
    func getMemberListViewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getMemberListViewForHeaderInSection?(tableView, section: section)
    }
    
    func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getMemberListItemHeight?(userInfo) ?? 54
    }
    
    func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getMemberListHeaderHeight?(tableView, section: section) ?? 0
    }
    
    func onCallEnd(_ endEvent: ZegoCallEndEvent) {
        reportCallEnded()
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onCallEnd?(endEvent)
    }
    
    func onSwitchCameraButtonClick(_ isFrontFacing: Bool) {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onSwitchCameraButtonClick?(isFrontFacing)
    }
    
    func onToggleCameraButtonClick(_ isOn: Bool) {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onToggleCameraButtonClick?(isOn)
    }
    
    func onToggleMicButtonClick(_ isOn: Bool) {
        if (ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate == nil) {
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onToggleMicButtonClick] callVCDelegate is not configured")
        } else if (ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onToggleMicButtonClick == nil) {
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onToggleMicButtonClick] callVCDelegate-onToggleMicButtonClick is not configured")
        } else {
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onToggleMicButtonClick] will notify")
            ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onToggleMicButtonClick?(isOn)
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onToggleMicButtonClick] did notify")
        }
    }
    
    func onAudioOutputButtonClick(_ isSpeaker: Bool) {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onAudioOutputButtonClick?(isSpeaker)
    }

    func onAudioOutputDeviceChanged(_ audioOutput: ZegoUIKitAudioOutputDevice) {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onAudioOutputDeviceChanged?(audioOutput)
    }
   
    func onOnlySelfInRoom(_ userList:[ZegoUIKitUser]) {
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall ||
          (ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall && ZegoUIKitPrebuiltCallInvitationService.shared.config?.exitRoomWhenOnlySelfInGroupRoom == true) {
            ZegoMinimizeManager.shared.stopPiP()
            ZegoMinimizeManager.shared.callVC = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC?.dismiss(animated: true, completion: nil)
            reportCallEnded()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        }
        let endEvent:ZegoCallEndEvent = ZegoCallEndEvent()
        endEvent.reason = .remoteHangUp
        endEvent.kickerUserID = userList.first?.userID ?? ""
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onCallEnd?(endEvent)
    }
  
    func onMeRemovedFromRoom() {
      let endEvent:ZegoCallEndEvent = ZegoCallEndEvent()
      endEvent.reason = .kickOut
      endEvent.kickerUserID = ZegoUIKitPrebuiltCallInvitationService.shared.userID ?? ""
      ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onCallEnd?(endEvent)
    }
    
    func getChatViewItemView(_ tableView: UITableView, indexPath: IndexPath, message: ZegoInRoomMessage) -> UITableViewCell? {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getChatViewItemView?(tableView, indexPath: indexPath, message: message)
    }
    
    func getChatViewItemHeight(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, message: ZegoInRoomMessage) -> CGFloat {
        return ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.getChatViewItemHeight?(tableView, heightForRowAt: indexPath, message: message) ?? -1
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
            callData.customData = dataDict["custom_data"] as? String
            
            let inviter = dataDict["inviter"] as? [String: String]
            let inviterID = inviter?["id"] ?? ""
            let inviterName = inviter?["name"] ?? ""
            callData.inviter = ZegoUIKitUser(inviterID, inviterName)
        }
        callData.invitationID = invitationID
        callData.type = ZegoInvitationType.init(rawValue: type) ?? .voiceCall
        
        return callData
    }
    
    func checkInviteesState() {
        guard let inviteesList = ZegoUIKitPrebuiltCallInvitationService.shared.invitees
        else { return }
        var needClear: Bool = true
        for user in inviteesList {
            if user.state == .waiting {
                needClear = false
                break
            }
        }
        if needClear {
            let callID = ZegoUIKitPrebuiltCallInvitationService.shared.callID ?? ""
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallRejectedCauseBusy?(callID, callee: ZegoCallUser())
            ZegoCallAudioPlayerTool.stopPlay()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
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
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][didReceiveIncomingPush] uuid:\(uuid.uuidString), invitationID:\(invitationID), data:\(data)", flush: true)
        
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")
        let voipData = ["call_id": invitationID as AnyObject,
                        "app_state": appState as AnyObject,
                        "is_voip": 1 as AnyObject,]
        ReportUtil.sharedInstance().reportEvent(callReceiveCallAlertReportString, paramsDict: voipData)
        
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
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onCallKitAnswerCall]", flush: true)

        let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData
        let inviterUserID = invitationData?.inviter?.userID ?? ""
        let invitationID = invitationData?.invitationID
        ZegoUIKit.getSignalingPlugin().acceptInvitation(inviterUserID, invitationID: invitationID, data: nil) { data in
            defer {
                ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting = false
                action.fulfill()
            }
            
            let errorCode = data?["code"] as? Int
            
            let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onCallKitAnswerCall] acceptInvitation, error:\(String(describing: errorCode)), appState:\(appState)")

            let reportData = ["call_id": String(describing: ZegoUIKitPrebuiltCallInvitationService.shared.callID) as AnyObject,
                              "action": "accept" as AnyObject,
                              "app_state":  appState as AnyObject,
                              "errorCode": errorCode as AnyObject,
                              "is_voip": 1 as AnyObject]
            ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: reportData)
            
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
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onCallKitAnswerCall] will present ZegoUIKitPrebuiltCallVC config:\(String(describing: config))")

            let callVC: ZegoUIKitPrebuiltCallVC = ZegoUIKitPrebuiltCallVC.init(invitationData, config: config)
            callVC.modalPresentationStyle = .fullScreen
            callVC.delegate = ZegoUIKitPrebuiltCallInvitationService.shared.help
            currentViewController()?.present(callVC, animated: true, completion: nil)
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC = callVC
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallAcceptButtonPressed?()
        }
    }
    
    func onCallKitEndCall(_ action: CallKitAction) {
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][onCallKitEndCall]", flush: true)
        
        let appState:String = UIApplication.shared.applicationState == .active ? "active" : (UIApplication.shared.applicationState == .background ? "background" : "restarted")

        let reportData = ["call_id": String(describing: ZegoUIKitPrebuiltCallInvitationService.shared.callID) as AnyObject,
                          "action": "refuse" as AnyObject,
                          "app_state":  appState as AnyObject,
                          "is_voip": 1 as AnyObject]
        ReportUtil.sharedInstance().reportEvent(callResponseCallReportString, paramsDict: reportData)
        
        if ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting {
            // refuse
            let refuseData: [String : AnyObject] = ["reason": "decline" as AnyObject, "invitationID": ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID as AnyObject]
            let inviterID = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID ?? ""
            ZegoUIKit.getSignalingPlugin().refuseInvitation(inviterID, data: refuseData.call_jsonString) { data in
                
            }
            
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallDeclineButtonPressed?()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
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
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallInvitationService][reportCallEnded] remoteEnded", flush: true)
            ZegoPluginAdapter.callkitPlugin?.reportCallEnded(with: uuid, reason: CXCallEndedReason.remoteEnded.rawValue)
        }
    }
    
    func onCallKitStartCall(_ action: CallKitAction) {
        // nothing
    }
    
    func onCallKitSetHeldCall(_ action: CallKitAction) {
        // nothing
    }
    
    func onCallKitSetGroupCall(_ action: CallKitAction) {
        // nothing
    }
    
    func onCallKitPlayDTMFCall(_ action: CallKitAction) {
        // nothing
    }
    
    func onCallKitTimeOutPerforming(_ action: CallKitAction) {
        // nothing
    }
    
}


