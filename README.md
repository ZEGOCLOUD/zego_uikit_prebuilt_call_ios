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

<img src="http://doc.oa.zego.im/Pics/ZegoUIKit/iOS/config_device_permissions.png" width = 600>


## Run & Test

Now you have finished all the steps!

You can simply click the **Run** on XCode to run and test your App on your device.



## Related guide

[Custom prebuilt UI](!ZEGOUIKIT_Custom_prebuilt_UI)

## Resources

<div class="md-grid-list-box">
  <a href="https://github.com/ZEGOCLOUD/zego_uikit_prebuilt_call_example/tree/master/basic_call/ios" class="md-grid-item" target="_blank">
    <div class="grid-title">Sample code</div>
    <div class="grid-desc">Click here to get the complete sample code.</div>
  </a>
</div>

Read the documentation [here](https://docs.zegocloud.com/article/14763)