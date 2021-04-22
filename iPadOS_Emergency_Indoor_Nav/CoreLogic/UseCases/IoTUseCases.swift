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

class IoTSettingsViewModel {
  @Published private(set) var edges: [Edge] = []
  private var buildingId: String
  var subscriptions = Set<AnyCancellable>()
  
  init(buildingId: String) {
    self.buildingId = buildingId
    fetchIoTs()
  }
  
  func fetchIoTs() {
    let remoteIoT = IoTAmplifyAPI()
    remoteIoT.list(buildingId: self.buildingId)
      .sink { (completion) in
        switch completion {
        case .finished:
          print("🟢 All IoTs retrieved")
        case .failure(let error):
          print("🔴 Failure to retrieve IoTs\(error.localizedDescription)")
        }
      } receiveValue: { [weak self] (edges) in
        self?.edges = edges
      }
      .store(in: &subscriptions)
  }
}
