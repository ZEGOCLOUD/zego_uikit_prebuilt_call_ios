//
//  ZegoUIKitPrebuiltCallInvitationService.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZegoUIKit
import ZegoPluginAdapter


@objc public class ZegoUIKitPrebuiltCallInvitationService: NSObject {
    
    @objc public static let shared = ZegoUIKitPrebuiltCallInvitationService()
    @objc public weak var delegate: ZegoUIKitPrebuiltCallInvitationServiceDelegate?
    @objc public weak var callVCDelegate: ZegoUIKitPrebuiltCallVCDelegate?
    
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
}

extension ZegoUIKitPrebuiltCallInvitationService: CallInvitationServiceApi {
    
    @objc public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String, config: ZegoUIKitPrebuiltCallInvitationConfig) {
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
            ZegoPluginAdapter.callkitPlugin?.enableVoIP(config.isSandboxEnvironment)
        }
        
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.enableCustomVideoRender(enable: true)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
    }
    
    @objc public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String) {
        self.userID = userID
        self.userName = userName
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
    }
    
    @objc public func unInit() {
        ZegoUIKit.shared.uninit()
        ZegoUIKitSignalingPluginImpl.shared.uninit()
        ZegoUIKit.shared.enableCustomVideoRender(enable: false)
        NotificationCenter.default.removeObserver(self)
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
        self.invitationData = nil
    }
}

class ZegoUIKitPrebuiltCallInvitationService_Help: NSObject, ZegoUIKitEventHandle, ZegoUIKitPrebuiltCallVCDelegate, ZegoCallKitPluginEventHandler {

    
    private let uikitEventDelegates: NSHashTable<ZegoUIKitEventHandle> = NSHashTable(options: .weakMemory)
    
    func addEventHandler(_ eventHandle: ZegoUIKitEventHandle?) {
        self.uikitEventDelegates.add(eventHandle)
    }
    
    func onInvitationReceived(_ inviter: ZegoUIKitUser, type: Int, data: String?) {
        // call invitation type, 0 - audio, 1 - video
        if type != 0 && type != 1 {
            return
        }
        let dataDic: Dictionary? = data?.call_convertStringToDictionary()
        let pluginInvitationID: String? = dataDic?["invitationID"] as? String
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID != nil && ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID != pluginInvitationID)
            || ZegoUIKit.shared.room != nil {
            guard let userID = inviter.userID else { return }
            let dataDict: [String : AnyObject] = ["reason":"busy" as AnyObject,"invitationID": pluginInvitationID as AnyObject]
            ZegoUIKitSignalingPluginImpl.shared.refuseInvitation(userID, data: dataDict.call_jsonString)
        } else {
            
            let needReportCall = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID == nil
            
            let callData = buildCallInvitationData(type: type, invitationID: pluginInvitationID, dataDict: dataDic)
//            callData.inviter = inviter;
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = callData
            
            if needReportCall {
                let uuid = UUID()
                if UIApplication.shared.applicationState == .active {
                  ZegoUIKitPrebuiltCallInvitationService.shared.currentCallUUID = uuid
  //                ZegoPluginAdapter.signalingPlugin?.reportIncomingCall(with: uuid, title: inviter.userName ?? "", hasVideo: type == 1)
                  ZegoPluginAdapter.callkitPlugin?.reportIncomingCall(with: uuid, title: inviter.userName ?? "", hasVideo: type == 1)
                }
            }
            
            ZegoUIKitPrebuiltCallInvitationService.shared.isCallInviting = true
            
            if (ZegoPluginAdapter.callkitPlugin == nil){
                _ = ZegoCallInvitationDialog.show(callData)
                ZegoUIKitPrebuiltCallInvitationService.shared.startIncomingRing()
            }

            
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
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
      
        let dataDic: Dictionary? = data?.call_convertStringToDictionary()
        let pluginInvitationID: String? = dataDic?["invitationID"] as? String
        // 同一个邀请的事件
      if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID != nil && ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.invitationID == pluginInvitationID) {
        // 房主
        if ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID == ZegoUIKitPrebuiltCallInvitationService.shared.userID {
          ZegoCallAudioPlayerTool.stopPlay()
        }
      }
//        let callee = getCallUser(invitee)
//        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.callID
//        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onOutgoingCallAccepted?(callID ?? "", callee: callee)
//          ZegoCallAudioPlayerTool.stopPlay()
//        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        let callUser = getCallUser(inviter)
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallCanceled?(callID ?? "", caller: callUser)
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        currentViewController()?.dismiss(animated: true, completion: nil)
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        reportCallEnded()
    }
    
    func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
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
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
        let caller = getCallUser(inviter)
        if caller.id == nil {
          caller.id = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.inviter?.userID
        }
        let callID: String? = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData?.callID
        ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onIncomingCallTimeout?(callID ?? "", caller: caller)
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        currentViewController()?.dismiss(animated: true, completion: nil)
        reportCallEnded()
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        if (ZegoUIKitPrebuiltCallInvitationService.shared.invitationData == nil) {
            return
        }
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
    
    // MARK: ZegoUIKitPrebuiltCallVCDelegate
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
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onToggleMicButtonClick?(isOn)
    }
    
    func onAudioOutputButtonClick(_ isSpeaker: Bool) {
        ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate?.onAudioOutputButtonClick?(isSpeaker)
    }
    
    func onOnlySelfInRoom(_ userList:[ZegoUIKitUser]) {
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            ZegoMinimizeManager.shared.stopPiP()
            ZegoMinimizeManager.shared.callVC = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC?.dismiss(animated: true, completion: nil)
            reportCallEnded()
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
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
            callData.customData = dataDict["customData"] as? String
            
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
//            ZegoPluginAdapter.signalingPlugin?.reportCallEnded(with: uuid, reason: 2)
            ZegoPluginAdapter.callkitPlugin?.reportCallEnded(with: uuid, reason: 2)
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
