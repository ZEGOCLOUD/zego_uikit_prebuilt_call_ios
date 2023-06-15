//
//  ZegoConferenceMemberList.swift
//  ZegoPrebuiltVideoConferenceDemoDemo
//
//  Created by zego on 2022/9/14.
//

import UIKit
import ZegoUIKit

protocol ZegoConferenceMemberListDelegate: AnyObject {
    func getForegroundView(_ userInfo: ZegoUIKitUser?) -> UIView?
    func onLeaveVideoConference(_ isLeave: Bool)
    func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell?
    func getMemberListviewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView?
    func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat
    func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat
}

extension ZegoConferenceMemberListDelegate {
    func getForegroundView(_ userInfo: ZegoUIKitUser?) -> UIView? {nil}
    func onLeaveVideoConference(_ isLeave: Bool) { }
    func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell? { return nil }
    func getMemberListviewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? { return nil}
    func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat { 54 }
    func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat { return 65 }
}

class ZegoConferenceMemberList: UIView {
    
    var showMicroPhoneStateOnMemberList: Bool = true {
        didSet {
            self.memberList.showMicrophoneState = showMicroPhoneStateOnMemberList
        }
    }
    var showCameraStateOnMemberList: Bool = true {
        didSet {
            self.memberList.showCameraState = showCameraStateOnMemberList
        }
    }
    
    weak var delegate: ZegoConferenceMemberListDelegate?
    
    lazy var backgroundView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#171821", alpha: 0.6)
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(hidenMemberList))
        view.addGestureRecognizer(tapClick)
        return view
    }()
    
    lazy var memberList: ZegoMemberList = {
        let listView: ZegoMemberList = ZegoMemberList()
        listView.backgroundColor = UIColor.colorWithHexString("#242736")
        listView.delegate = self
        return listView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.backgroundView)
        self.addSubview(memberList)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout() {
        self.backgroundView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        let topTop: CGFloat = self.frame.size.height - (self.frame.size.height * 0.85)
        self.memberList.frame = CGRect(x: 0, y: topTop, width: self.frame.size.width, height: self.frame.size.height - topTop)
        self.memberList.addCorner(conrners: [.topLeft,.topRight], radius: 23)
    }
    
    @objc func hidenMemberList() {
        self.removeFromSuperview()
    }
    
    deinit {
        print("ZegoConferenceMemberList deinit")
    }
}

extension ZegoConferenceMemberList: ZegoMemberListDelegate, ZegoMemberListHeaderViewDelegate {
    
    func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell? {
        if let cell = self.delegate?.getMemberListItemView(tableView, indexPath: indexPath, userInfo: userInfo) {
            return cell
        } else {
            return nil
        }
    }
    
    func getMemberListviewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? {
        if let headView = self.delegate?.getMemberListviewForHeaderInSection(tableView, section: section) {
            return headView
        } else {
            let headView: ZegoMemberListHeaderView = ZegoMemberListHeaderView()
            headView.delegate = self
            return headView
        }
    }
    
    func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat {
        return self.delegate?.getMemberListItemHeight(userInfo) ?? 54
    }
    
    func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat {
        return self.delegate?.getMemberListHeaderHeight(tableView, section: section) ?? 65
    }
    
    func closeMemberListDidClick() {
        self.hidenMemberList()
    }
}

protocol ZegoMemberListHeaderViewDelegate: AnyObject {
    func closeMemberListDidClick()
}

class ZegoMemberListHeaderView: UIView {
    
    weak var delegate: ZegoMemberListHeaderViewDelegate?
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        button.setImage(ZegoUIKitCallIconSetType.icon_back.load(), for: .normal)
        return button
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Member"
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = UIColor.colorWithHexString("#FFFFFF")
        return label
    }()
    
    lazy var line: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#FFFFFF",alpha: 0.8)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.addSubview(self.closeButton)
        self.addSubview(self.titleLabel)
        self.addSubview(self.line)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    func setupLayout() {
        self.closeButton.frame = CGRect(x: 11.5, y: 7.5, width: 35, height: 35)
        self.titleLabel.frame = CGRect(x: self.closeButton.frame.maxX + 5, y: 12, width: 100, height: 25)
        self.line.frame = CGRect(x: 0, y: self.closeButton.frame.maxY + 6.5, width: self.frame.size.width, height: 0.5)
    }
    
    @objc func buttonClick() {
        self.delegate?.closeMemberListDidClick()
    }
    
}
