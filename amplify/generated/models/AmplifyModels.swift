// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "2acf177b73c6ae7a300118fb5df40647"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Building.self)
    ModelRegistry.register(modelType: Edge.self)
    ModelRegistry.register(modelType: IoT.self)
    ModelRegistry.register(modelType: MobileUser.self)
  }
}