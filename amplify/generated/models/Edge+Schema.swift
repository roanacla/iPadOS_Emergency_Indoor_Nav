// swiftlint:disable all
import Amplify
import Foundation

extension Edge {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case buildingId
    case sourceIoTId
    case sourceIoT
    case destinationIoTId
    case destinationIoT
    case isActive
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let edge = Edge.keys
    
    model.pluralName = "Edges"
    
    model.fields(
      .id(),
      .field(edge.buildingId, is: .required, ofType: .string),
      .field(edge.sourceIoTId, is: .required, ofType: .string),
      .hasOne(edge.sourceIoT, is: .optional, ofType: IoT.self, associatedWith: IoT.keys.id),
      .field(edge.destinationIoTId, is: .required, ofType: .string),
      .hasOne(edge.destinationIoT, is: .optional, ofType: IoT.self, associatedWith: IoT.keys.id),
      .field(edge.isActive, is: .optional, ofType: .bool)
    )
    }
}