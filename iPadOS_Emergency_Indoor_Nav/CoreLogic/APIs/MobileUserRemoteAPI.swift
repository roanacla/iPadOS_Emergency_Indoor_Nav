//
//  MobileUserRemoteAPI.swift
//  iOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 2/1/21.
//

import Foundation
import Combine


protocol MobileUserRemoteAPI {
  //Subscriptions
  func create(userID: String, tokenID: String) -> AnyCancellable
  func getMobileUser(userID: String) -> AnyCancellable
  func updateLocation(userID: String, location: String) -> AnyCancellable
  func updateDeviceTokenId(userID: String, newToken: String) -> AnyCancellable
  
  //Publishers
  func getMobileUser(withID id: String) -> AnyPublisher<MobileUser?,Error>
}
