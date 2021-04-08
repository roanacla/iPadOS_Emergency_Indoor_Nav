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
    let edges = [("R-A1","R-A2"),
                 ("R-A1","W-5"),
                 ("R-A2","W-7"),
                 ("R-B1","R-B2"),
                 ("R-B1","W-8"),
                 ("R-B2","W-23"),
                 ("R-C1","R-C2"),
                 ("R-C1","W-13"),
                 ("R-C2","W-14"),
                 ("R-D1","R-D2"),
                 ("R-D1","W-18"),
                 ("R-D2","W-19"),
                 ("R-E1","W-21"),
                 ("R-F1","W-20"),
                 ("R-G1","W-1"),
                 ("R-H1","W-2"),
                 ("R-I1","W-3"),
                 ("R-M1","R-M2"),
                 ("R-M1","W-9"),
                 ("R-M2","W-10"),
                 ("R-M3","R-M1"),
                 ("R-M3","R-M2"),
                 ("R-M3","W-11"),
                 ("R-N1","W-22"),
                 ("W-1","W-2"),
                 ("W-10","W-12"),
                 ("W-11","W-12"),
                 ("W-12","W-15"),
                 ("W-13","W-12"),
                 ("W-13","W-15"),
                 ("W-14","W-15"),
                 ("W-14","W-17"),
                 ("W-15","W-16"),
                 ("W-17","W-15"),
                 ("W-18","W-17"),
                 ("W-19","W-18"),
                 ("W-2","W-3"),
                 ("W-20","W-21"),
                 ("W-21","W-22"),
                 ("W-22","W-17"),
                 ("W-23","W-12"),
                 ("W-3","W-4"),
                 ("W-4","W-6"),
                 ("W-5","W-6"),
                 ("W-6","W-9"),
                 ("W-7","W-9"),
                 ("W-8","W-9"),
                 ("W-9","W-10")]
    
    let api = EdgeAmplifyAPI()
    for edge in edges {
      let source = ioTDict[edge.0]
      let destination = ioTDict[edge.1]
      
      api
        .create(id: UUID().uuidString,
                 buildingId: "id001",
                 sourceIoTId: source!,
                 destinationIoTId: destination!,
                 isActive: true)
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
