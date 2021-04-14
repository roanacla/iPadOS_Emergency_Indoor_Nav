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
    let edges = [("R-A1","R-A2",true),
                 ("R-A1","W-5",true),
                 ("R-A2","W-7",true),
                 ("R-B1","R-B2",true),
                 ("R-B1","W-8",true),
                 ("R-B2","W-23",true),
                 ("R-C1","R-C2",true),
                 ("R-C1","W-13",true),
                 ("R-C2","W-14",true),
                 ("R-D1","R-D2",true),
                 ("R-D1","W-18",true),
                 ("R-D2","W-19",true),
                 ("R-E1","W-21",false),
                 ("R-F1","W-20",false),
                 ("R-G1","W-1",false),
                 ("R-H1","W-2",false),
                 ("R-I1","W-3",false),
                 ("R-M1","R-M2",true),
                 ("R-M1","W-9",true),
                 ("R-M2","W-10",true),
                 ("R-M3","R-M1",true),
                 ("R-M3","R-M2",true),
                 ("R-M3","W-11",true),
                 ("R-N1","W-22",false),
                 ("W-1","W-2",false),
                 ("W-10","W-12",false),
                 ("W-11","W-12",false),
                 ("W-12","W-15",false),
                 ("W-13","W-12",false),
                 ("W-13","W-15",false),
                 ("W-14","W-15",false),
                 ("W-14","W-17",false),
                 ("W-15","W-16",false),
                 ("W-17","W-15",false),
                 ("W-18","W-17",false),
                 ("W-19","W-18",false),
                 ("W-2","W-3",false),
                 ("W-20","W-21",false),
                 ("W-21","W-22",false),
                 ("W-22","W-17",false),
                 ("W-23","W-12",false),
                 ("W-3","W-4",false),
                 ("W-4","W-6",false),
                 ("W-5","W-6",false),
                 ("W-6","W-9",false),
                 ("W-7","W-9",false),
                 ("W-8","W-9",false),
                 ("W-9","W-10",false)]
    
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
                 canBeDeactivated: edge.2)
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
