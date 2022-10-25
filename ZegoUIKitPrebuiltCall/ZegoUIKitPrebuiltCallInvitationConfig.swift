//
//  ZegoUIKitPrebuiltCallInvitationConfig.swift
//  ZegoUIKitCallWithInvitation
//
//  Created by zego on 2022/10/14.
//

import UIKit
import ZegoUIKitSDK

@objcMembers
public class ZegoUIKitPrebuiltCallInvitationConfig: NSObject {
    public var incomingCallRingtone: String?
    public var outgoingCallRingtone: String?
    var plugins: [ZegoUIKitPlugin]?
    
    public init(_ plugins: [ZegoUIKitPlugin]) {
        super.init()
        self.plugins = plugins
    }
}
