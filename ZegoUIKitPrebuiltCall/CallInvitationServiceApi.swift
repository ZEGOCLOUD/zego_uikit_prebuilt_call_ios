//
//  CallInvitationServiceApi.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2024/1/18.
//

import Foundation

public protocol CallInvitationServiceApi {
    
    /// Initialization of call service
    /// - Parameters:
    ///   - appID: Your appID
    ///   - appSign: Your appSign
    ///   - userID: User unique identification
    ///   - userName: userName
    ///   - config: CallInvitation personalized configuration
    func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String, config: ZegoUIKitPrebuiltCallInvitationConfig)
    /// Initialization of call service
    /// - Parameters:
    ///   - appID: Your appID
    ///   - appSign: Your appSign
    ///   - userID: User unique identification
    ///   - userName: userName
    func initWithAppID(_ appID: UInt32, appSign: String, userID: String, userName: String)
    /// Deinitialize call service
    func unInit()
    /// Obtain the call page controller
    /// - Returns: ZegoUIKitPrebuiltCallVC
    func getPrebuiltCallVC()-> ZegoUIKitPrebuiltCallVC?
    /// End the call
    func endCall()
    /// Set the device Token to be pushed offline
    /// - Parameter deviceToken: device token
    static func setRemoteNotificationsDeviceToken(_ deviceToken: Data)
}
