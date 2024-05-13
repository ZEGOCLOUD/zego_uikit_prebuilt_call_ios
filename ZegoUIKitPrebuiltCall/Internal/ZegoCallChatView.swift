//
//  ZegoCallChatView.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/10/18.
//

import UIKit
import ZegoUIKit

@objc protocol ZegoCallChatViewDelegate: AnyObject {
    @objc optional func getChatViewItemView(_ tableView: UITableView, indexPath: IndexPath, message: ZegoInRoomMessage) -> UITableViewCell?
    @objc optional func getChatViewItemHeight(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, message: ZegoInRoomMessage) -> CGFloat
}

class ZegoCallChatView: UIView {
    
    weak var delegate: ZegoCallChatViewDelegate?
    
    let help: ZegoCallChatView_Help = ZegoCallChatView_Help()
    
    var lastFrame: CGRect = CGRect.zero
    var zegoCallText: ZegoCallText = ZegoCallText(language: .ENGLISH)
    lazy var backgroundView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#171821", alpha: 0.6)
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(hidenChatView))
        view.addGestureRecognizer(tapClick)
        return view
    }()
    
    lazy var messageInputView: ZegoInRoomMessageInput = {
        let inputView = ZegoInRoomMessageInput()
        inputView.minHeight = 55
        inputView.placeHolder = self.zegoCallText.sendMessageAllPeopleMessage
        return inputView
    }()
    
    lazy var bottomMaskView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#222222")
        return view
    }()
    
    lazy var messageView: ZegoInRoomChatView = {
        let chatView = ZegoInRoomChatView()
        chatView.delegate = self.help
        chatView.backgroundColor = UIColor.colorWithHexString("#222222")

        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(messageViewTapClick))
        chatView.addGestureRecognizer(tapClick)
        return chatView
    }()

    public init(frame: CGRect,zegoCallText: ZegoCallText?) {
        super.init(frame: frame)
        self.help.chatView = self
        if let zegoCallText = zegoCallText {
          self.zegoCallText = zegoCallText
          self.help.zegoCallText = zegoCallText;
        }
        self.addSubview(self.backgroundView)
        self.addSubview(self.bottomMaskView)
        self.addSubview(self.messageView)
        self.addSubview(self.messageInputView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(node:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    public override var frame: CGRect {
        didSet {
            if frame.equalTo(lastFrame) {
                return
            }
            self.messageInputView.frame = CGRect(x: 0, y: frame.size.height - 55 - UIKitBottomSafeAreaHeight, width: frame.size.width, height: 55)
            let messageViewHeight: CGFloat = (self.frame.size.height - UIKitBottomSafeAreaHeight - 55) * 0.85
            self.messageView.frame = CGRect(x: 0, y: self.messageInputView.frame.minY - messageViewHeight, width: self.frame.size.width, height: messageViewHeight)
            self.messageView.addCorner(conrners: [.topLeft,.topRight], radius: 23)
            self.lastFrame = frame
        }
    }
    
    @objc func keyboardWillChangeFrame(node : Notification){
            // 1.获取动画执行的时间
            let duration = node.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
            // 2.获取键盘最终 Y值
            let endFrame = (node.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let y = endFrame.origin.y
            
            //3计算工具栏距离底部的间距
            let margin = UIScreen.main.bounds.size.height - y
            //4.执行动画
            UIView.animate(withDuration: duration) {
                self.layoutIfNeeded()
                let messageViewHeight: CGFloat = (self.frame.size.height - UIKitBottomSafeAreaHeight - 55) * 0.85
                if margin > 0 {
                    self.messageInputView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - margin - 55, width: UIScreen.main.bounds.size.width, height: 55)
                    self.messageView.frame = CGRect(x: 0, y: self.messageView.frame.origin.y, width: self.messageView.frame.size.width, height: messageViewHeight - margin + UIKitBottomSafeAreaHeight)
                    self.messageView.scrollToLastLine()
                } else {
                    self.messageInputView.frame = CGRect(x: 0, y: self.frame.size.height - margin - 55 - UIKitBottomSafeAreaHeight, width: UIScreen.main.bounds.size.width, height: 55)
                    self.messageView.frame = CGRect(x: 0, y: self.messageInputView.frame.minY - messageViewHeight, width: self.messageView.frame.size.width, height:messageViewHeight)
                }
                
            }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    func setupLayout() {
        self.backgroundView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height - 55 - UIKitBottomSafeAreaHeight)
        self.bottomMaskView.frame = CGRect(x: 0, y: self.frame.size.height - UIKitBottomSafeAreaHeight, width: self.frame.size.width, height: UIKitBottomSafeAreaHeight)
    }
    
    @objc func hidenChatView() {
        self.removeFromSuperview()
    }
    
    @objc func messageViewTapClick() {
        self.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class ZegoCallChatView_Help: NSObject, ZegoInRoomChatViewDelegate {
    
    weak var chatView: ZegoCallChatView?
    var zegoCallText: ZegoCallText = ZegoCallText(language: .ENGLISH)
    func getChatViewHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat {
        return 49.0
    }
  
    func getChatViewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#222222")
        let closeButton: UIButton = UIButton()
        closeButton.frame = CGRect(x: 11.5, y: 7.5, width: 35, height: 35)
        closeButton.setImage(ZegoUIKitCallIconSetType.icon_back.load(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
        view.addSubview(closeButton)
        let label: UILabel = UILabel()
        label.frame = CGRect(x: closeButton.frame.maxX + 5, y: 11, width: 100, height: 27)
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = self.zegoCallText.chatViewHeaderTitle
        label.textColor = UIColor.white
        view.addSubview(label)
        return view
    }
    
    func getChatViewItemView(_ tableView: UITableView, indexPath: IndexPath, message: ZegoInRoomMessage) -> UITableViewCell? {
        return self.chatView?.delegate?.getChatViewItemView?(tableView, indexPath: indexPath, message: message)
    }
    
    func getChatViewItemHeight(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, message: ZegoInRoomMessage) -> CGFloat {
        return self.chatView?.delegate?.getChatViewItemHeight?(tableView, heightForRowAt: indexPath, message: message) ?? -1
    }
    
    @objc func closeButtonClick() {
        self.chatView?.removeFromSuperview()
    }
}
