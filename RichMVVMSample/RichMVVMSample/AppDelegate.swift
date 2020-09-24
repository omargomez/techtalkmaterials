//
//  AppDelegate.swift
//  RichMVVMSample
//
//  Created by Omar Eduardo Gomez Padilla on 23/09/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    #if HTTPSTUBS
    let dynamicStubs = HTTPDynamicStubs()
    #endif


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        #if HTTPSTUBS
            print("STUBS ON")
            dynamicStubs.setUp()
            dynamicStubs.setupStub(url: "/symbols", filename: "symbols")
            dynamicStubs.setupStub(url: "/convert", filename: "convert")
        #else
            print("STUBS OFF")
        #endif
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

