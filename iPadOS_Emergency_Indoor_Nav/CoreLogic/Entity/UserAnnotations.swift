//
//  UserAnnotations.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/27/21.
//

import Foundation
import MapKit

class UserAnnotation: NSObject {
  
  var latitude: Double
  var longitude: Double
  var name: String
  
  var location: CLLocation {
    return CLLocation(latitude: latitude, longitude: longitude)
  }
  
  init(latitude: Double, longitude: Double, name: String) {
    self.latitude = latitude
    self.longitude = longitude
    self.name = name
  }
  
}

extension UserAnnotation: MKAnnotation {
  
  var coordinate: CLLocationCoordinate2D {
    get {
      return self.location.coordinate
    }
  }
  
  var title: String? {
    get {
      return nil
    }
  }
  
}
