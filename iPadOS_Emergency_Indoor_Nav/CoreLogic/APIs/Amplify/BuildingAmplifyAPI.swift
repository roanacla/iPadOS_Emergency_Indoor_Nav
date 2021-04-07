//
//  BuildingAmplifyAPI.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/6/21.
//

import Foundation
import Combine
import Amplify

public struct BuildingAmplifyAPI: BuildingRemoteAPI {
  func create(id: String) -> AnyCancellable {
    let building = Building(id: id)
    let sink = Amplify.API.mutate(request: .create(building))
      .resultPublisher
      .sink { completion in
        if case let .failure(error) = completion {
          print("🔴 Failed to create Building graphql \(error)")
        }
      }
      receiveValue: { result in
        switch result {
        case .success(let building):
          print("🟢 Successfully created the Building : \(building)")
        case .failure(let graphQLError):
          print("Could not decode result: \(graphQLError)")
        }
      }
    return sink
  }
  
  func get(id: String) -> AnyPublisher<Building?, Error> {
    Amplify.API
      .query(request: .get(Building.self, byId: id))
      .resultPublisher
      .tryMap { result -> Building? in
        //Cast Amplify publisher to AnyPublisher
        guard let building = try result.get() else { return nil}
        return building
      }
      .eraseToAnyPublisher()
  }
  
  func getEdges(id: String) -> AnyPublisher<[Edge]?, Error> {
    Amplify.API
      .query(request: .list(Edge.self))
      .resultPublisher
      .tryMap { result -> [Edge]? in
        return try result.get()
      }
      .eraseToAnyPublisher()
  }
  
  func getMobileUsers(id: String) -> AnyPublisher<[MobileUser]?, Error> {
    Amplify.API
      .query(request: .list(MobileUser.self))
      .resultPublisher
      .tryMap{ result -> [MobileUser]? in
        return try result.get()
      }
      .eraseToAnyPublisher()
  }
}
