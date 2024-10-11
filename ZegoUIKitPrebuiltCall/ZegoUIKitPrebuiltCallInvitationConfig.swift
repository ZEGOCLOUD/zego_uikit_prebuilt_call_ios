//
//  ZegoUIKitPrebuiltCallInvitationConfig.swift
//  ZegoUIKitCallWithInvitation
//
//  Created by zego on 2022/10/14.
//

import UIKit
import ZegoUIKit
import ZegoPluginAdapter


@objcMembers
public class ZegoUIKitPrebuiltCallInvitationConfig: NSObject {
    public var incomingCallRingtone: String?
    public var outgoingCallRingtone: String?
    public var showDeclineButton: Bool = true
    public var notifyWhenAppRunningInBackgroundOrQuit: Bool = true
    public var isSandboxEnvironment: Bool = true
    public var exitRoomWhenOnlySelfInGroupRoom: Bool = false
    public var certificateIndex: ZegoSignalingPluginMultiCertificate = .firstCertificate
    public var translationText: ZegoTranslationText = ZegoTranslationText(language: .ENGLISH);
    public var videoConfig :ZegoPrebuiltCallVideoConfig = ZegoPrebuiltCallVideoConfig(resolution: .PRESET_360P)
    public init(notifyWhenAppRunningInBackgroundOrQuit: Bool = true,
                isSandboxEnvironment: Bool = true,
                certificateIndex: ZegoSignalingPluginMultiCertificate = .firstCertificate) {
        super.init()
        self.notifyWhenAppRunningInBackgroundOrQuit = notifyWhenAppRunningInBackgroundOrQuit
        self.isSandboxEnvironment = isSandboxEnvironment
        self.certificateIndex = certificateIndex
    }
}

@objcMembers
public class ZegoTranslationText: NSObject {
    
    var language :ZegoUIKitLanguage  = .ENGLISH
  
    public var incomingVideoCallDialogTitle: String = "%@"
    public var incomingVideoCallDialogMessage: String = "Incoming video call..."
    public var incomingVoiceCallDialogTitle: String = "%@"
    public var incomingVoiceCallDialogMessage: String = "Incoming voice call..."
    public var incomingVideoCallPageTitle: String = "%@"
    public var incomingVideoCallPageMessage: String = "Incoming video call..."
    public var incomingVoiceCallPageTitle: String = "%@"
    public var incomingVoiceCallPageMessage: String = "Incoming voice call..."
    public var incomingGroupVideoCallDialogTitle: String = "%@"
    public var incomingGroupVideoCallDialogMessage: String = "Incoming group video call..."
    public var incomingGroupVoiceCallDialogTitle: String = "%@"
    public var incomingGroupVoiceCallDialogMessage: String = "Incoming group voice call..."
    public var incomingGroupVideoCallPageTitle: String = "%@"
    public var incomingGroupVideoCallPageMessage: String = "Incoming group video call..."
    public var incomingGroupVoiceCallPageTitle: String = "%@"
    public var incomingGroupVoiceCallPageMessage: String = "Incoming group voice call..."
    
    
    public var outgoingVideoCallPageTitle: String = "%@"
    public var outgoingVideoCallPageMessage: String = "Calling..."
    public var outgoingVoiceCallPageTitle: String = "%@"
    public var outgoingVoiceCallPageMessage: String = "Calling..."
    
    public var incomingCallPageDeclineButton: String = "Decline"
    public var incomingCallPageAcceptButton: String = "Accept"
  
    public init(language:ZegoUIKitLanguage) {
      super.init()
      self.language = language
      if language == .CHS {
        incomingVideoCallDialogTitle = "%@"
        incomingVideoCallDialogMessage = "视频来电..."
        incomingVoiceCallDialogTitle = "%@"
        incomingVoiceCallDialogMessage = "语音来电..."
        incomingVideoCallPageTitle = "%@"
        incomingVideoCallPageMessage = "视频来电..."
        incomingVoiceCallPageTitle = "%@"
        incomingVoiceCallPageMessage = "语音来电..."
        incomingGroupVideoCallDialogTitle = "%@"
        incomingGroupVideoCallDialogMessage = "群组视频来电..."
        incomingGroupVoiceCallDialogTitle = "%@"
        incomingGroupVoiceCallDialogMessage = "来电群组语音呼叫..."
        incomingGroupVideoCallPageTitle = "%@"
        incomingGroupVideoCallPageMessage = "群组视频来电..."
        incomingGroupVoiceCallPageTitle = "%@"
        incomingGroupVoiceCallPageMessage = "来电群组语音呼叫..."
        
        
        outgoingVideoCallPageTitle = "%@"
        outgoingVideoCallPageMessage = "正在呼叫..."
        outgoingVoiceCallPageTitle = "%@"
        outgoingVoiceCallPageMessage = "正在呼叫..."
        
        incomingCallPageDeclineButton = "拒绝"
        incomingCallPageAcceptButton = "接受"
     
      }
    }
  
    public func getLanguage() -> ZegoUIKitLanguage {
      return self.language
    }
}
