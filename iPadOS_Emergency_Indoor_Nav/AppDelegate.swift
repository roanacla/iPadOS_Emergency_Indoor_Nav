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
  var ioTDict: [String: String] = [:]
  var building: Building?
  var beaconsDict: [String: Beacon] = [:]
  private var combineSubscriptions = Set<AnyCancellable>()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    do {
      Amplify.Logging.logLevel = .verbose
      try Amplify.add(plugin: AWSCognitoAuthPlugin())
      try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
      try Amplify.configure()
    } catch {
      print("An error occurred setting up Amplify: \(error)")
    }

    loadBuilding()
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
      self.loadIoTs()
    }
    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
      self.loadEdges()
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
    guard let ioT = ioTDict.randomElement() else { return nil }
//    let beacon = beaconsDict.filter({$0.key == "W-1"}).first!
    let updateLocationUseCase = UpdateLocationUseCase(userID: UserDefaultsData.userID,
                                                      tokenID: UserDefaultsData.deviceTokenId,
                                                      location: ioT.key,
                                                      remoteAPI: MobileUserAmplifyAPI())

    return updateLocationUseCase.start()
  }
  
  func loadBuilding() {
    building = Building(id: "id001")
    let buildingAPI = BuildingAmplifyAPI()
    buildingAPI.create(id: building!.id).store(in: &combineSubscriptions)
  }
  
  func loadIoTs() {
    guard let entries = loadPlist(for: "IoTs") else { fatalError("Unable to load data") }
    
    for property in entries {
      guard let name = property["Name"] as? String,
            let latitude = property["Latitude"] as? NSNumber,
            let longitude = property["Longitude"] as? NSNumber,
            let number = property["Number"] as? NSNumber else { fatalError("Error reading data") }
      
      let ioTID = UUID().uuidString
      CRUDIoTUseCase(id: ioTID,
                     name: name,
                     latitude: latitude.doubleValue,
                     longitude: longitude.doubleValue,
                     number: number.intValue,
                     remoteAPI: IoTAmplifyAPI())
        .start()
        .store(in: &combineSubscriptions)
      ioTDict[name] = ioTID
    }
  }
  
  func loadEdges() {
    let edges = [("R-A1","R-A2"),
                 ("R-A1","W-5"),
                 ("R-A2","W-7"),
                 ("R-B1","R-B2"),
                 ("R-B1","W-8"),
                 ("R-B2","W-23"),
                 ("R-C1","R-C2"),
                 ("R-C1","W-13"),
                 ("R-C2","W-14"),
                 ("R-D1","R-D2"),
                 ("R-D1","W-18"),
                 ("R-D2","W-19"),
                 ("R-E1","W-21"),
                 ("R-F1","W-20"),
                 ("R-G1","W-1"),
                 ("R-H1","W-2"),
                 ("R-I1","W-3"),
                 ("R-M1","R-M2"),
                 ("R-M1","W-9"),
                 ("R-M2","W-10"),
                 ("R-M3","R-M1"),
                 ("R-M3","R-M2"),
                 ("R-M3","W-11"),
                 ("R-N1","W-22"),
                 ("W-1","W-2"),
                 ("W-10","W-12"),
                 ("W-11","W-12"),
                 ("W-12","W-15"),
                 ("W-13","W-12"),
                 ("W-13","W-15"),
                 ("W-14","W-15"),
                 ("W-14","W-17"),
                 ("W-15","W-16"),
                 ("W-17","W-15"),
                 ("W-18","W-17"),
                 ("W-19","W-18"),
                 ("W-2","W-3"),
                 ("W-20","W-21"),
                 ("W-21","W-22"),
                 ("W-22","W-17"),
                 ("W-23","W-12"),
                 ("W-3","W-4"),
                 ("W-4","W-6"),
                 ("W-5","W-6"),
                 ("W-6","W-9"),
                 ("W-7","W-9"),
                 ("W-8","W-9"),
                 ("W-9","W-10")]
    
    let api = EdgeAmplifyAPI()
    for edge in edges {
      let source = ioTDict[edge.0]
      let destination = ioTDict[edge.1]
      
      api
        .create(id: UUID().uuidString,
                 buildingId: "id001",
                 sourceIoTId: source!,
                 destinationIoTId: destination!,
                 isActive: true)
        .store(in: &combineSubscriptions)
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
