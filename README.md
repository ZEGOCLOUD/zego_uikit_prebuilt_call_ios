# Overview

- - -


[![](https://img.shields.io/badge/chat-on%20discord-7289da.svg)](https://discord.gg/EtNRATttyp)

> If you have any questions regarding bugs and feature requests, visit the [ZEGOCLOUD community](https://discord.gg/EtNRATttyp) .


**Call Kit** is a prebuilt feature-rich call component, which enables you to build **one-on-one and group voice/video calls** into your app with only a few lines of code.

And it includes the business logic with the UI, you can add or remove features accordingly by customizing UI components.


|One-on-one call|Group call|
|---|---|
|![One-on-one call](https://storage.zego.im/sdk-doc/Pics/ZegoUIKit/Flutter/_all_close.gif)|![Group call](https://storage.zego.im/sdk-doc/Pics/ZegoUIKit/conference/8C_little.jpg)|

[![Tutorial | How to build video call using iOS in 10 mins with ZEGOCLOUD](https://res.cloudinary.com/marcomontalbano/image/upload/v1682408159/video_to_markdown/images/youtube--LQXjqmWrQzI-c05b58ac6eb4c4700831b2b3070cd403.jpg)](https://youtu.be/LQXjqmWrQzI "Tutorial | How to build video call using iOS in 10 mins with ZEGOCLOUD")

## When do you need the Call Kit

- Build apps faster and easier
  - When you want to prototype 1-on-1 or group voice/video calls **ASAP** 

  - Consider **speed or efficiency** as the first priority

  - Call Kit allows you to integrate **in minutes**

- Customize UI and features as needed
  - When you want to customize in-call features **based on actual business needs**

  - **Less time wasted** developing basic features

  - Call Kit includes the business logic along with the UI, allows you to **customize features accordingly**


## Embedded features

- Ready-to-use one-on-one/group calls
- Customizable UI styles
- Real-time sound waves display
- Device management
- Switch views during a one-on-one call
- Extendable top/bottom menu bar
- Participant list

# Quick start

- - -

## Integrate the SDK

### Add ZegoUIKitPrebuiltCall as dependencies

- Add basic dependencies:
Open Terminal, navigate to the `Podfile` file, and run the following command:
    ```
    pod init
    pod 'ZegoUIKitPrebuiltCall'
    pod install
    ```


### Using the ZegoUIKitPrebuiltCallVC in your project

- Go to [ZEGOCLOUD Admin Console\|_blank](https://console.zegocloud.com/), get the `appID` and `appSign` of your project.
- Get the `userID` and `userName` for connecting the Video Call Kit service. 
- And also get a `callID` for making a call.

<div class="mk-hint">

- `userID` and `callID` can only contain numbers, letters, and underlines (_). 
- Users that join the call with the same `callID` can talk to each other. 
</div>

<pre style="background-color: #011627; border-radius: 8px; padding: 25px; color: white"><div>
// YourViewController.swift
class ViewController: UIViewController {
    // Others code...

    @IBAction func makeNewCall(_ sender: Any) {
        
        let config: ZegoUIkitPrebuiltCallConfig = ZegoUIkitPrebuiltCallConfig()
        let audioVideoConfig: ZegoAudioVideoViewConfig = ZegoAudioVideoViewConfig()
        let menuBarConfig: ZegoBottomMenuBarConfig = ZegoBottomMenuBarConfig()
        config.audioVideoViewConfig = audioVideoConfig
        config.bottomMenuBarConfig = menuBarConfig
        let layout: ZegoLayout = ZegoLayout()
        layout.mode = .pictureInPicture
        let pipConfig: ZegoLayoutPictureInPictureConfig = ZegoLayoutPictureInPictureConfig()
        pipConfig.smallViewPostion = .topRight
        layout.config = pipConfig
        config.layout = layout
        <div style="background-color:#032A4B; margin: 0px; padding: 2px;">
        let callVC = ZegoUIKitPrebuiltCallVC.init(yourAppID, 
                                                  appSign: yourAppSign, 
                                                  userID: self.selfUserID, 
                                                  userName: self.selfUserName ?? "", 
                                                  callID: self.callID, 
                                                  config: config)
        </div>
        callVC.modalPresentationStyle = .fullScreen
        self.present(callVC, animated: true, completion: nil)
    }
}

</div></pre>

Then, you can make a new call by presenting the `VC`.

## Configure your project


Open the `Info.plist`, add the following code inside the `dict` part:

```plist
<key>NSCameraUsageDescription</key>
<string>We require camera access to connect to a call</string>
<key>NSMicrophoneUsageDescription</key>
<string>We require microphone access to connect to a call</string>
```

<img src="https://storage.zego.im/sdk-doc/Pics/ZegoUIKit/iOS/config_device_permissions.png" width = 600>


## Run & Test

Now you have finished all the steps!

You can simply click the **Run** on XCode to run and test your App on your device.



## Recommended resources

[Custom prebuilt UI](https://docs.zegocloud.com/article/14765)

[Complete Sample Code](https://github.com/ZEGOCLOUD/zego_uikit_prebuilt_call_example_ios)

[About Us](https://www.zegocloud.com)
