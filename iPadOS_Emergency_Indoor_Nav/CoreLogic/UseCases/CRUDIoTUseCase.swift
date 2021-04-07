//
//  CRUDIoTUseCase.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/7/21.
//

import Foundation
import Combine

class CRUDIoTUseCase: UseCase {
  let id: String
  let name: String
  let latitude: Double
  let longitude: Double
  let number: Int
  let remoteAPI: IoTRemoteAPI
  
  init(id: String,
       name: String,
       latitude: Double,
       longitude: Double,
       number: Int,
       remoteAPI: IoTRemoteAPI) {
    
    self.id = id
    self.name = name
    self.latitude = latitude
    self.longitude = longitude
    self.number = number
    self.remoteAPI = remoteAPI
  }
  
  func start() -> AnyCancellable {
    return remoteAPI.create(id: id,
                            name: name,
                            number: number,
                            latitude: latitude,
                            longitud: longitude)
  }
}
