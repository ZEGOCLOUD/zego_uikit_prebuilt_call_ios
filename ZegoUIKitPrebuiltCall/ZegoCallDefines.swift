//
//  CallDefines.swift
//  ZegoUIKit
//
//  Created by zego on 2022/7/28.
//

import Foundation
import UIKit
import ZegoUIKit


@objc public enum ZegoMenuBarButtonName: Int {
    case hangUpButton
    case toggleCameraButton
    case toggleMicrophoneButton
    case switchCameraButton
    case switchAudioOutputButton
    case showMemberListButton
    case chatButton
    case minimizingButton
}

//public enum ZegoCallType: Int {
//    case oneOnOneVoiceCall
//    case oneOnOneVideoCall
//    case groupVoiceCall
//    case groupVideoCall
//}

@objc public enum ZegoCallType: Int {
    case voiceCall = 0
    case videoCall = 1
}

public class ZegoCallUser: NSObject {
    public var id: String?
    public var name: String?
}

@objcMembers
public class ZegoCallInvitationData: NSObject {
    public var callID: String?
    public var type: ZegoInvitationType = .voiceCall
    public var invitees: [ZegoUIKitUser]?
    public var inviter: ZegoUIKitUser?
    public var invitationID: String?
    public var customData: String?
    
}

@objc public enum ZegoInvitationType: Int {
    case voiceCall = 0
    case videoCall = 1
}


@objc public enum ZegoMenuBarStyle: Int {
    case light
    case dark
}

enum ZegoUIKitCallIconSetType: String, Hashable {
    
    case call_accept_icon
    case call_video_icon
    case icon_more
    case icon_more_light
    case icon_member_normal
    case icon_back
    case icon_camera_overturn
    case call_waiting_bg
    case user_phone_icon
    case user_video_icon
    case icon_message_normal
    case icon_message_press
    case minimizing_icon
    
    // MARK: - Image handling
    func load() -> UIImage {
        let image = UIImage.resource.loadImage(name: self.rawValue, bundleName: "ZegoUIKitPrebuiltCall") ?? UIImage()
        return image
    }
}


let UIkitScreenHeight = UIScreen.main.bounds.size.height
let UIKitScreenWidth = UIScreen.main.bounds.size.width
let UIKitBottomSafeAreaHeight = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
let UIKitTopSafeAreaHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0

func adaptLandscapeWidth(_ x: CGFloat) -> CGFloat {
    return x * (UIKitScreenWidth / 375.0)
}

func adaptLandscapeHeight(_ x: CGFloat) -> CGFloat {
    return x * (UIkitScreenHeight / 818.0)
}

func currentViewController() -> (UIViewController?) {
   var window = UIApplication.shared.keyWindow
   if window?.windowLevel != UIWindow.Level.normal{
     let windows = UIApplication.shared.windows
     for  windowTemp in windows{
       if windowTemp.windowLevel == UIWindow.Level.normal{
          window = windowTemp
          break
        }
      }
    }
   let vc = window?.rootViewController
   return currentViewController(vc)
}


func currentViewController(_ vc :UIViewController?) -> UIViewController? {
   if vc == nil {
      return nil
   }
   if let presentVC = vc?.presentedViewController {
      return currentViewController(presentVC)
   }
   else if let tabVC = vc as? UITabBarController {
      if let selectVC = tabVC.selectedViewController {
          return currentViewController(selectVC)
       }
       return nil
    }
    else if let naiVC = vc as? UINavigationController {
       return currentViewController(naiVC.visibleViewController)
    }
    else {
       return vc
    }
 }

func KeyWindow() -> UIWindow {
    let window: UIWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last!
    return window
}

func getTimeStamp() -> Int64 {
    let timeInterval:TimeInterval = Date().timeIntervalSince1970
    let timeStamp = Int64(timeInterval)
    return timeStamp
}
