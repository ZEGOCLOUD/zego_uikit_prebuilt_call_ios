//
//  Prebuilt1on1Config.swift
//  ZegoUIKitExample
//
//  Created by zego on 2022/7/14.
//

import UIKit
import ZegoUIKitSDK

public class ZegoUIkitPrebuiltCallConfig: NSObject {
    public var audioVideoViewConfig: ZegoAudioVideoViewConfig = ZegoAudioVideoViewConfig()
    public var bottomMenuBarConfig: ZegoBottomMenuBarConfig = ZegoBottomMenuBarConfig()
    public var layout: ZegoLayout = ZegoLayout()
    /// Whether the camera is enabled by default. The default value is enabled.
    public var turnOnCameraWhenjoining: Bool = true
    /// Is the microphone enabled by default? It is enabled by default.
    public var turnOnMicrophoneWhenjoining: Bool = true
    /// Is the speaker used by default? The default is Yes. If no, use the default device.
    public var useSpeakerWhenjoining: Bool = false
    /// The maximum number of buttons that can be displayed in the ControlBar. If this value is exceeded, the "More" button is displayed
    /// Whether to display information about the Leave Room dialog box when the hang up button is clicked. If it is not set, it will not be displayed. If it is set, it will be displayed.
    public var hangUpConfirmDialogInfo: ZegoLeaveConfirmDialogInfo?
}

public class ZegoAudioVideoViewConfig: NSObject {
    /// Used to control whether the default MicrophoneStateIcon for the prebuilt layer is displayed on VideoView.
    public var showMicrophoneStateOnView: Bool = true
    /// Used to control whether the default CameraStateIcon for the prebuilt layer is displayed on VideoView.
    public var showCameraStateOnView: Bool = true
    /// Controls whether to display the default UserNameLabel for the prebuilt layer on VideoView
    public var showUserNameOnView: Bool = true
    /// Whether to display the sound waves around the profile picture in voice mode
    public var showSoundWavesInAudioMode: Bool = true
    /// Default true, normal black edge mode (otherwise landscape is ugly)
    public var useVideoViewAspectFill: Bool = true
}

public class ZegoBottomMenuBarConfig: NSObject {
    /// Buttons that need to be displayed on the MenuBar are displayed in the order of the actual List
    public var buttons: [ZegoMenuBarButtonName] = [.toggleCameraButton,.toggleMicrophoneButton,.hangUpButton,.swtichAudioOutputButton,.switchCameraButton]
    /// 在MenuBar最多能显示的按钮数量，该值最大为5。如果超过了该值，则显示“更多”按钮.注意这个值是包含“更多”按钮。
    public var maxCount: UInt = 5
    /// Yes no operation on the screen for 5 seconds, or if the user clicks the position of the non-response area on the screen, the top and bottom will be folded up
    public var hideAutomatically: Bool = true
    /// Whether the user can click the position of the non-responsive area of the screen, and fold up the top and bottom
    public var hideByClick: Bool = true

}

public class ZegoLayout: NSObject {
    public var mode: ZegoUIKitLayoutMode = .invalid
    public var config: ZegoLayoutConfig?
}


