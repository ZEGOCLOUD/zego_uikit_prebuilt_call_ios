//
//  ZegoUIKitPrebuiteCallProvider+Plugin.swift
//  ZegoUIKitPrebuiltCall
//
//  Created by zego on 2024/8/6.
//

import Foundation
import ZegoPluginAdapter

extension ZegoUIKitPrebuiteCallProvider: ZegoPluginProvider {
  public func getPlugin() -> ZegoPluginProtocol? {
      ZegoUIKitPrebuiltCallPlugin.shared
  }
}
