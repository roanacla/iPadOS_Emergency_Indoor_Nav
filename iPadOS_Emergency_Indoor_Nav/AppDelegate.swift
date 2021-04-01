//
//  AppDelegate.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 3/29/21.
//

import UIKit
import Amplify
import AmplifyPlugins
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var safeRegions: [SafeRegion] = []
  var beaconsDict: [String: Beacon] = [:]

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    do {
      Amplify.Logging.logLevel = .verbose
      try Amplify.add(plugin: AWSCognitoAuthPlugin())
      try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
      try Amplify.configure()
    } catch {
      print("An error occurred setting up Amplify: \(error)")
    }
    
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

extension AppDelegate {
  
  func createUserSubs() -> AnyCancellable {
    let useCase = CreateUserUseCase(userID: UserDefaultsData.userID,
                                    tokenID: UserDefaultsData.deviceTokenId,
                                    remoteAPI: MobileUserAmplifyAPI())
    return useCase.start()
  }
  
  func updateToken() -> AnyCancellable {
    let useCase = UpdateDeviceTokenIdUseCase(userID: UserDefaultsData.userID,
                                             tokenID: UserDefaultsData.deviceTokenId,
                                             remoteAPI: MobileUserAmplifyAPI())
    return useCase.start()
  }
  
  
  func updateLocation() -> AnyCancellable? {
    guard let beacon = beaconsDict.randomElement() else { return nil }
//    let beacon = beaconsDict.filter({$0.key == "W-1"}).first!
    let updateLocationUseCase = UpdateLocationUseCase(userID: UserDefaultsData.userID,
                                                      tokenID: UserDefaultsData.deviceTokenId,
                                                      location: beacon.value.name,
                                                      remoteAPI: MobileUserAmplifyAPI())

    return updateLocationUseCase.start()
  }
  
  func loadBeacons() {
    guard let entries = loadPlist(for: "Beacons") else { fatalError("Unable to load data") }
    
    for property in entries {
      guard let name = property["Name"] as? String,
            let latitude = property["Latitude"] as? NSNumber,
            let longitude = property["Longitude"] as? NSNumber else { fatalError("Error reading data") }
      
      let beacon = Beacon(name: name, latitude: latitude.doubleValue, longitude: longitude.doubleValue)
      beaconsDict[beacon.name] = beacon
    }
  }
  
  func loadSafeRegions() {
    guard let entries = loadPlist(for: "SafeRegions") else { fatalError("Unable to load data") }
    
    for property in entries {
      guard let name = property["Name"] as? String,
            let latitude = property["Latitude"] as? NSNumber,
            let longitude = property["Longitude"] as? NSNumber else { fatalError("Error reading data") }

      let safeRegion = SafeRegion(latitude: latitude.doubleValue, longitude: longitude.doubleValue, name: name)
      safeRegions.append(safeRegion)
    }
  }
  
  private func loadPlist(for filename: String) -> [[String: Any]]? {
    guard let plistUrl = Bundle.main.url(forResource: filename, withExtension: "plist"),
      let plistData = try? Data(contentsOf: plistUrl) else { return nil }
    var placedEntries: [[String: Any]]? = nil
    
    do {
      placedEntries = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [[String: Any]]
    } catch {
      print("error reading plist")
    }
    return placedEntries
  }
  
}
