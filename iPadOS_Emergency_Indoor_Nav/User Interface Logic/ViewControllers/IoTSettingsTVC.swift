//
//  IoTSettingsTVC.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/8/21.
//

import UIKit
import Combine

class IoTSettingsTVC: UITableViewController {
  //MARK: - Properties
  private var combineSubscribers = Set<AnyCancellable>()
  private var edges: [Edge] = []
  
  //MARK: - IBOutlets
  @IBOutlet weak var alertSwitch: UISwitch!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    loadIoTs()
    tableView.register(UINib(nibName: "AlertCell", bundle: nil), forCellReuseIdentifier: "AlertCell")
    tableView.register(UINib(nibName: "IoTCell", bundle: nil), forCellReuseIdentifier: "IoTCell")
  }
  
  // MARK: - Functions
  func loadIoTs() {
    let remoteAPI = IoTAmplifyAPI()
    let subscription = remoteAPI.list(buildingId: "id001")
    subscription.sink { (completion) in
      switch completion {
      case .finished:
        print("🟢 All IoTs retrieved")
      case .failure(let error):
        print("🔴 Failure to retrieve IoTs\(error.localizedDescription)")
      }
    } receiveValue: { [weak self] (edges) in
      self?.edges = edges
      DispatchQueue.main.async {
        self?.tableView.reloadData()
      }
    }.store(in: &combineSubscribers)
  }
  // MARK: - IBActions
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      return 1
    case 1:
      return edges.count
    default:
      return 1
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.section {
    case 0:
      let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertTableViewCell
      cell.delegate = self
      return cell
    case 1:
      let cell = tableView.dequeueReusableCell(withIdentifier: "IoTCell", for: indexPath) as! IoTTableViewCell
      cell.cellLabel.text = self.edges[indexPath.row].name?.replacingOccurrences(of: "B-", with: "Area ")
      cell.iotSwitch.isOn = self.edges[indexPath.row].isActive
      cell.delegate = self
      return cell
    default:
      return UITableViewCell()
    }
  }
   
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Alarm Details"
    case 1:
      return "Iot Devices"
    default:
      return nil
    }
  }

}

extension IoTSettingsTVC: AlertTableViewCellDelegate {
  func didSwitched(cell: AlertTableViewCell, uiSwitch: UISwitch) {
    let isInEmergency = uiSwitch.isOn
    BuildingUseCase()
      .toogleAlarm(remoteAPI: BuildingAmplifyAPI(), buildingID: "id001", isInEmergency: isInEmergency)
      .store(in: &combineSubscribers)
  }
}

extension IoTSettingsTVC: IoTTableViewCellDelegate {
  func ioTCelldidSwitched(cell: IoTTableViewCell, uiSwitch: UISwitch) {
    let isActive = uiSwitch.isOn
  }
}
