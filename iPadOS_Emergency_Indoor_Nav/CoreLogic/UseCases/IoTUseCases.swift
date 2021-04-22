//
//  IoTUseCases.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/21/21.
//

import Foundation
import Combine

struct IoTUseCases {
  
  func listIoTs(buildingId: String, remoteAPI: IoTRemoteAPI) -> AnyPublisher<[Edge],Error> {
    return remoteAPI.list(buildingId: buildingId)
  }
  
}
