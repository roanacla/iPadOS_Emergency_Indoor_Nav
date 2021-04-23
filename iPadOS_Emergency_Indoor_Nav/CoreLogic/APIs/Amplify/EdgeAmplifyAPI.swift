//
//  EdgesAmplifyAPI.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/7/21.
//

import Foundation
import Combine
import Amplify

extension GraphQLRequest {
  static func updateEdgeIsActive(id: String, isActive: Bool) -> GraphQLRequest<Edge> {
    let operationName = "updateEdge"
    let document = """
        mutation updateEdgeIsActive($id: ID!, $isActive: Boolean!) {
           \(operationName)(input: {id: $id, isActive: $isActive}) {
              id
              buildingId
              sourceIoTId
              destinationIoTId
              isActive
              canBeDeactivated
            }
        }
        """
    return GraphQLRequest<Edge>(document: document,
                                     variables: ["id": id,
                                                 "isActive": isActive],
                                     responseType: Edge.self,
                                     decodePath: operationName)
  }
}

class EdgeAmplifyAPI: EdgeRemoteAPI {
  
  func create(id: String,
              buildingId: String,
              sourceIoTId: String,
              destinationIoTId: String,
              isActive: Bool,
              canBeDeactivated: Bool,
              name: String,
              latitude: Double,
              longitude: Double) -> AnyCancellable {
    let edge = Edge(id: id,
                    buildingId: buildingId,
                    sourceIoTId: sourceIoTId,
                    destinationIoTId: destinationIoTId,
                    isActive: isActive,
                    canBeDeactivated: canBeDeactivated,
                    name: name,
                    latitude: latitude,
                    longitude: longitude)
    
    
    return Amplify.API.mutate(request: .create(edge))
      .resultPublisher
      .sink { (completion) in
        if case let .failure(error) = completion {
          print("🔴 Failed to create Edge graphql \(error)")
        }
      } receiveValue: { (result) in
        switch result {
        case .success(let edge):
          print("🟢 Successfully created the Edge : \(edge)")
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
  
  func updateIoT(edgeId: String, isActive: Bool) -> AnyPublisher<Edge,Error> {
    Amplify.API.mutate(request: .updateEdgeIsActive(id: edgeId, isActive: isActive))
      .resultPublisher
      .tryMap { result -> Edge in
        return try result.get()
      }
      .eraseToAnyPublisher()
  }
  
}
