//
//  1v1PrebuiltViewController.swift
//  ZegoUIKitExample
//
//  Created by zego on 2022/7/14.
//

import UIKit
import ZegoUIKit
import ZegoPrebuiltLog

class ZegoAudioCallWaitView : UIView {
  
    lazy var backgroundImage: UIImageView = {
      let bgImage = UIImageView()
      bgImage.contentMode = .scaleAspectFill
      return bgImage
    }()

   lazy var callStatusLabel: UILabel = {
     let label = UILabel()
     label.frame.size = CGSize(width: 100, height: 23)
     label.frame.origin.y = self.audioUserNameLabel.frame.origin.y + self.audioUserNameLabel.frame.size.height + 25
     label.center.x = UIScreen.main.bounds.width / 2
     label.font = UIFont.systemFont(ofSize: 16)
     label.textColor = UIColor.white
     label.textAlignment = .center
     return label
    }()
    
    lazy var audioUserIconLabel: UILabel = {
        let topPadding: CGFloat = UIKitKeyWindow?.safeAreaInsets.top ?? 0
        let label = UILabel()
        label.backgroundColor = UIColor.colorWithHexString("#DBDDE3")
        label.frame.size = CGSize(width: 100, height: 100)
        label.frame.origin.y = topPadding + 138
        label.center.x = UIScreen.main.bounds.width / 2
        label.clipsToBounds = true
        label.layer.cornerRadius = 50
        label.font = UIFont.systemFont(ofSize: 23)
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
  
    lazy var audioUserNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 21)
        label.frame.size = CGSize(width: 200, height: 30)
        label.frame.origin.y = self.audioUserIconLabel.frame.origin.y + self.audioUserIconLabel.frame.size.height + 5
        label.center.x = UIScreen.main.bounds.width / 2
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    lazy var userAvatarImage: UIImageView = {
        let userImage: UIImageView = UIImageView()
        userImage.clipsToBounds = true
        userImage.layer.cornerRadius = 50
        userImage.isHidden = true
        return userImage
    }()
  
    public init(frame: CGRect, userName:String, bgImage:UIImage, callingString:String) {
      super.init(frame: frame)
      self.addSubview(self.backgroundImage)
      self.addSubview(self.audioUserIconLabel)
      self.addSubview(self.audioUserNameLabel)
      self.addSubview(self.callStatusLabel)
      self.addSubview(self.userAvatarImage)
      self.audioUserIconLabel.text = String(userName.prefix(1))
      self.audioUserNameLabel.text = userName
      self.callStatusLabel.text = callingString
      self.backgroundImage.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
      self.backgroundImage.image = bgImage
      self.userAvatarImage.frame = self.audioUserIconLabel.frame
    }
  
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
      }
}

extension ZegoUIKitPrebuiltCallVC: CallVCApi {
    
    public func addButtonToBottomMenuBar(_ button: UIButton) {
        if self.config.bottomMenuBarConfig.style == .dark {
            self.menuBar.addButtonToMenuBar(button)
        } else {
            self.lightMenuBar.addButtonToMenuBar(button)
        }
    }
    
    public func addButtonToTopMenuBar(_ button: UIButton) {
        self.topBar.addButtonToMenuBar(button)
    }
    
    public func finish() {
        self.dismiss(animated: true, completion: nil)
    }
}

@objcMembers
open class ZegoUIKitPrebuiltCallVC: UIViewController {
    
    var bottomBarHeight: CGFloat = adaptLandscapeHeight(61) + UIKitBottomSafeAreaHeight
    var topMenuBarHeight: CGFloat {
        get {
            if UIKitBottomSafeAreaHeight > 0 {
                return 88
            } else {
                return 64
            }
        }
    }
    
    public weak var delegate: ZegoUIKitPrebuiltCallVCDelegate?
    
    private let help: ZegoUIKitPrebuiltCallVC_Help = ZegoUIKitPrebuiltCallVC_Help()
    fileprivate var config: ZegoUIKitPrebuiltCallConfig = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
    private var userID: String?
    private var userName: String?
    private var roomID: String?
    private var isHiddenMenuBar: Bool = false
    private var isHiddenTopMenuBar: Bool = false
    private var timer: ZegoTimer? = ZegoTimer(1000)
    private var timerCount: Int = 3
    private var currentBottomMenuBar: UIView?
    private var bottomBarY: CGFloat = 0
    private var topBarY: CGFloat = 0
    var lastFrame: CGRect = CGRect.zero
    let callDuration: ZegoCallDuration = ZegoCallDuration()
    lazy var callRoomForegroundBaseView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    lazy var avContainer: ZegoAudioVideoContainer = {
        let container: ZegoAudioVideoContainer = ZegoAudioVideoContainer()
        container.delegate = self.help
        return container
    }()
    
    lazy var menuBar: ZegoCallBottomMenuBar = {
        let menuBar = ZegoCallBottomMenuBar()
        menuBar.showQuitDialogVC = self
        menuBar.config = self.config
        menuBar.delegate = self
        menuBar.backgroundColor = UIColor.colorWithHexString("#222222", alpha: 0.9)
        return menuBar
    }()
    
    lazy var lightMenuBar: ZegoCallBottomMenuBar = {
        let menuBar = ZegoCallBottomMenuBar()
        menuBar.showQuitDialogVC = self
        menuBar.config = self.config
        menuBar.delegate = self
        return menuBar
    }()
    
    lazy var topBar: ZegoTopMenuBar = {
        let topMenuBar = ZegoTopMenuBar()
        topMenuBar.isHidden = !self.config.topMenuBarConfig.isVisible
        topMenuBar.titleLabel.textColor = UIColor.colorWithHexString("#FFFFFF")
        topMenuBar.titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        if self.config.topMenuBarConfig.style == .dark {
            topMenuBar.backgroundColor = UIColor.colorWithHexString("#222222",alpha: 0.9)
        } else {
            topMenuBar.backgroundColor = UIColor.clear
        }
        topMenuBar.showQuitDialogVC = self
        topMenuBar.config = self.config
        topMenuBar.delegate = self
        return topMenuBar
    }()
    
    lazy var callTimeLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.isHidden = !self.config.showCallDuration
        return label
    }()
    
    var waitingView: ZegoAudioCallWaitView?
    
    /// Initialization of call page
    /// - Parameters:
    ///   - appID: Your appID
    ///   - appSign: Your appSign
    ///   - userID: User unique identification
    ///   - userName: userName
    ///   - callID: call id
    ///   - config: call personalized configuration
    public init(_ appID: UInt32, appSign: String, userID: String, userName: String, callID: String, config: ZegoUIKitPrebuiltCallConfig?) {
        super.init(nibName: nil, bundle: nil)
        self.help.callVC = self
      
        let zegoLanguage: ZegoUIKitLanguage = config?.zegoCallText.getLanguage() ?? .ENGLISH
        let zegoUIKitLanguage = ZegoUIKitLanguage(rawValue: zegoLanguage.rawValue)!
        ZegoUIKitTranslationTextConfig.shared.translationText = ZegoUIKitTranslationText(language: zegoUIKitLanguage);
      
        ZegoUIKit.shared.addEventHandler(self.help)
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        self.userID = userID
        self.userName = userName
        self.roomID = callID
        if let config = config {
            ZegoUIKit.shared.setVideoConfig(config: config.videoConfig.resolution)
            self.config = config
        }
    }
    
    
    /// Initialization of call page
    /// - Parameters:
    ///   - data: Call invitation data
    ///   - config: call personalized configuration
    public init(_ data: ZegoCallInvitationData, config: ZegoUIKitPrebuiltCallConfig?) {
        super.init(nibName: nil, bundle: nil)
        self.help.callVC = self
        ZegoUIKit.shared.addEventHandler(self.help)
        self.userID = ZegoUIKit.shared.localUserInfo?.userID
        self.userName = ZegoUIKit.shared.localUserInfo?.userName
        self.roomID = data.callID
        if let config = config {
            ZegoUIKit.shared.setVideoConfig(config: config.videoConfig.resolution)
            self.config = config
        }
        
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallVC][init] userID:\(String(describing: self.userID)), userName:\(String(describing: self.userName)), roomID:\(String(describing: self.roomID))")
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        if self.config.turnOnCameraWhenJoining == false {
          self.joinRoomAudioWaitingView()
        }
        self.view.addSubview(self.avContainer.view)
        self.view.addSubview(self.callTimeLabel)
        self.view.addSubview(self.topBar)
        if self.config.bottomMenuBarConfig.style == .dark {
            self.currentBottomMenuBar = self.menuBar
            self.bottomBarHeight = adaptLandscapeHeight(104) + UIKitBottomSafeAreaHeight
            self.view.addSubview(self.menuBar)
        } else {
            self.currentBottomMenuBar = self.lightMenuBar
            self.bottomBarHeight = adaptLandscapeHeight(61) + UIKitBottomSafeAreaHeight
            self.view.addSubview(self.lightMenuBar)
        }
        let callRoomForegroundView: UIView? = delegate?.requireRoomForegroundView?()
        
        if let callRoomForegroundView = callRoomForegroundView {
            self.callRoomForegroundBaseView.addSubview(callRoomForegroundView)
            
            NSLayoutConstraint.activate([
                self.callRoomForegroundBaseView.leftAnchor.constraint(equalTo: callRoomForegroundView.leftAnchor,constant: 0),
                self.callRoomForegroundBaseView.rightAnchor.constraint(equalTo: callRoomForegroundView.rightAnchor,constant: 0),
                self.callRoomForegroundBaseView.topAnchor.constraint(equalTo: callRoomForegroundView.topAnchor,constant: 0),
                self.callRoomForegroundBaseView.bottomAnchor.constraint(equalTo: callRoomForegroundView.bottomAnchor,constant: 0),
            ])
            view.insertSubview(self.callRoomForegroundBaseView, aboveSubview: self.avContainer.view!)
        }
        
        ZegoMinimizeManager.shared.delegate = self
        ZegoMinimizeManager.shared.pipConfig = config.layout.config
        if config.topMenuBarConfig.buttons.contains(.minimizingButton) || config.bottomMenuBarConfig.buttons.contains(.minimizingButton) {
            if config.turnOnCameraWhenJoining && config.layout.mode == .pictureInPicture {
                ZegoMinimizeManager.shared.setupPipControllerWithSourceView(sourceView: view, isOneOnOneVideo: true)
            } else {
                ZegoMinimizeManager.shared.setupPipControllerWithSourceView(sourceView: view, isOneOnOneVideo: false)
            }
        }
        self.setupLayout()
        self.joinRoom()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer = nil
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.view.frame.equalTo(self.lastFrame) {
            self.avContainer.view.frame = CGRect(x: 0, y: UIKitTopSafeAreaHeight, width: self.view.frame.size.width, height: self.view.frame.size.height - UIKitTopSafeAreaHeight - UIKitBottomSafeAreaHeight)
            self.callTimeLabel.frame = CGRect(x: 100, y: UIKitTopSafeAreaHeight + 10, width: UIScreen.main.bounds.width - 200, height: 20)
            self.topBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.topMenuBarHeight)
            self.currentBottomMenuBar?.frame = CGRect.init(x: 0, y: self.view.frame.size.height - self.bottomBarHeight, width: self.view.frame.size.width, height: self.bottomBarHeight)
            self.menuBar.addCorner(conrners: [.topLeft,.topRight], radius: 16)
            self.lastFrame = self.view.frame
        }
    }
    
    func setupLayout() {
        let audioVideoConfig: ZegoAudioVideoViewConfig = ZegoAudioVideoViewConfig()
        audioVideoConfig.showSoundWavesInAudioMode = self.config.audioVideoViewConfig.showSoundWavesInAudioMode
        audioVideoConfig.useVideoViewAspectFill = self.config.audioVideoViewConfig.useVideoViewAspectFill
        self.avContainer.setLayout(self.config.layout, audioVideoConfig: audioVideoConfig)
        ZegoUIKit.shared.setAudioOutputToSpeaker(enable: self.config.useSpeakerWhenJoining)
        
        if config.bottomMenuBarConfig.style == .dark {
            self.currentBottomMenuBar?.backgroundColor = UIColor.colorWithHexString("#222222", alpha: 0.8)
        } else {
            self.currentBottomMenuBar?.backgroundColor = UIColor.clear
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
        self.view.addGestureRecognizer(tap)
        
        //5秒自动隐藏
        guard let timer = timer else {
            return
        }
        timer.setEventHandler {[weak self] in
            guard let self = self else { return }
            if self.timerCount == 0 {
                if self.config.bottomMenuBarConfig.hideAutomatically {
                    if !self.isHiddenMenuBar {
                        self.hiddenMenuBar(true)
                    }
                }
                if self.config.topMenuBarConfig.hideAutomatically {
                    if !self.isHiddenTopMenuBar {
                        self.hiddenTopMenuBar(isHidden: true)
                    }
                }
            } else {
                self.timerCount = self.timerCount - 1
            }
        }
        timer.start()
    }
    
    @objc func tapClick() {
        if self.config.bottomMenuBarConfig.hideByClick || self.config.topMenuBarConfig.hideByClick {
            if self.config.bottomMenuBarConfig.hideByClick {
                self.hiddenMenuBar(!self.isHiddenMenuBar)
            }
            if self.config.topMenuBarConfig.hideByClick {
                self.hiddenTopMenuBar(isHidden: !self.isHiddenTopMenuBar)
            }
            guard let timer = timer else {
                return
            }
            timer.start()
            self.timerCount = 3
        } else {
            if self.timerCount <= 0 {
                self.hiddenMenuBar(false)
                self.hiddenTopMenuBar(isHidden: false)
                guard let timer = timer else {
                    return
                }
                timer.start()
                self.timerCount = 3
            }
        }
    }
    
    private func hiddenMenuBar(_ isHidden: Bool) {
        self.isHiddenMenuBar = isHidden
        UIView.animate(withDuration: 0.5) {[weak self] in
            guard let self = self else { return }
            if self.config.bottomMenuBarConfig.hideAutomatically {
                let bottomY: CGFloat = isHidden ? UIScreen.main.bounds.size.height:UIScreen.main.bounds.size.height - self.bottomBarHeight
                self.currentBottomMenuBar?.frame = CGRect.init(x: 0, y: bottomY, width: UIScreen.main.bounds.size.width, height: self.bottomBarHeight)
            }
        }
    }
    
    private func hiddenTopMenuBar(isHidden: Bool) {
        self.isHiddenTopMenuBar = isHidden
        UIView.animate(withDuration: 0.5) {[weak self] in
            guard let self = self else { return }
            if self.config.topMenuBarConfig.hideAutomatically {
                let topY: CGFloat = isHidden ? -self.topMenuBarHeight : 0
                self.topBar.frame = CGRect.init(x: 0, y: topY, width: UIScreen.main.bounds.size.width, height: self.topMenuBarHeight)
            }
        }
    }
    
    @objc func buttonClick() {
        
    }
    
    private func joinRoom() {
        guard let roomID = self.roomID,
              let userID = self.userID,
              let userName = self.userName
        else {
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallVC][joinRoom] joinRoom check params fail")
            return
        }
        
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallVC][joinRoom] userID:\(userID), userName:\(userName), roomID:\(roomID)")
        ZegoUIKit.shared.joinRoom(userID, userName: userName, roomID: roomID) {[weak self] code in
            LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallVC][joinRoom] error:\(code)")
            
            guard let self = self else { return }
            if code == 0 {
              ZegoUIKit.shared.turnCameraOn(userID, isOn: self.config.turnOnCameraWhenJoining)
              ZegoUIKit.shared.turnMicrophoneOn(userID, isOn: self.config.turnOnMicrophoneWhenJoining)
              ZegoUIKit.shared.startPreview(self.view, videoMode: .aspectFill)
              callDuration.delegate = self
              callDuration.startTheTimer()
            }
        }
    }
    
    private func joinRoomAudioWaitingView() {
       let topPadding: CGFloat = UIKitKeyWindow?.safeAreaInsets.top ?? 0
       let bottomPadding: CGFloat = UIKitKeyWindow?.safeAreaInsets.bottom ?? 0
       self.waitingView = ZegoAudioCallWaitView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height + topPadding + bottomPadding), userName: self.userName ?? "",bgImage: ZegoUIKitCallIconSetType.call_waiting_bg.load(), callingString: self.config.zegoCallText.outgoingAudioCallPageMessage)
        let user: ZegoUIKitUser = ZegoUIKitUser(ZegoUIKit.shared.localUserInfo?.userID ?? "", ZegoUIKit.shared.localUserInfo?.userName ?? "")
        let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: user) ?? "") as String
        if userAvatar != ""{
            loadImage(imageUrl: userAvatar)
        }
        
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallVC][joinRoomAudioWaitingView] will addsubview waitingView")
        self.view.addSubview(self.waitingView!)
    }
    
    private func loadImage(imageUrl: String) {
        guard !imageUrl.isEmpty else {
            print("提供的图片 URL 为空")
            return
        }
        
        // 安全创建 URL 对象
        guard let url = URL(string: imageUrl) else {
            print("无效的图片 URL: \(imageUrl)")
            return
        }
        
        // 创建 URLSession 数据任务
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // 检查是否有错误发生
            if let error = error {
                print("加载图片出错: \(error)")
                return
            }
            
            // 检查是否有数据返回
            guard let data = data else {
                print("没有接收到数据")
                return
            }
            
            // 尝试将数据转换为 UIImage
            guard let image = UIImage(data: data) else {
                print("数据转换为 UIImage 失败")
                return
            }
            
            // 在主线程更新 UI
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.waitingView?.userAvatarImage.isHidden = false
                self.waitingView?.audioUserIconLabel.isHidden = true
                self.waitingView?.userAvatarImage.image = image
            }
        }
        
        // 启动数据任务
        task.resume()
    }
    deinit {
        callDuration.stopTheTimer()
        ZegoUIKit.shared.leaveRoom()
        print("CallViewController deinit")
    }
}

class ZegoUIKitPrebuiltCallVC_Help: NSObject, ZegoAudioVideoContainerDelegate, ZegoUIKitEventHandle {

    weak var callVC: ZegoUIKitPrebuiltCallVC?
    
    func onUserCountOrPropertyChanged(_ userList: [ZegoUIKitUser]?) {
        callVC?.waitingView?.removeFromSuperview()
        LogManager.sharedInstance().write("[PrebuiltCall][ZegoUIKitPrebuiltCallVC_Help][onUserCountOrPropertyChanged] did remove waitingView")
    }
    
    func onUserIDUpdated(userID: String) -> String? {
        let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: ZegoUIKitUser(userID, "")) ?? "") as String
        return userAvatar as String
    }
  
    func sortAudioVideo(_ userList: [ZegoUIKitUser]) -> [ZegoUIKitUser]? {
        if callVC?.config.layout.mode == .pictureInPicture {
            var tempList: [ZegoUIKitUser] = []
            if userList.count > 1 {
                var index = 0
                for user in userList {
                    let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: user) ?? "") as String
                    user.userAvatar = userAvatar
                    if index == 0 {
                        tempList.append(user)
                    } else {
                        if user.userID == ZegoUIKit.shared.localUserInfo?.userID {
                            tempList.append(user)
                        } else {
                            tempList.insert(user, at: 0)
                        }
                    }
                    index = index + 1
                }
            } else {
                for user in userList {
                    let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: user) ?? "") as String
                    user.userAvatar = userAvatar
                }
                tempList.append(contentsOf: userList)
            }
            return tempList
        } else {
            var tempList: [ZegoUIKitUser] = userList.reversed()
            var localUser: ZegoUIKitUser?
            var index = 0
            for user in tempList {
                if user.userID == ZegoUIKit.shared.localUserInfo?.userID {
                    localUser = user
                    let userAvatar:String = (ZegoUIKitPrebuiltCallInvitationService.shared.delegate?.onUserIDUpdated?(user: user) ?? "") as String
                    localUser?.userAvatar = userAvatar
                    tempList.remove(at: index)
                    break
                }
                index = index + 1
            }
            if let localUser = localUser {
                if tempList.count == 0 {
                    tempList.append(localUser)
                } else {
                    tempList.insert(localUser, at: 0)
                }
            }
            return tempList
        }
    }
    
    func onOnlySelfInRoom(_ userList:[ZegoUIKitUser]) {
        self.callVC?.delegate?.onOnlySelfInRoom?(userList)
    }
    
    func getForegroundView(_ userInfo: ZegoUIKitUser?) -> ZegoBaseAudioVideoForegroundView? {
        guard let userInfo = userInfo,
              let callVC = self.callVC
        else {
            return nil
        }
        
        let foregroundView: ZegoBaseAudioVideoForegroundView? = callVC.delegate?.getForegroundView?(userInfo)
        if let foregroundView = foregroundView {
            return foregroundView
        } else {
            // user normal foregroundView
            let normalForegroundView: ZegoCallNormalForegroundView = ZegoCallNormalForegroundView.init(callVC.config, userID: userInfo.userID, frame: .zero)
            normalForegroundView.userInfo = userInfo
            return normalForegroundView
        }
    }
    
    func textWidth(_ font: UIFont, text: String) -> CGFloat {
        let maxSize: CGSize = CGSize.init(width: 57, height: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let labelSize: CGRect = NSString(string: text).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return labelSize.width
    }
}

extension ZegoUIKitPrebuiltCallVC: ZegoCallBottomMenuBarDelegate, ZegoCallMemberListDelegate, ZegoCallChatViewDelegate, ZegoTopMenuBarDelegate {
    
    func onMenuBarMoreButtonClick(_ buttonList: [UIView]) {
        let newList:[UIView] = buttonList
        let vc: ZegoCallMoreView = ZegoCallMoreView()
        vc.buttonList = newList
        self.view.addSubview(vc.view)
        self.addChild(vc)
    }
    
    func onHangUp(_ isHandup: Bool) {
        let endEvent:ZegoCallEndEvent = ZegoCallEndEvent()
        endEvent.reason = .localHangUp
        endEvent.kickerUserID = ZegoUIKitPrebuiltCallInvitationService.shared.userID ?? ""
        self.delegate?.onCallEnd?(endEvent)
        if isHandup {
            ReportUtil.sharedInstance().reportEvent(callHangUpString, paramsDict: [:])
            self.dismiss(animated: true, completion: nil)
            ZegoCallAudioPlayerTool.stopPlay()
            guard let invitationData = ZegoUIKitPrebuiltCallInvitationService.shared.invitationData else { return }
            var needCancel: Bool = true
            if let invitees = ZegoUIKitPrebuiltCallInvitationService.shared.invitees {
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
                    ZegoUIKitSignalingPluginImpl.shared.cancelInvitation(cancelInvitees, data: nil, callback: nil)
                }
            }
            ZegoUIKitPrebuiltCallInvitationService.shared.invitationData = nil
            ZegoUIKitPrebuiltCallInvitationService.shared.callID = nil
        }
    }
    
    func onMinimizationButtonDidClick() {
        ZegoMinimizeManager.shared.callVC = self
        self.dismiss(animated: false)
    }
    
    func onSwitchCameraButtonClick(_ isFrontFacing: Bool) {
        delegate?.onSwitchCameraButtonClick?(isFrontFacing)
    }
    
    func onToggleCameraButtonClick(_ isOn: Bool) {
        delegate?.onToggleCameraButtonClick?(isOn)
    }
    
    func onToggleMicButtonClick(_ isOn: Bool) {
        delegate?.onToggleMicButtonClick?(isOn)
    }
    
    func onAudioOutputButtonClick(_ isSpeaker: Bool) {
        delegate?.onAudioOutputButtonClick?(isSpeaker)
    }
    
    func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell? {
        return self.delegate?.getMemberListItemView?(tableView, indexPath: indexPath, userInfo: userInfo)
    }
    
    func getMemberListViewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? {
        return self.delegate?.getMemberListViewForHeaderInSection?(tableView, section: section)
    }
    
    func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat {
        return self.delegate?.getMemberListItemHeight?(userInfo) ?? 54
    }
    
    func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat {
        return self.delegate?.getMemberListHeaderHeight?(tableView, section: section) ?? 65
    }
    
    //MARK: -ZegoCallChatViewDelegate
    func getChatViewItemView(_ tableView: UITableView, indexPath: IndexPath, message: ZegoInRoomMessage) -> UITableViewCell? {
        return self.delegate?.getChatViewItemView?(tableView, indexPath: indexPath, message: message)
    }
    
    func getChatViewItemHeight(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, message: ZegoInRoomMessage) -> CGFloat {
        return self.delegate?.getChatViewItemHeight?(tableView, heightForRowAt: indexPath, message: message) ?? -1
    }
}

extension ZegoUIKitPrebuiltCallVC: ZegoMinimizeManagerDelegate {
    func willStopPictureInPicture() {
        if let callVC = ZegoMinimizeManager.shared.callVC,
           ZegoMinimizeManager.shared.isNarrow
        {
            ZegoMinimizeManager.shared.isNarrow = false
            currentViewController()?.present(callVC, animated: false)
            ZegoMinimizeManager.shared.callVC = nil
        }
    }
}

extension ZegoUIKitPrebuiltCallVC: ZegoCallDurationDelegate {
    func onTimeUpdate(_ duration: Int, formattedString: String) {
        self.callTimeLabel.text = formattedString
        self.delegate?.onCallTimeUpdate?(duration)
        ZegoMinimizeManager.shared.updateCallTime(time: formattedString)
    }
}
