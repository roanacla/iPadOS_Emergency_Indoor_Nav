/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The main view controller.
 */

import UIKit
import CoreLocation
import MapKit
import Combine
import Amplify

class IndoorMapViewController: UIViewController, LevelPickerDelegate {
  //MARK: - IBOutlets
  @IBOutlet var mapView: MKMapView!
  let locationManager = CLLocationManager()
  @IBOutlet weak var trackMeButton: UIButton!
  @IBOutlet weak var emergencyKindLabel: UILabel!
  @IBOutlet weak var peopleInsideLabel: UILabel!
  @IBOutlet weak var peopleOutsideLabel: UILabel!
  
  
  //MARK: - Properties
  var currentLocation: CLLocation?
  private var subscriptions = Set<AnyCancellable>()
  var createSubscription: GraphQLSubscriptionOperation<MobileUser>?
  var deleteSubscription: GraphQLSubscriptionOperation<MobileUser>?
  var updateSubscription: GraphQLSubscriptionOperation<JSONValue>?
  var isTrackerEnabled = false {
    didSet {
      if isTrackerEnabled {
        locationManager.startUpdatingLocation()
      }
    }
  }
  var venue: Venue?
  var levels: [Level] = []
  var currentLevelFeatures = [StylableFeature]()
  var currentLevelOverlays = [MKOverlay]()
  var currentPathOverlay = MKPolyline()
  var currentLevelAnnotations = [MKAnnotation]()
  let pointAnnotationViewIdentifier = "PointAnnotationView"
  let labelAnnotationViewIdentifier = "LabelAnnotationView"
  private var buildingPublisher: AnyPublisher<Building, Error>? {
    return (UIApplication.shared.delegate as? AppDelegate)?.buildingPublisher
  }
  private var edges: [Edge] = []
  var blockedAreas: [BlockedArea] = []
  
  //MARK: - Animation Properties
  var pulseLayer: Pulsing?
  
  // MARK: - View life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //TODO: Use just to pin locations - Delete for production
//    let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(IndoorMapViewController.handleLongPress(_:)))
//    longPressRecogniser.minimumPressDuration = 1.0
//    mapView.addGestureRecognizer(longPressRecogniser)
    
    // Request location authorization so the user's current location can be displayed on the map
    locationManager.requestWhenInUseAuthorization()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.requestLocation()
    
    self.mapView.delegate = self
    self.mapView.register(PointAnnotationView.self, forAnnotationViewWithReuseIdentifier: pointAnnotationViewIdentifier)
    self.mapView.register(LabelAnnotationView.self, forAnnotationViewWithReuseIdentifier: labelAnnotationViewIdentifier)
    
    // Decode the IMDF data. In this case, IMDF data is stored locally in the current bundle.
    let imdfDirectory = Bundle.main.resourceURL!.appendingPathComponent("IMDFData")
    do {
      let imdfDecoder = IMDFDecoder()
      venue = try imdfDecoder.decode(imdfDirectory)
    } catch let error {
      print(error)
    }
    
    // You might have multiple levels per ordinal. A selected level picker item displays all levels with the same ordinal.
    if let levelsByOrdinal = self.venue?.levelsByOrdinal {
      let levels = levelsByOrdinal.mapValues { (levels: [Level]) -> [Level] in
        // Choose indoor level over outdoor level
        if let level = levels.first(where: { $0.properties.outdoor == false }) {
          return [level]
        } else {
          return [levels.first!]
        }
      }.flatMap({ $0.value })
      
      // Sort levels by their ordinal numbers
      self.levels = levels.sorted(by: { $0.properties.ordinal > $1.properties.ordinal })
    }
    
    // Set the map view's region to enclose the venue
    if let venue = venue, let venueOverlay = venue.geometry[0] as? MKOverlay {
      self.mapView.setVisibleMapRect(venueOverlay.boundingMapRect, edgePadding:
                                      UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: false)
      
      // Centers the map the first time
      let span = MKCoordinateSpan(latitudeDelta: 0.00275, longitudeDelta: 0.00275)
      let myLocation = CLLocationCoordinate2DMake(37.32940846176404,-121.88905656337738)
      let region = MKCoordinateRegion(center: myLocation, span: span)
      mapView.setRegion(region, animated: true)
      // The map rotates to focus the building
      mapView.camera.heading = CLLocationDirection(330)
    }
    
    // Display a default level at start, for example a level with ordinal 0
    showFeaturesForOrdinal(1)
    
    // Setup the level picker with the shortName of each level
    drawSafeArea()
    
    mapView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.tapAction)))
//    signInWithWebUI()
//      .store(in: &subscriptions)
//    fetchCurrentAuthSession()
//      .store(in: &subscriptions)
    getMobileUsers()
      .store(in: &subscriptions)
    establishCreateSubscription()
    establishDeleteSubscription()
    establishUpdateSubscription()
    //Get all edges before adding annotations
    subscribeToBuilding()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
//    subscribeChanges()
  }
  
  @objc func tapAction(gesture: UITapGestureRecognizer) {
    if isTrackerEnabled {
      DispatchQueue.main.async {
        self.trackMe(self)
      }
    }
  }
  
  //TODO: Use just to pin locations - Delete for production
//  @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
//      if gestureRecognizer.state != .began { return }
//
//      let touchPoint = gestureRecognizer.location(in: mapView)
//      let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
//    print("🧭")
//      print(touchMapCoordinate)
//    let newPin = MKPointAnnotation()
//    newPin.coordinate = touchMapCoordinate
//    mapView.addAnnotation(newPin)
//  }
  
  deinit {
    subscriptions.removeAll()
    createSubscription?.cancel()
    deleteSubscription?.cancel()
    updateSubscription?.cancel()
  }
  
  //MARK: - IBActions
  @IBAction func locateMe(_ sender: Any) {
    locationManager.startUpdatingLocation()
  }
  
  @IBAction func trackMe(_ sender: Any) {
    isTrackerEnabled.toggle()
    trackMeButton.isSelected = isTrackerEnabled
  }
  
  //MARK: - Functions
  func startSafeMode(path: [String]) {
    self.loadDirections(path: path)
    self.pulseLayer = self.startPulsationAnimation()
  }
  
  private func loadDirections(path: [String]) { //e.i. ["W-10", "W-12", "W-15", "W-16"]
    print("🔴 This functionalify is not available for the iPad")
//    guard !path.isEmpty else { return }
//    var points: [CLLocationCoordinate2D] = []
//
//    for node in path {
//      if let beacon = beaconsDict[node] {
//        points.append(CLLocationCoordinate2DMake(beacon.location.coordinate.latitude,
//                                                 beacon.location.coordinate.longitude))
//      }
//    }
//
//    currentPathOverlay = MKPolyline(coordinates: &points, count: points.count)
//    mapView.addOverlay(currentPathOverlay)
  }
  
  private func startPulsationAnimation() -> Pulsing {
    let pulse = Pulsing(numberOfPulses: Float.infinity, position: view.center, height: view.bounds.height, width: view.bounds.width)
    pulse.animationDuration = 3.0
    pulse.backgroundColor = UIColor.systemRed.cgColor
    
    self.view.layer.insertSublayer(pulse, above: mapView.layer)
    
    return pulse
  }
  
  func stopPulsationAnimation() {
    guard let pulseLayer = pulseLayer else { return }
    pulseLayer.stopAnimationGroup()
    
    let pulse = Pulsing(numberOfPulses: 3.0, position: view.center, height: view.bounds.height, width: view.bounds.width)
    pulse.animationDuration = 1.0
    pulse.backgroundColor = UIColor.systemGreen.cgColor
    self.view.layer.insertSublayer(pulse, above: mapView.layer)
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
        case .success(let mobileUsers):
          print("🟢 Successfully retrieved list of MobileUsers: \(mobileUsers)")
          let numOutside = mobileUsers.filter{ $0.location == "W-16" }.count
          let numInside = mobileUsers.count - numOutside
          DispatchQueue.main.async {
            self.peopleInsideLabel.text = "\(numInside)"
            self.peopleOutsideLabel.text = "\(numOutside)"
          }
        case .failure(let error):
          print("🔴 Got failed result trying to retrive MobileUsers with \(error.errorDescription)")
        }
      }
  }
  
  func establishCreateSubscription() {
    createSubscription = Amplify.API.subscribe(request: .subscription(of: MobileUser.self, type: .onCreate))
    createSubscription?.subscriptionDataPublisher.sink {
      if case let .failure(apiError) = $0 {
        print("Subscription has terminated with \(apiError)")
      } else {
        print("Subscription has been closed successfully")
      }
    }
    receiveValue: { result in
      switch result {
      case .success(let createdMobileUser):
        print("🟢 Successfully got MobileUser from create subscription: \(createdMobileUser)")
        self.getMobileUsers().store(in: &self.subscriptions)
      case .failure(let error):
        print("🔴 Got failed result from create subscription with \(error.errorDescription)")
      }
    }.store(in: &subscriptions)
  }
  
  func establishDeleteSubscription() {
    deleteSubscription = Amplify.API.subscribe(request: .subscription(of: MobileUser.self, type: .onDelete))
    createSubscription?.subscriptionDataPublisher.sink {
      if case let .failure(apiError) = $0 {
        print("Subscription has terminated with \(apiError)")
      } else {
        print("Subscription has been closed successfully")
      }
    }
    receiveValue: { result in
      switch result {
      case .success(let createdMobileUser):
        print("🟢 Successfully remove MobileUser from delete subscription: \(createdMobileUser)")
        self.getMobileUsers().store(in: &self.subscriptions)
      case .failure(let error):
        print("🔴 Got failed result from delete subscription with \(error.errorDescription)")
      }
    }.store(in: &subscriptions)
  }
  
  func establishUpdateSubscription() {
    updateSubscription = Amplify.API.subscribe(request: .updateMobileUserLocationSubscription())
    
    updateSubscription?.subscriptionDataPublisher.sink {
      if case let .failure(apiError) = $0 {
        print("Subscription has terminated with \(apiError)")
      } else {
        print("Subscription has been closed successfully")
      }
    }
    receiveValue: { result in
      switch result {
      case .success(let updatedMobileUser):
        print("🟢 Successfully got MobileUser from update subscription: \(updatedMobileUser)")
        self.getMobileUsers().store(in: &self.subscriptions)
      case .failure(let error):
        print("🔴 Got failed result from update subscription with \(error.errorDescription)")
      }
    }.store(in: &subscriptions)
  }
  
  func signInWithWebUI() -> AnyCancellable {
    Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!)
      .resultPublisher
      .sink {
        if case let .failure(authError) = $0 {
          print("Sign in failed \(authError)")
        }
      }
      receiveValue: { _ in
        print("Sign in succeeded")
      }
  }
  
  func fetchCurrentAuthSession() -> AnyCancellable {
    Amplify.Auth.fetchAuthSession().resultPublisher
      .sink {
        if case let .failure(authError) = $0 {
          print("🔴 Fetch session failed with error \(authError)")
        }
      }
      receiveValue: { session in
        print("🟢 Is user signed in - \(session.isSignedIn)")
      }
  }
  
  func drawSafeArea() {
    var points: [CLLocationCoordinate2D] = []
    
    points.append(CLLocationCoordinate2DMake(37.32995498762128, -121.88921548426148))
    points.append(CLLocationCoordinate2DMake(37.33013520698357, -121.88883930444716))
    points.append(CLLocationCoordinate2DMake(37.33036074717399, -121.88900962471959))
    points.append(CLLocationCoordinate2DMake(37.33018212793003, -121.88938647508618))
    
    let safeAreaPolygon = MKPolygon(coordinates: &points, count: points.count)  
    mapView.addOverlay(safeAreaPolygon)
  }
  
  func subscribeToBuilding() {
    buildingPublisher?
      .sink(receiveCompletion: { (completion) in
        switch completion {
        case .finished:
          print("🟢 Building with nested objects retrieved for IndoorMapViewController))")
          print(self.blockedAreas.count)
          DispatchQueue.main.async {
            self.mapView.addAnnotations(self.blockedAreas)
          }
        case .failure(let error):
          print("🔴 Failure to retrieve Building with nested objects \(error.localizedDescription)")
        }
      }, receiveValue: { [weak self] (building) in
        guard let self = self else { return }
        self.edges = Array(building.edges!)
        for edge in self.edges {
          guard let latitude = edge.latitude, let longitude = edge.longitude else { continue }
          self.blockedAreas.append(BlockedArea(latitude: latitude, longitude: longitude, name: edge.name))
        }
      })
      .store(in: &subscriptions)
  }
  
  // MARK: - LevelPickerDelegate
  
  func selectedLevelDidChange(selectedIndex: Int) {
    precondition(selectedIndex >= 0 && selectedIndex < self.levels.count)
    let selectedLevel = self.levels[selectedIndex]
    showFeaturesForOrdinal(selectedLevel.properties.ordinal)
  }
}
