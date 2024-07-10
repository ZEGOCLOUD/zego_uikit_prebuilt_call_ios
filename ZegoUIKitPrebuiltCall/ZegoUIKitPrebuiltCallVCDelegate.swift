//
//  ZegoUIKitPrebuiltCallVCDelegate.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2024/1/18.
//

import Foundation
import ZegoUIKit

@objc public protocol ZegoUIKitPrebuiltCallVCDelegate: AnyObject {
    @objc optional func getForegroundView(_ userInfo: ZegoUIKitUser?) -> ZegoBaseAudioVideoForegroundView?
    @objc optional func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell?
    @objc optional func getMemberListViewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView?
    @objc optional func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat
    @objc optional func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat
    @objc optional func onOnlySelfInRoom(_ userList:[ZegoUIKitUser])
    @objc optional func onCallEnd(_ endEvent: ZegoCallEndEvent)
    @objc optional func onSwitchCameraButtonClick(_ isFrontFacing: Bool)
    @objc optional func onToggleCameraButtonClick(_ isOn: Bool)
    @objc optional func onToggleMicButtonClick(_ isOn: Bool)
    @objc optional func onAudioOutputButtonClick(_ isSpeaker: Bool)
    
    //MARK: - ZegoInRoomChatViewDelegate
    @objc optional func getChatViewItemView(_ tableView: UITableView, indexPath: IndexPath, message: ZegoInRoomMessage) -> UITableViewCell?
    @objc optional func getChatViewItemHeight(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, message: ZegoInRoomMessage) -> CGFloat
    
    @objc optional func onCallTimeUpdate(_ duration: Int)
  
    @objc optional func onAudioOutputDeviceChanged(_ audioOutput: ZegoUIKitAudioOutputDevice)
}
