//
//  ZegoCallAudioPipView.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/11/16.
//

import UIKit

class ZegoCallAudioPipView: ZegoCallPipView {

    lazy var timeLabel: UILabel = {
        let label: UILabel = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.blue
        return label
    }()
    
    lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ZegoUIKitCallIconSetType.user_phone_icon.load()
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        addSubview(iconImage)
        addSubview(timeLabel)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapClick)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconImage.frame = CGRect(x: (bounds.size.width / 2) - 20, y: 0, width: 40, height: 40)
        timeLabel.frame = CGRect(x: 0, y: iconImage.frame.maxY, width: bounds.width, height: 20)
    }
    
    func updateTime(time: String) {
        timeLabel.text = time
    }
    
    @objc func tapClick(gesture: UITapGestureRecognizer) {
        ZegoMinimizeManager.shared.stopPiP()
    }

}
