//
//  BlockAreas.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/16/21.
//

import Foundation
import MapKit

class BlockedArea: NSObject {
  
  var latitude: Double
  var longitude: Double
  var name: String?
  var isActive: Bool
  
  var location: CLLocation {
    return CLLocation(latitude: latitude, longitude: longitude)
  }
  
  init(latitude: Double, longitude: Double, name: String?, isActive: Bool) {
    self.latitude = latitude
    self.longitude = longitude
    self.name = name
    self.isActive = isActive
  }
  
}

extension BlockedArea: MKAnnotation {
  var coordinate: CLLocationCoordinate2D {
    get {
      return self.location.coordinate      
    }
  }
  
  var title: String? {
    get {
      return name
    }
  }
  
}
