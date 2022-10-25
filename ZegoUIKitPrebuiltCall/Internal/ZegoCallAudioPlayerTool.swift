//
//  ZegoCallAudioPlayerTool.swift
//  ZegoUIKitCallWithInvitation
//
//  Created by zego on 2022/10/14.
//

import UIKit
import AVFAudio

class ZegoCallAudioPlayerTool: NSObject {
        
      static var backgrndSound: AVAudioPlayer?
    
     // AVAudioPlayer already has an isPlaying property
       class func isMusicPlaying() -> Bool
       {
          return backgrndSound?.isPlaying ?? false
       }
       
       class func startPlay(_ resourcePath: String)
       {
          let url = URL(fileURLWithPath: resourcePath)
          do
          {
             backgrndSound = try AVAudioPlayer(contentsOf: url)
             backgrndSound?.numberOfLoops = -1
             backgrndSound?.currentTime = 0
             backgrndSound?.prepareToPlay()
             backgrndSound?.play()
          }
          catch
          {
             // couldn't load file :(
          }
       }
       
       class func stopPlay()
       {
           if isMusicPlaying() {
               backgrndSound?.pause()
               backgrndSound?.stop()
           }
       }

}
