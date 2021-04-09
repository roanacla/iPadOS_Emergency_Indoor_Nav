//
//  BuildingUseCase.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/8/21.
//

import Foundation
import Combine

struct BuildingUseCase {
  
  func toogleAlarm(remoteAPI: BuildingRemoteAPI, buildingID id: String, isInEmergency: Bool, description: String = "Fire") -> AnyCancellable {
    return remoteAPI.updateIsInEmergency(id: id, isInEmergency: isInEmergency, description: description)
  }
  
  func getAllEdges(remoteAPI: BuildingRemoteAPI, buildingId: String) -> AnyPublisher<[Edge],Error> {
    return remoteAPI.getEdges(id: buildingId)
  }
}
