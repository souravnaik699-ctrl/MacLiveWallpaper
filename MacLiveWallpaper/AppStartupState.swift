//
//  AppStartupState.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//
import Foundation

enum AppStartupState: Equatable {

    case starting
    case ready
    case restoring
    case failed(String)
}
