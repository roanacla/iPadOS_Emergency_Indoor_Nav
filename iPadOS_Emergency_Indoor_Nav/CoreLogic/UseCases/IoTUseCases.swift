//
//  IoTUseCases.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/21/21.
//

import Foundation
import Combine
import Amplify
struct IoTUseCases {
  
  func listIoTs(buildingId: String, remoteAPI: EdgeRemoteAPI) -> AnyPublisher<[Edge],Error> {
    return remoteAPI.list(buildingId: buildingId)
  }
  
}

class SettingsViewModel {
  @Published private(set) var edges: [Edge] = []
  @Published private(set) var currentEdge: Edge?
  
  var remoteAPI: EdgeRemoteAPI
  var subscriptions = Set<AnyCancellable>()
  
  init(remoteAPI: EdgeRemoteAPI) {
    self.remoteAPI = remoteAPI
  }
  
  func fetchIoTs(with buildingId: String) {
    remoteAPI.list(buildingId: buildingId)
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
  
  func updateEdge(atIndex index: Int, isActive: Bool) {
    let edge = edges[index]
    remoteAPI.updateIoT(edgeId: edge.id, isActive: isActive)
      .sink { [weak self](completion) in
        guard let self = self else { return }
        switch completion {
        case .finished:
          print("🟢 The Edge is been updated.")
        case .failure(let error):
          print("🔴 Failure to update Edge. \(error.localizedDescription)")
          self.edges[index].isActive = !isActive
        }
      } receiveValue: { [weak self] (edge) in
        self?.currentEdge = edge
        
      }
      .store(in: &subscriptions)
  }
}
