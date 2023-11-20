//
//  ZegoPipSourceView.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/11/16.
//

import UIKit

class ZegoPipSourceView: UIView {
    
    lazy var timeLabel: UILabel = {
        let label: UILabel = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
        addSubview(timeLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        timeLabel.frame = CGRect(x: 0, y: (bounds.height - 20) / 2 - 10, width: bounds.width, height: 20)
    }
    
    func updateTime(time: Int) {
        
    }
    
}
