//
//  ZegoUIKitCallPlugin.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2024/8/5.
//

import ZegoPluginAdapter

class ZegoUIKitPrebuiltCallPlugin: ZegoCallPluginProtocol {
    
    public static let shared = ZegoUIKitPrebuiltCallPlugin()
    
    public init() {
        
    }
    
    
    let service = ZegoUIKitPrebuiltCallInvitationService.shared
    
    public var pluginType: ZegoPluginType {
        .call
    }
    
    public var version: String {
        "1.0.0"
    }
    
    func initWith(appID: UInt32, appSign: String, userID: String, userName: String, callPluginConfig: ZegoCallPluginConfig) {
        var invitationConfig: ZegoUIKitPrebuiltCallInvitationConfig;
        if (callPluginConfig.invitationConfig is ZegoUIKitPrebuiltCallInvitationConfig) {
            invitationConfig = callPluginConfig.invitationConfig as! ZegoUIKitPrebuiltCallInvitationConfig;
        } else {
            invitationConfig = ZegoUIKitPrebuiltCallInvitationConfig();
        }
        service.initWithAppID(appID, appSign: appSign, userID: userID, userName: userName, config: invitationConfig)
    }
    
    func initWith(appID: UInt32, appSign: String, userID: String, userName: String) {
        service.initWithAppID(appID, appSign: appSign, userID: userID, userName: userName)
    }
    
    
    func unInit() {
        service.unInit()
    }
    
    func logoutUser() {
        
    }
  
  /// 主动发起音、视频呼叫通话
  /// - Parameters:
  ///   - invitees: 邀请通话的用户list
  ///   - invitationType: 通话类型。语音、视频
  ///   - customData: 自定义数据
  ///   - timeout: 超时时间
  ///   - notificationConfig: 离线通知信息
  ///   - callback: 回调callback
    func sendInvitationWithUIChange( invitees:[ZegoPluginCallUser],invitationType: ZegoPluginCallType,
                                     customData: String, timeout: Int, notificationConfig: ZegoSignalingPluginNotificationConfig,
                                     callback: ZegoPluginCallback?) {
        service.sendInvitation(invitees, invitationType: invitationType, timeout: timeout, customerData: customData, notificationConfig: notificationConfig) { data in
            callback?(data)
        }
    }
    
    func registerCallKitDelegate(delegate: AnyObject) {
        
      if delegate is ZegoUIKitPrebuiltCallInvitationServiceDelegate {
            ZegoUIKitPrebuiltCallInvitationService.shared.delegate = delegate as? any ZegoUIKitPrebuiltCallInvitationServiceDelegate
        }
        
      if delegate is ZegoUIKitPrebuiltCallVCDelegate {
            ZegoUIKitPrebuiltCallInvitationService.shared.callVCDelegate = delegate as? any ZegoUIKitPrebuiltCallVCDelegate
        }
    }
    
}
