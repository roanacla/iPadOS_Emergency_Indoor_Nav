// swiftlint:disable all
import Amplify
import Foundation

public struct Edge: Model {
  public let id: String
  public var buildingId: String
  public var sourceIoTId: String
  public var sourceIoT: IoT?
  public var destinationIoTId: String
  public var destinationIoT: IoT?
  public var isActive: Bool
  public var canBeDeactivated: Bool
  
  public init(id: String = UUID().uuidString,
      buildingId: String,
      sourceIoTId: String,
      sourceIoT: IoT? = nil,
      destinationIoTId: String,
      destinationIoT: IoT? = nil,
      isActive: Bool,
      canBeDeactivated: Bool) {
      self.id = id
      self.buildingId = buildingId
      self.sourceIoTId = sourceIoTId
      self.sourceIoT = sourceIoT
      self.destinationIoTId = destinationIoTId
      self.destinationIoT = destinationIoT
      self.isActive = isActive
      self.canBeDeactivated = canBeDeactivated
  }
}