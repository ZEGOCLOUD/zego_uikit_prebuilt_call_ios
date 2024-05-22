//
//  ZegoTopMenuBar.swift
//  ZegoPrebuiltVideoConferenceDemoDemo
//
//  Created by zego on 2022/9/14.
//

import UIKit
import ZegoUIKit

protocol ZegoTopMenuBarDelegate: AnyObject {
    func onHangUp(_ isHangup: Bool)
    func onMinimizationButtonDidClick()
    func onSwitchCameraButtonClick(_ isFrontFacing: Bool)
    func onToggleCameraButtonClick(_ isOn: Bool)
    func onToggleMicButtonClick(_ isOn: Bool)
    func onAudioOutputButtonClick(_ isSpeaker: Bool)
}

extension ZegoTopMenuBarDelegate {
    func onHangUp(_ isHandup: Bool) { }
    func onMinimizationButtonDidClick() { }
    func onSwitchCameraButtonClick(_ isFrontFacing: Bool) { }
    func onToggleCameraButtonClick(_ isOn: Bool) { }
    func onToggleMicButtonClick(_ isOn: Bool) { }
    func onAudioOutputButtonClick(_ isSpeaker: Bool) { }
}

class ZegoTopMenuBar: UIView {
    
    public var userID: String?
    public var config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() {
        didSet {
            self.barButtons = config.topMenuBarConfig.buttons
        }
    }
    private var barButtons:[ZegoMenuBarButtonName] = [] {
        didSet {
            self.createButton()
            self.setupLayout()
        }
    }
    
    private let maxCount: Int = 3
    private let rightMargin: CGFloat = 13
    private let bottomMargin: CGFloat = 5
    
    private let itemSpace: CGFloat = 1.5
    
    let itemSize: CGSize = CGSize.init(width: 35, height: 35)
    
    public weak var delegate: ZegoTopMenuBarDelegate?
    
    
    weak var showQuitDialogVC: UIViewController?
    
    private var buttons: [UIView] = []
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHexString("#FFFFFF")
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel.frame = CGRect(x: 5, y: self.frame.size.height - 9.5 - 25, width: 150, height: 25)
        self.setupLayout()
    }
    
    /// - Parameter button: <#button description#>
    public func addButtonToMenuBar(_ button: UIButton) {
        if self.buttons.count > maxCount {
            return
        }
        self.buttons.append(button)
        self.addSubview(button)
        self.setupLayout()
    }
    
    //MARK: -private
    private func setupLayout() {
        self.layoutViewWithButton()
    }
    
    private func layoutViewWithButton() {
        var index: Int = 0
        var lastView: UIView?
        for button in self.buttons {
            if index == 0 {
                button.frame = CGRect.init(x: self.frame.size.width - rightMargin - itemSize.width, y: self.frame.size.height - bottomMargin - itemSize.height, width: itemSize.width, height: itemSize.width)
            } else {
                if let lastView = lastView {
                    button.frame = CGRect.init(x: lastView.frame.minX - itemSpace - itemSize.width, y: lastView.frame.minY, width: itemSize.width, height: itemSize.height)
                }
            }
            lastView = button
            index = index + 1
        }
    }
    
    
    private func createButton() {
        self.buttons.removeAll()
        let buttonConfig = config.topMenuBarConfig.buttonConfig
        var index = 0
        for item in self.barButtons {
            if maxCount < self.barButtons.count && index == maxCount {
                break
            }
            index = index + 1
            switch item {
            case .switchCameraButton:
                let flipCameraComponent: ZegoSwitchCameraButton = ZegoSwitchCameraButton()
                flipCameraComponent.iconBackFacingCamera = ZegoUIKitCallIconSetType.icon_camera_overturn.load()
                flipCameraComponent.iconFrontFacingCamera = ZegoUIKitCallIconSetType.icon_camera_overturn.load()
                flipCameraComponent.delegate = self
                if let switchCameraFrontImage = buttonConfig.switchCameraFrontImage {
                    flipCameraComponent.iconFrontFacingCamera = switchCameraFrontImage
                }
                if let switchCameraBackImage = buttonConfig.switchCameraBackImage {
                    flipCameraComponent.iconBackFacingCamera = switchCameraBackImage
                }
                self.buttons.append(flipCameraComponent)
                self.addSubview(flipCameraComponent)
            case .toggleCameraButton:
                let switchCameraComponent: ZegoToggleCameraButton = ZegoToggleCameraButton()
                switchCameraComponent.isOn = self.config.turnOnCameraWhenJoining
                switchCameraComponent.userID = ZegoUIKit.shared.localUserInfo?.userID
                switchCameraComponent.delegate = self
                if let toggleCameraOnImage = buttonConfig.toggleCameraOnImage {
                    switchCameraComponent.iconCameraOn = toggleCameraOnImage
                }
                if let toggleCameraOffImage = buttonConfig.toggleCameraOffImage {
                    switchCameraComponent.iconCameraOff = toggleCameraOffImage
                }
                self.buttons.append(switchCameraComponent)
                self.addSubview(switchCameraComponent)
            case .toggleMicrophoneButton:
                let micButtonComponent: ZegoToggleMicrophoneButton = ZegoToggleMicrophoneButton()
                micButtonComponent.userID = ZegoUIKit.shared.localUserInfo?.userID
                micButtonComponent.isOn = self.config.turnOnMicrophoneWhenJoining
                micButtonComponent.delegate = self
                if let toggleMicrophoneOnImage = buttonConfig.toggleMicrophoneOnImage {
                    micButtonComponent.iconMicrophoneOn = toggleMicrophoneOnImage
                }
                if let toggleMicrophoneOffImage = buttonConfig.toggleMicrophoneOffImage {
                    micButtonComponent.iconMicrophoneOff = toggleMicrophoneOffImage
                }
                self.buttons.append(micButtonComponent)
                self.addSubview(micButtonComponent)
            case .switchAudioOutputButton:
                let audioOutputButtonComponent: ZegoSwitchAudioOutputButton = ZegoSwitchAudioOutputButton()
                audioOutputButtonComponent.delegate = self
                if let audioOutputSpeakerImage = buttonConfig.audioOutputSpeakerImage {
                    audioOutputButtonComponent.iconSpeaker = audioOutputSpeakerImage
                }
                if let audioOutputHeadphoneImage = buttonConfig.audioOutputEarSpeakerImage {
                    audioOutputButtonComponent.iconEarSpeaker = audioOutputHeadphoneImage
                }
                if let audioOutputBluetoothImage = buttonConfig.audioOutputBluetoothImage {
                    audioOutputButtonComponent.iconBluetooth = audioOutputBluetoothImage
                }
                audioOutputButtonComponent.useSpeaker = self.config.useSpeakerWhenJoining
                self.buttons.append(audioOutputButtonComponent)
                self.addSubview(audioOutputButtonComponent)
            case .hangUpButton:
                let endButtonComponent: ZegoLeaveButton = ZegoLeaveButton()
                if let leaveConfirmDialogInfo = self.config.hangUpConfirmDialogInfo {
                    if leaveConfirmDialogInfo.title == "" || leaveConfirmDialogInfo.title == nil {
                        leaveConfirmDialogInfo.title = self.config.zegoCallText.leaveRoomTextDialogTitle                    }
                    if leaveConfirmDialogInfo.message == "" || leaveConfirmDialogInfo.title == nil {
                        leaveConfirmDialogInfo.message = self.config.zegoCallText.leaveRoomTextDialogMessage
                    }
                    if leaveConfirmDialogInfo.cancelButtonName == "" || leaveConfirmDialogInfo.cancelButtonName == nil  {
                        leaveConfirmDialogInfo.cancelButtonName = self.config.zegoCallText.cancelDialogMessage
                    }
                    if leaveConfirmDialogInfo.confirmButtonName == "" || leaveConfirmDialogInfo.confirmButtonName == nil  {
                        leaveConfirmDialogInfo.confirmButtonName = self.config.zegoCallText.confirmDialogMessage
                    }
                    if leaveConfirmDialogInfo.dialogPresentVC == nil  {
                        leaveConfirmDialogInfo.dialogPresentVC = self.showQuitDialogVC
                    }
                    endButtonComponent.quitConfirmDialogInfo = leaveConfirmDialogInfo
                }
                endButtonComponent.delegate = self
                if let hangUpButtonImage = buttonConfig.hangUpButtonImage {
                    endButtonComponent.iconLeave = hangUpButtonImage
                }
                self.buttons.append(endButtonComponent)
                self.addSubview(endButtonComponent)
            case .showMemberListButton:
                let memberButton: ZegoCallMemberButton = ZegoCallMemberButton()
                if let showMemberListButtonImage = buttonConfig.showMemberListButtonImage {
                    memberButton.iconMember = showMemberListButtonImage
                }
                self.buttons.append(memberButton)
                self.addSubview(memberButton)
                memberButton.addTarget(self, action: #selector(memberButtonClick), for: .touchUpInside)
            case .chatButton:
                let messageButton: ZegoCallChatButton = ZegoCallChatButton()
                if let chatButtonImage = buttonConfig.chatButtonImage {
                    messageButton.iconChat = chatButtonImage
                }
                self.buttons.append(messageButton)
                self.addSubview(messageButton)
                messageButton.addTarget(self, action: #selector(messageButtonClick), for: .touchUpInside)
            case .minimizingButton:
                let minimizingButton = ZegoMinimizationButton()
                minimizingButton.delegate = self
                if let minimizingButtonImage = buttonConfig.minimizingButtonImage {
                    minimizingButton.iconMinimize = minimizingButtonImage
                }
                self.buttons.append(minimizingButton)
                self.addSubview(minimizingButton)
            }
        }
    }
    
    @objc func memberButtonClick() {
        let memberListView: ZegoCallMemberList = ZegoCallMemberList()
        memberListView.showCameraStateOnMemberList = self.config.memberListConfig.showCameraState
        memberListView.showMicroPhoneStateOnMemberList = self.config.memberListConfig.showMicrophoneState
        memberListView.delegate = self.showQuitDialogVC as? ZegoCallMemberListDelegate
        memberListView.frame = CGRect(x: 0, y: 0, width: self.showQuitDialogVC?.view.frame.size.width ?? UIKitScreenWidth, height:self.showQuitDialogVC?.view.frame.size.height ?? UIkitScreenHeight)
        self.showQuitDialogVC?.view.addSubview(memberListView)
    }
    
    @objc func messageButtonClick() {
        let messageView: ZegoCallChatView = ZegoCallChatView(frame: CGRectZero, zegoCallText: self.config.zegoCallText)
        messageView.delegate = self.showQuitDialogVC as? ZegoCallChatViewDelegate
        messageView.frame = CGRect(x: 0, y: 0, width:self.showQuitDialogVC?.view.frame.size.width ?? UIKitScreenWidth, height:self.showQuitDialogVC?.view.frame.size.height ?? UIkitScreenHeight )
        self.showQuitDialogVC?.view.addSubview(messageView)
    }

}

extension ZegoTopMenuBar: LeaveButtonDelegate,
                          ZegoMinimizationButtonDelegate,
                          ZegoSwitchCameraButtonDelegate,
                          ZegoToggleCameraButtonDelegate,
                          ToggleMicrophoneButtonDelegate,
                          ToggleAudioOutputButtonDelegate {
    func onSwitchCameraButtonClick(_ isFrontFacing: Bool) {
        delegate?.onSwitchCameraButtonClick(isFrontFacing)
    }
    
    func onToggleCameraButtonClick(_ isOn: Bool) {
        delegate?.onToggleCameraButtonClick(isOn)
    }
    
    func onToggleMicButtonClick(_ isOn: Bool) {
        delegate?.onToggleMicButtonClick(isOn)
    }
    
    func onAudioOutputButtonClick(_ isSpeaker: Bool) {
        delegate?.onAudioOutputButtonClick(isSpeaker)
    }
    
    func onLeaveButtonClick(_ isLeave: Bool) {
        delegate?.onHangUp(isLeave)
        if isLeave {
            showQuitDialogVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func onMinimizationButtonDidClick() {
        delegate?.onMinimizationButtonDidClick()
    }
}
