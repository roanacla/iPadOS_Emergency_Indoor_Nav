//
//  UseCase.swift
//  iOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 2/1/21.
//

import Foundation
import Combine

enum CRUDUseCase {
  case create
  case read
  case update
  case delete
}

protocol UseCase {
  func start() -> AnyCancellable
}
