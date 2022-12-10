//
//  SceneDelegate.swift
//  SolarMonitor
//
//  Created by Eric Vickery on 2/21/20.
//  Copyright © 2020 Eric Vickery. All rights reserved.
//

import UIKit
import SwiftUI
import CocoaMQTT

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var mqtt: CocoaMQTT?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        if let comboxDevice = BaseDevice.loadFromFile(deviceName: "Combox") as! Combox?
        {
            connectToCombox(combox: comboxDevice)

            let clientID = "SolarMonitor"
            mqtt = CocoaMQTT(clientID: clientID, host: "192.168.211.1", port: 1883)
            if let mqtt = mqtt
            {
                mqtt.allowUntrustCACertificate = true
                //            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
//                mqtt.logLevel = .debug
                mqtt.keepAlive = 60
//                mqtt.delegate = self
                mqtt.didReceiveMessage = { mqtt, message, id in
                    print("Message received in topic \(message.topic) with payload \(message.string!)")
                }
                mqtt.didChangeState = { mqtt, connectionState in
                    if connectionState == .connected
                    {
//                        mqtt.publish("dashbox/01001232/t1/val", withString: "", qos: .qos1, retained: true)
                        mqtt.subscribe("dashbox/01001232/t1/#", qos: CocoaMQTTQoS.qos1)
                        print("Connected")
                    }
                }
                _ = mqtt.connect()
            }
            // Create the SwiftUI view that provides the window contents.
            let contentView = ContentView(comboxDevice: comboxDevice)

            // Use a UIHostingController as window root view controller.
            if let windowScene = scene as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIHostingController(rootView: contentView)
                self.window = window
                window.makeKeyAndVisible()
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func connectToOutback(outback: Outback)
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            outback.connect(address: "192.168.211.11", port: 502, completionHandler: { result in
                if result
                {
                    outback.startGettingData()
                }
                else
                {
                    // There was an error loading try again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.connectToOutback(outback: outback)
                    }
                }
            })
        }
    }
    
    func connectToCombox(combox: Combox)
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            combox.connect(address: "192.168.211.10", port: 502, completionHandler: { result in
                if result
                {
                    combox.startGettingData()
                }
                else
                {
                    // There was an error loading try again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.connectToCombox(combox: combox)
                    }
                }
            })
        }
    }
}

