//
//  ZegoUIKitPrebuiltCallInvitationService.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/11.
//

import UIKit
import ZegoUIKitSDK

public protocol ZegoUIKitPrebuiltCallInvitationServiceDelegate: AnyObject {
    func requireConfig(_ data: ZegoCallInvitationData) -> ZegoUIKitPrebuiltCallConfig
}

public class ZegoUIKitPrebuiltCallInvitationService: NSObject {
    
    public static let shared = ZegoUIKitPrebuiltCallInvitationService()
    public weak var delegate: ZegoUIKitPrebuiltCallInvitationServiceDelegate?
    
    let help = ZegoUIKitPrebuiltCallInvitationService_Help()
    var config: ZegoUIKitPrebuiltCallInvitationConfig? {
        didSet {
            if let plugins = config?.plugins {
                ZegoUIKitInvitationService.shared.installPlugins(plugins)
            }
        }
    }
    var invitationData: ZegoCallPrebuiltInvitationData? {
        didSet {
            guard let invitationData = invitationData else {
                return
            }
            self.isGroupCall = invitationData.invitees?.count ?? 0 > 1 ? true : false
        }
    }
    var isCalling: Bool = false
    var isGroupCall: Bool = false
    var pluginConnectState: ZegoPluginConnectionState?
    var userID: String?
    var userName: String?
    weak var callVC: UIViewController?
    
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
            ZegoUIKitInvitationService.shared.login(userID, userName: userName)
        }
    }
    
    public func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String, config: ZegoUIKitPrebuiltCallInvitationConfig) {
        self.config = config
        self.userID = userID
        self.userName = userName
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKitInvitationService.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.login(userID, userName: userName)
        ZegoUIKitInvitationService.shared.login(userID, userName: userName)
    }
    
    public func unInit() {
        ZegoUIKit.shared.uninit()
        ZegoUIKitInvitationService.shared.uninit()
        NotificationCenter.default.removeObserver(self)
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
        if ZegoUIKitPrebuiltCallInvitationService.shared.isCalling {
            guard let userID = inviter.userID else { return }
            let dataDict: [String : AnyObject] = ["reason":"busy" as AnyObject,"invitationID": pluginInvitationID as AnyObject]
            ZegoUIKitInvitationService.shared.refuseInvitation(userID, data: dataDict.call_jsonString)
        } else {
            let callData = ZegoCallInvitationData()
            if let dataDic = dataDic {
                callData.callID = dataDic["call_id"] as? String
                let invitees = dataDic["invitees"] as! Array<[String : String]>
                callData.invitees = self.getInviteeList(invitees)
                callData.customData = dataDic["customData"] as? String
            }
            callData.invitationID = pluginInvitationID
            callData.inviter = inviter
            callData.type = ZegoInvitationType.init(rawValue: type)
            _ = ZegoCallInvitationDialog.show(callData)
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = self.buildReceiveInvitationData(callData, invitationID: pluginInvitationID)
            ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = true
            ZegoUIKitPrebuiltCallInvitationService.shared.startIncomingRing()
        }
    }
    
    func onInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
    }
    
    func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
        if let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData,
           let invitationInvitees = invitationData.invitees
        {
            for invitationUser in invitationInvitees {
                if invitee.userID == invitationUser.user?.userID {
                    invitationUser.state = .refuse
                }
            }
        }
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            ZegoCallAudioPlayerTool.stopPlay()
            ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        } else {
            self.checkInviteesState()
        }
    }
    
    func onInvitationTimeout(_ inviter: ZegoUIKitUser, data: String?) {
        ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
        ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        ZegoCallAudioPlayerTool.stopPlay()
        ZegoCallInvitationDialog.hide()
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        if let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData,
           let invitationInvitees = invitationData.invitees
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
                ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
                ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            } else {
                self.checkInviteesState()
            }
        }
        ZegoCallInvitationDialog.hide()
    }
    
    func onSignalingPluginConnectionState(_ params: [String : AnyObject]) {
        let state: ZegoPluginConnectionState? = params["state"] as? ZegoPluginConnectionState
        ZegoUIKitPrebuiltCallInvitationService.shared.pluginConnectState = state
    }
    
    func onHangUp(_ isHandup: Bool) {
        if isHandup {
            ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
            ZegoCallAudioPlayerTool.stopPlay()
            guard let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData else { return }
            var needCancel: Bool = true
            if let invitees = invitationData.invitees {
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
                    ZegoUIKitInvitationService.shared.cancelInvitation(cancelInvitees, data: nil, callback: nil)
                }
            }
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
        }
    }
    
    func onOnlySelfInRoom() {
        if !ZegoUIKitPrebuiltCallInvitationService.shared.isGroupCall {
            ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC?.dismiss(animated: true, completion: nil)
        }
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
    
    func buildReceiveInvitationData(_ callData: ZegoCallInvitationData, invitationID: String?) -> ZegoCallPrebuiltInvitationData? {
        guard let callID = callData.callID,
        let prebuiltInviter = callData.inviter,
        let invitees = callData.invitees
        else { return nil }
        var invitationUsers: [ZegoCallPrebuiltInvitationUser] = []
        for user in invitees {
            let invitationUser = ZegoCallPrebuiltInvitationUser.init(user, state: .wating)
            invitationUsers.append(invitationUser)
        }
        let invitationData: ZegoCallPrebuiltInvitationData = ZegoCallPrebuiltInvitationData.init(callID, inviter: prebuiltInviter, invitees: invitationUsers, type: callData.type ?? .voiceCall)
        invitationData.invitationID = invitationID
        return invitationData
    }
    
    func checkInviteesState() {
        guard let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData,
        let inviteesList = invitationData.invitees
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
            ZegoUIKitPrebuiltCallInvitationService.shared.isCalling = false
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateUserState(_ state: ZegoCallInvitationState, userList: [String]) {
        guard let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData,
        let invitees = invitationData.invitees
        else { return }
        for user in invitees {
            for userID in userList {
                if user.user?.userID == userID {
                    user.state = state
                }
            }
        }
    }
}

