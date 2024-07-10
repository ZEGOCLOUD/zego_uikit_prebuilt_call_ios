//
//  ZegoCallAudioPlayerTool.swift
//  ZegoUIKitCallWithInvitation
//
//  Created by zego on 2022/10/14.
//

import UIKit
import AVFAudio

class ZegoCallAudioPlayerTool: NSObject {
        
      static var backgroundSound: AVAudioPlayer?
    
     // AVAudioPlayer already has an isPlaying property
       class func isMusicPlaying() -> Bool
       {
          return backgroundSound?.isPlaying ?? false
       }
       
       class func startPlay(_ resourcePath: String)
       {
          let url = URL(fileURLWithPath: resourcePath)
          do
          {
             backgroundSound = try AVAudioPlayer(contentsOf: url)
             backgroundSound?.numberOfLoops = -1
             backgroundSound?.currentTime = 0
             backgroundSound?.prepareToPlay()
             backgroundSound?.play()
          }
          catch
          {
             // couldn't load file :(
          }
       }
       
       class func stopPlay()
       {
           if isMusicPlaying() {
               backgroundSound?.pause()
               backgroundSound?.stop()
           }
       }

}
