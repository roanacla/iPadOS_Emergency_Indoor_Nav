//
//  DataUploader.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/8/21.
//

import Foundation
import Combine
import Amplify

class DataUploader {
  
  static let shared = DataUploader()
  var building: Building?
  var ioTDict: [String: String] = [:]
  private var combineSubscriptions = Set<AnyCancellable>()
  private init(){
    
  }
  
  func uploadData() {
    loadBuilding()
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
      self.loadIoTs()
    }
    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
      self.loadEdges()
    }
  }
  
  func loadBuilding() {
    building = Building(id: "id001")
    let buildingAPI = BuildingAmplifyAPI()
    buildingAPI.create(id: building!.id).store(in: &combineSubscriptions)
  }
  
  func loadIoTs() {
    guard let entries = loadPlist(for: "IoTs") else { fatalError("Unable to load data") }
    
    for property in entries {
      guard let name = property["Name"] as? String,
            let latitude = property["Latitude"] as? NSNumber,
            let longitude = property["Longitude"] as? NSNumber,
            let number = property["Number"] as? NSNumber else { fatalError("Error reading data") }
      
      let ioTID = UUID().uuidString
      CRUDIoTUseCase(id: ioTID,
                     name: name,
                     latitude: latitude.doubleValue,
                     longitude: longitude.doubleValue,
                     number: number.intValue,
                     remoteAPI: IoTAmplifyAPI())
        .start()
        .store(in: &combineSubscriptions)
      ioTDict[name] = ioTID
    }
  }
  
  func loadEdges() {
    let edges = [("R-A1","R-A2",false,"",0.0,0.0),//can be deactivated
                 ("R-A1","W-5",true,"B-5", -121.89012676477431, 37.32892165050638),
                 ("R-A2","W-7",true,"B-7", -121.88966274261475, 37.32910240554742),
                 ("R-B1","R-B2",false,"",0.0,0.0),//can be deactivated
                 ("R-B1","W-8",true,"B-8", -121.88944078981878, 37.32912373354719),
                 ("R-B2","W-23",true,"B-23", -121.88898950815201, 37.32933168122753),
                 ("R-C1","R-C2",false,"",0.0,0.0),
                 ("R-C1","W-13",true,"B-13", -121.888762190938, 37.32933754641018),
                 ("R-C2","W-14",true,"B-14", -121.88831493258476, 37.32955189186158),
                 ("R-D1","R-D2",false,"",0.0,0.0),//can be deactivated
                 ("R-D1","W-18",true,"B-18", -121.88809365034103, 37.329534829559506),
                 ("R-D2","W-19",true,"B-19", -121.88784286379814, 37.329209578685),
                 ("R-E1","W-21",false,"",0.0,0.0),
                 ("R-F1","W-20",false,"",0.0,0.0),
                 ("R-G1","W-1",false,"",0.0,0.0),
                 ("R-H1","W-2",false,"",0.0,0.0),
                 ("R-I1","W-3",false,"",0.0,0.0),
                 ("R-M1","R-M2",false,"",0.0,0.0),//can be deactivated
                 ("R-M1","W-9",true,"B-9", -121.88946962356567, 37.32932581604445),
                 ("R-M2","W-10",true,"B-10", -121.88928857445717, 37.329407928566134),
                 ("R-M3","R-M1",false,"",0.0,0.0),//can be deactivated
                 ("R-M3","R-M2",false,"",0.0,0.0),//can be deactivated
                 ("R-M3","W-11",false,"",0.0,0.0),//can be deactivated
                 ("R-N1","W-22",false,"",0.0,0.0),
                 ("W-1","W-2",false,"",0.0,0.0),
                 ("W-10","W-12",false,"",0.0,0.0),
                 ("W-11","W-12",false,"",0.0,0.0),
                 ("W-12","W-15",false,"",0.0,0.0),
                 ("W-13","W-12",false,"",0.0,0.0),
                 ("W-13","W-15",false,"",0.0,0.0),
                 ("W-14","W-15",false,"",0.0,0.0),
                 ("W-14","W-17",false,"",0.0,0.0),
                 ("W-15","W-16",false,"",0.0,0.0),
                 ("W-17","W-15",false,"",0.0,0.0),
                 ("W-18","W-17",false,"",0.0,0.0),
                 ("W-19","W-18",false,"",0.0,0.0),
                 ("W-2","W-3",false,"",0.0,0.0),
                 ("W-20","W-21",false,"",0.0,0.0),
                 ("W-21","W-22",false,"",0.0,0.0),
                 ("W-22","W-17",false,"",0.0,0.0),
                 ("W-23","W-12",false,"",0.0,0.0),
                 ("W-3","W-4",false,"",0.0,0.0),
                 ("W-4","W-6",false,"",0.0,0.0),
                 ("W-5","W-6",false,"",0.0,0.0),
                 ("W-6","W-9",false,"",0.0,0.0),
                 ("W-7","W-9",false,"",0.0,0.0),
                 ("W-8","W-9",false,"",0.0,0.0),
                 ("W-9","W-10",false,"",0.0,0.0)]
    
    let api = EdgeAmplifyAPI()
    for edge in edges {
      let source = ioTDict[edge.0]
      let destination = ioTDict[edge.1]
      
      api
        .create(id: UUID().uuidString,
                 buildingId: "id001",
                 sourceIoTId: source!,
                 destinationIoTId: destination!,
                 isActive: false,
                 canBeDeactivated: edge.2,
                 name: edge.3,
                 latitude: edge.5,
                 longitude: edge.4)
        .store(in: &combineSubscriptions)
    }
  }
  
  private func loadPlist(for filename: String) -> [[String: Any]]? {
    guard let plistUrl = Bundle.main.url(forResource: filename, withExtension: "plist"),
      let plistData = try? Data(contentsOf: plistUrl) else { return nil }
    var placedEntries: [[String: Any]]? = nil
    
    do {
      placedEntries = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [[String: Any]]
    } catch {
      print("error reading plist")
    }
    return placedEntries
  }
}
