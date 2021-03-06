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
  
  var buildingPublisher: AnyPublisher<Building,Error>?
  var viewModel: SettingsViewModel!
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    do {
      Amplify.Logging.logLevel = .verbose
      try Amplify.add(plugin: AWSCognitoAuthPlugin())
      try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
      try Amplify.configure()
      viewModel = SettingsViewModel(remoteAPI: EdgeAmplifyAPI())
      loadIoTs()
    } catch {
      print("An error occurred setting up Amplify: \(error)")
    }

    self.buildingPublisher = self.getBuildingWithNestedObjects()
    //Use the following line only to populate data on the cloud for the first time
//    DataUploader.shared.uploadData()
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
  
  func getBuildingWithNestedObjects() -> AnyPublisher<Building,Error> {
    return BuildingUseCase().getBuildingWithNestedObjects(remoteAPI: BuildingAmplifyAPI(),
                                                          buildingId: "id001")
  }
  
  var combineSubscribers = Set<AnyCancellable>()
  func loadIoTs() {
    viewModel.fetchIoTs(with: "id001")
  }
}
