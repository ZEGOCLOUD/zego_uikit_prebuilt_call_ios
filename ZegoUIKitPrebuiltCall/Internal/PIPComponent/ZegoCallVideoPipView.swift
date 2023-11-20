//
//  ZegoCallPipView.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2023/11/14.
//

import UIKit
import ZegoUIKit
import AVFoundation
import AVKit
import ZegoExpressEngine

class ZegoCallVideoPipView: ZegoCallPipView {
    
    var config: ZegoLayoutPictureInPictureConfig?

    var isEnablePreview: Bool = true {
        didSet {
            previewView.isHidden = !isEnablePreview
        }
    }
    
    lazy var backgroundView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    lazy var displayView: ZegoVideoRenderView = {
        let view = ZegoVideoRenderView()
        return view
    }()
    
    lazy var previewView: ZegoVideoRenderView = {
        let view = ZegoVideoRenderView()
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        ZegoUIKit.shared.addEventHandler(self)
        addSubview(backgroundView)
        addSubview(displayView)
        addSubview(previewView)
        getUsers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        backgroundView.frame = bounds
        displayView.frame = bounds
        previewView.frame = CGRect(x: Int(bounds.size.width * 0.6), y: 10, width: Int(bounds.size.width * 0.4), height: Int((bounds.size.width * 0.4)) * 16 / 9)
    }
    
    func getUsers() {
        let users = ZegoUIKit.shared.getAllUsers()
        for user in users {
            if user.userID == ZegoUIKit.shared.localUserInfo?.userID {
                previewView.relevanceUser = user
            } else {
                displayView.relevanceUser = user
            }
        }
    }
    
    override func onRemoteVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, streamID: String) {
        DispatchQueue.main.async {
            self.displayView.onRemoteVideoFrameCVPixelBuffer(buffer, param: param, streamID: streamID)
        }
    }
    
    override func onCapturedVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, flipMode: ZegoVideoFlipMode, channel: ZegoPublishChannel) {
        DispatchQueue.main.async {
            self.previewView.onCapturedVideoFrameCVPixelBuffer(buffer, param: param, flipMode: flipMode, channel: channel)
        }
        
    }
}

extension ZegoCallVideoPipView: ZegoUIKitEventHandle {
    
    func onCameraOn(_ user: ZegoUIKitUser, isOn: Bool) {
        if user.userID == ZegoUIKit.shared.localUserInfo?.userID {
            previewView.onCameraOn(user, isOn: isOn)
        } else {
            displayView.onCameraOn(user, isOn: isOn)
        }
    }
}

class ZegoVideoRenderView: UIView {
    
    var displayLayer: AVSampleBufferDisplayLayer?
    var relevanceUser: ZegoUIKitUser? {
        didSet {
            if relevanceUser?.userID == ZegoUIKit.shared.localUserInfo?.userID {
                backgroundColor = UIColor.darkGray
            } else {
                backgroundColor = UIColor.black
            }
            headView.text = relevanceUser?.userName
            headView.isHidden = relevanceUser?.isCameraOn ?? true
        }
    }
    
    lazy var displayView: UIView = {
        let view = UIView()
        displayLayer = AVSampleBufferDisplayLayer()
        displayLayer?.videoGravity = .resizeAspect
        view.layer.addSublayer(displayLayer!)
        return view
    }()
    
    lazy var headView: ZegoPipHeadView = {
        let view = ZegoPipHeadView()
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headView)
        addSubview(displayView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        displayView.frame = bounds
        displayLayer?.frame = displayView.bounds
        let headW: CGFloat = 0.4 * bounds.width
        let headH: CGFloat = 0.4 * bounds.width
        headView.frame = CGRect(x: (bounds.width - headW) / 2, y: (bounds.height - headH) * 0.5, width: headW, height: headH)
    }
    
    func onRemoteVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, streamID: String) {
        let sampleBuffer: CMSampleBuffer? = createSampleBuffer(pixelBuffer: buffer)
        if let sampleBuffer = sampleBuffer {
            self.displayLayer?.enqueue(sampleBuffer)
            if self.displayLayer?.status == .failed {
                
            }
        }
    }
    
    func onCapturedVideoFrameCVPixelBuffer(_ buffer: CVPixelBuffer, param: ZegoVideoFrameParam, flipMode: ZegoVideoFlipMode, channel: ZegoPublishChannel) {
        let sampleBuffer: CMSampleBuffer? = createSampleBuffer(pixelBuffer: buffer)
        if let sampleBuffer = sampleBuffer {
            self.displayLayer?.enqueue(sampleBuffer)
        }
    }
    
    func createSampleBuffer(pixelBuffer: CVPixelBuffer?) -> CMSampleBuffer? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        
        // Do not set specific time info
        var timing = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: CMTime.invalid, decodeTimeStamp: CMTime.invalid)
        
        // Get video info
        var videoInfo: CMVideoFormatDescription? = nil
        let result = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
        guard result == noErr, let videoInfo = videoInfo else {
            assertionFailure("Error occurred: \(result)")
            return nil
        }
        
        var sampleBuffer: CMSampleBuffer? = nil
        let sampleBufferResult = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoInfo, sampleTiming: &timing, sampleBufferOut: &sampleBuffer)
        
        guard sampleBufferResult == noErr, let sampleBuffer = sampleBuffer else {
            assertionFailure("Error occurred: \(sampleBufferResult)")
            return nil
        }
        
        // Attachments settings
        let attachments: CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
        let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        CFDictionarySetValue(dict, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        
        return sampleBuffer
    }
    
    func onCameraOn(_ user: ZegoUIKitUser, isOn: Bool) {
        if user.userID == relevanceUser?.userID {
            displayView.isHidden = !isOn
            headView.isHidden = isOn
        }
    }
    
}

class ZegoPipHeadView: UIView {
    
    var font: UIFont? {
        didSet {
            guard let font = font else { return }
            self.headLabel.font = font
        }
    }
    
    var text: String? {
        didSet {
            guard let text = text else { return }
            if text.count > 0 {
                let firstStr: String = String(text[text.startIndex])
                self.headLabel.text = firstStr
            }
        }
    }
    
    var lastUrl: String?

    lazy var headLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.colorWithHexString("#222222")
        label.backgroundColor = UIColor.colorWithHexString("#DBDDE3")
        return label
    }()
    
    lazy var headImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.headLabel)
        self.addSubview(self.headImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.headLabel.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.headLabel.layer.masksToBounds = true
        self.headLabel.layer.cornerRadius = self.frame.size.width * 0.5
        self.headImageView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.headImageView.layer.masksToBounds = true
        self.headImageView.layer.cornerRadius = self.frame.size.width * 0.5
    }
    
    func setHeadLabelText(_ text: String) {
        self.headLabel.text = text
    }
}
