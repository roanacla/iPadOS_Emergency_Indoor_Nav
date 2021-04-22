//
//  IoTAmplifyAPI.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/7/21.
//

import Foundation
import Combine
import Amplify

class IoTAmplifyAPI: IoTRemoteAPI {
  func create(id: String, name: String, number: Int, latitude: Double, longitud: Double) -> AnyCancellable {
    let device = IoT(id: id,
                     name: name,
                     number: number,
                     latitude: latitude,
                     longitude: longitud)
    return Amplify.API.mutate(request: .create(device))
      .resultPublisher
      .sink { (completion) in
        if case let .failure(error) = completion {
          print("🔴 Failed to create IoT graphql \(error)")
        }
      } receiveValue: { (result) in
        switch result {
        case .success(let device):
          print("🟢 Successfully created the Building : \(device)")
        case .failure(let graphQLError):
          print("Could not decode result: \(graphQLError)")
        }
      }
  }
  
  func list(buildingId: String) -> AnyPublisher<[Edge], Error> {
    let edge = Edge.keys
    let predicate = edge.buildingId == buildingId && edge.canBeDeactivated == true
    let result = Amplify.API
      .query(request: .list(Edge.self, where: predicate))
      .resultPublisher
      .tryMap { result -> [Edge] in
        return try result.get()
      }
      .eraseToAnyPublisher()
    
    return result
  }
  
  
}
