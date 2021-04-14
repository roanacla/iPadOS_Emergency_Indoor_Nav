//
//  EdgesAmplifyAPI.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/7/21.
//

import Foundation
import Combine
import Amplify

class EdgeAmplifyAPI: EdgeRemoteAPI {
  func create(id: String,
              buildingId: String,
              sourceIoTId: String,
              destinationIoTId: String,
              isActive: Bool,
              canBeDeactivated: Bool) -> AnyCancellable {
    let edge = Edge(id: id,
                    buildingId: buildingId,
                    sourceIoTId: sourceIoTId,
                    destinationIoTId: destinationIoTId,
                    isActive: isActive,
                    canBeDeactivated: canBeDeactivated)
    
    
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
  
  
}
