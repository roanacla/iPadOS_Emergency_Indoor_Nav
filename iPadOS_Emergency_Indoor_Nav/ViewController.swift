//
//  ViewController.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 3/29/21.
//

import UIKit
import Combine
import Amplify

class ViewController: UIViewController {
  
  private var subscriptions = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    getMobileUsers()
      .store(in: &subscriptions)
  }
  
  func getMobileUsers() -> AnyCancellable {
    Amplify.API
      .query(request: .list(MobileUser.self))
      .resultPublisher
      .sink {
        if case let .failure(error) = $0 {
          print("Got failed event with error \(error)")
        }
      }
      receiveValue: { result in
        switch result {
        case .success(let todos):
          print("Successfully retrieved list of todos: \(todos)")
        case .failure(let error):
          print("Got failed result with \(error.errorDescription)")
        }
      }
  }
  
}

