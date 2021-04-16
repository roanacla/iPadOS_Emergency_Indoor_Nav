//
//  MobileUserRemoteAPI.swift
//  iOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 2/1/21.
//

import Foundation
import Combine



protocol BuildingRemoteAPI {
  //Subscriptions
  func create(id: String) -> AnyCancellable
  
  func get(id: String) -> AnyPublisher<Building?,Error>
  func getEdges(id: String) -> AnyPublisher<[Edge],Error>
  func getMobileUsers(id: String) -> AnyPublisher<[MobileUser]?,Error>
  func updateIsInEmergency(id: String, isInEmergency: Bool, description: String) -> AnyCancellable
  func getBuildingWithNestedObjects(id: String) -> AnyPublisher<Building, Error>
}

protocol EdgeRemoteAPI {
  func create(id: String,
              buildingId: String,
              sourceIoTId: String,
              destinationIoTId: String,
              isActive: Bool,
              canBeDeactivated: Bool,
              name: String,
              latitude: Double,
              longitude: Double) -> AnyCancellable
}

protocol IoTRemoteAPI {
  func create(id: String, name: String, number: Int, latitude: Double, longitud: Double) -> AnyCancellable
}

protocol MobileUserRemoteAPI {
  //Subscriptions
  func create(userID: String, tokenID: String) -> AnyCancellable
  func getMobileUser(userID: String) -> AnyCancellable
  func updateLocation(userID: String, location: String) -> AnyCancellable
  func updateDeviceTokenId(userID: String, newToken: String) -> AnyCancellable
  
  //Publishers
  func getMobileUser(withID id: String) -> AnyPublisher<MobileUser?,Error>
}
