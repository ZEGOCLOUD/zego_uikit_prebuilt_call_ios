//
//  ZegoMenuBar.swift
//  ZegoUIKit
//
//  Created by zego on 2022/7/18.
//

import UIKit
import ZegoUIKit

protocol ZegoCallLightBottomMenuBarDelegate: AnyObject {
    func onMenuBarMoreButtonClick(_ buttonList: [UIView])
    func onHangUp(_ isHandup: Bool)
    func onMinimizationButtonDidClick()
    func onSwitchCameraButtonClick(_ isFrontFacing: Bool)
    func onToggleCameraButtonClick(_ isOn: Bool)
    func onToggleMicButtonClick(_ isOn: Bool)
    func onAudioOutputButtonClick(_ isSpeaker: Bool)
}

extension ZegoCallLightBottomMenuBarDelegate {
    func onMenuBarMoreButtonClick(_ buttonList: [UIView]) { }
    func onHangUp(_ isHandup: Bool){ }
    func onMinimizationButtonDidClick() {}
}

class ZegoCallLightBottomMenuBar: UIView {
    
    public var userID: String?
    public var config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() {
        didSet {
            self.barButtons = config.bottomMenuBarConfig.buttons
        }
    }
    public weak var delegate: ZegoCallLightBottomMenuBarDelegate?
    
    
    weak var showQuitDialogVC: UIViewController?
    
    private var buttons: [UIView] = []
    private var moreButtonList: [UIView] = []
    private var barButtons:[ZegoMenuBarButtonName] = [] {
        didSet {
            self.createButton()
            self.setupLayout()
        }
    }
    private var margin: CGFloat {
        get {
            if buttons.count >= 5 {
                return adaptLandscapeWidth(21.5)
            } else if buttons.count == 4 {
                return adaptLandscapeWidth(36)
            } else if buttons.count == 3 {
                return adaptLandscapeWidth(55.5)
            } else if buttons.count == 2 {
                return adaptLandscapeWidth(100)
            } else {
                return 0
            }
        }
    }
    private var itemSpace: CGFloat {
        get {
            if buttons.count >= 5 {
                return adaptLandscapeWidth(23)
            } else if buttons.count == 4 {
                return adaptLandscapeWidth(37)
            } else if buttons.count == 3 {
                return adaptLandscapeWidth(59.5)
            } else if buttons.count == 2 {
                return adaptLandscapeWidth(79)
            } else {
                return 0
            }
         }
    }
    
    let itemSize: CGSize = CGSize.init(width: adaptLandscapeWidth(48), height: adaptLandscapeWidth(48))
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.createButton()
        self.setupLayout()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    /// 添加自定义按钮
    /// - Parameter button: <#button description#>
    public func addButtonToMenuBar(_ button: UIButton) {
        if self.buttons.count > self.config.bottomMenuBarConfig.maxCount - 1 {
            if self.buttons.last is CallMoreButton {
                self.moreButtonList.append(button)
                return
            }
            //替换最后一个元素
            let moreButton: CallMoreButton = CallMoreButton()
            moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
            self.addSubview(moreButton)
            let lastButton: UIButton = self.buttons.last as! UIButton
            lastButton.removeFromSuperview()
            self.moreButtonList.append(lastButton)
            self.moreButtonList.append(button)
            self.buttons.replaceSubrange(4...4, with: [moreButton])
        } else {
            self.buttons.append(button)
            self.addSubview(button)
        }
        self.setupLayout()
    }
    
    
    //MARK: -private
    private func setupLayout() {
        switch self.buttons.count {
        case 1:
            break
        case 2:
            self.layoutViewWithButton()
            break
        case 3:
            self.layoutViewWithButton()
            break
        case 4:
            self.layoutViewWithButton()
            break
        case 5:
            self.layoutViewWithButton()
        default:
            break
        }
    }
    
    private func replayAddAllView() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        for item in self.buttons {
            self.addSubview(item)
        }
    }
    
    private func layoutViewWithButton() {
        var index: Int = 0
        var lastView: UIView?
        for button in self.buttons {
            if index == 0 {
                button.frame = CGRect.init(x: self.margin, y: adaptLandscapeHeight(6.5), width: itemSize.width, height: itemSize.width)
            } else {
                if let lastView = lastView {
                    button.frame = CGRect.init(x: lastView.frame.maxX + itemSpace, y: lastView.frame.minY, width: itemSize.width, height: itemSize.height)
                }
            }
            lastView = button
            index = index + 1
        }
    }
    
    
    private func createButton() {
        self.buttons.removeAll()
        var index = 0
        for item in self.barButtons {
            index = index + 1
            if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index == self.config.bottomMenuBarConfig.maxCount {
                //显示更多按钮
                let moreButton: CallMoreButton = CallMoreButton()
                moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
                self.buttons.append(moreButton)
                self.addSubview(moreButton)
            }
            switch item {
            case .switchCameraButton:
                let flipCameraComponent: ZegoSwitchCameraButton = ZegoSwitchCameraButton()
                flipCameraComponent.delegate = self
                saveButton(flipCameraComponent, index: index)
            case .toggleCameraButton:
                let switchCameraComponent: ZegoToggleCameraButton = ZegoToggleCameraButton()
                switchCameraComponent.isOn = self.config.turnOnCameraWhenJoining
                switchCameraComponent.userID = ZegoUIKit.shared.localUserInfo?.userID
                switchCameraComponent.delegate = self
                saveButton(switchCameraComponent, index: index)
            case .toggleMicrophoneButton:
                let micButtonComponent: ZegoToggleMicrophoneButton = ZegoToggleMicrophoneButton()
                micButtonComponent.userID = ZegoUIKit.shared.localUserInfo?.userID
                micButtonComponent.isOn = self.config.turnOnMicrophoneWhenJoining
                micButtonComponent.delegate = self
                saveButton(micButtonComponent, index: index)
            case .swtichAudioOutputButton:
                let audioOutputButtonComponent: ZegoSwitchAudioOutputButton = ZegoSwitchAudioOutputButton()
                audioOutputButtonComponent.useSpeaker = self.config.useSpeakerWhenJoining
                audioOutputButtonComponent.delegate = self
                saveButton(audioOutputButtonComponent, index: index)
            case .hangUpButton:
                let endButtonComponent: ZegoLeaveButton = ZegoLeaveButton()
                if let leaveConfirmDialogInfo = self.config.hangUpConfirmDialogInfo {
                    if leaveConfirmDialogInfo.title == "" || leaveConfirmDialogInfo.title == nil {
                        leaveConfirmDialogInfo.title = "Leave the room"
                    }
                    if leaveConfirmDialogInfo.message == "" || leaveConfirmDialogInfo.title == nil {
                        leaveConfirmDialogInfo.message = "Are you sure to leave the room?"
                    }
                    if leaveConfirmDialogInfo.cancelButtonName == "" || leaveConfirmDialogInfo.cancelButtonName == nil  {
                        leaveConfirmDialogInfo.cancelButtonName = "Cancel"
                    }
                    if leaveConfirmDialogInfo.confirmButtonName == "" || leaveConfirmDialogInfo.confirmButtonName == nil  {
                        leaveConfirmDialogInfo.confirmButtonName = "Confirm"
                    }
                    if leaveConfirmDialogInfo.dialogPresentVC == nil  {
                        leaveConfirmDialogInfo.dialogPresentVC = self.showQuitDialogVC
                    }
                    endButtonComponent.quitConfirmDialogInfo = leaveConfirmDialogInfo
                }
                endButtonComponent.delegate = self
                saveButton(endButtonComponent, index: index)
            case .showMemberListButton:
                let memberButton: ZegoCallMemberButton = ZegoCallMemberButton()
                memberButton.addTarget(self, action: #selector(memberButtonClick), for: .touchUpInside)
                saveButton(memberButton, index: index)
            case .chatButton:
                let messageButton: ZegoCallChatButton = ZegoCallChatButton()
                messageButton.addTarget(self, action: #selector(messageButtonClick), for: .touchUpInside)
                saveButton(messageButton, index: index)
            case .minimizingButton:
                let minimizingButton = ZegoMinimizationButton()
                minimizingButton.delegate = self
                saveButton(minimizingButton, index: index)
            }
        }
    }
    
    private func saveButton(_ button: UIButton, index: Int) {
        if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
            self.moreButtonList.append(button)
        } else {
            self.buttons.append(button)
            self.addSubview(button)
        }
    }
    
    @objc func moreClick() {
        //更多按钮点击事件
        self.delegate?.onMenuBarMoreButtonClick(self.moreButtonList)
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
        let messageView: ZegoCallChatView = ZegoCallChatView()
        messageView.delegate = self.showQuitDialogVC as? ZegoCallChatViewDelegate
        messageView.frame = CGRect(x: 0, y: 0, width:self.showQuitDialogVC?.view.frame.size.width ?? UIKitScreenWidth, height:self.showQuitDialogVC?.view.frame.size.height ?? UIkitScreenHeight )
        self.showQuitDialogVC?.view.addSubview(messageView)
    }
    
}

extension ZegoCallLightBottomMenuBar: LeaveButtonDelegate,
                                      ZegoMinimizationButtonDelegate,
                                      ZegoSwitchCameraButtonDelegate,
                                      ZegoToggleCameraButtonDelegate,
                                      ToggleMicrophoneButtonDelegate,
                                      ToggleAudioOutputButtonDelegate {
    func onLeaveButtonClick(_ isLeave: Bool) {
        delegate?.onHangUp(isLeave)
        if isLeave {
            showQuitDialogVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func onMinimizationButtonDidClick() {
        delegate?.onMinimizationButtonDidClick()
    }
    
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
}

class CallMoreButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(ZegoUIKitCallIconSetType.icon_more.load(), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
