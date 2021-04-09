//
//  BuildingAmplifyAPI.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/6/21.
//

import Foundation
import Combine
import Amplify

extension GraphQLRequest {
  static func updateBuildingEmergency(id: String, isInEmergency: Bool, emergencyDescription: String) -> GraphQLRequest<JSONValue> {
    let document = """
        mutation updateBuildingEmergency($id: ID!, $isInEmergency: Boolean, $emergencyDescription: String!) {
          updateBuilding(input: {id: $id, isInEmergency: $isInEmergency, emergencyDescription: $emergencyDescription}) {
            isInEmergency
          }
        }
        """
    return GraphQLRequest<JSONValue>(document: document,
                                     variables: ["id": id,
                                                 "isInEmergency": isInEmergency,
                                                 "emergencyDescription": emergencyDescription],
                                     responseType: JSONValue.self)
  }
}

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
  
  func updateIsInEmergency(id: String, isInEmergency: Bool, description: String) -> AnyCancellable {
    return Amplify.API.mutate(request: .updateBuildingEmergency(id: id, isInEmergency: isInEmergency, emergencyDescription: description))
      .resultPublisher
      .sink {
        if case let .failure(error) = $0 {
          print("🔴 Failed to update building emergency \(error)")
        }
      }
      receiveValue: { result in
        switch result {
        case .success(let building):
          print("🟢 Successfully updated building status: \(building)")
        case .failure(let error):
          print("🔴 Got failed result updating device location \(error.errorDescription)")
        }
      }
  }
}
