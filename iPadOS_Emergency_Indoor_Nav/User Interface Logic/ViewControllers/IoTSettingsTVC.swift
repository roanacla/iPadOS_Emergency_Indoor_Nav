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
  private var edgesPublisher: AnyPublisher<[Edge],Error>? {
    return (UIApplication.shared.delegate as? AppDelegate)?.edgesPublisher
  }
  private var edges: [Edge] = []
  
  //MARK: - IBOutlets
  @IBOutlet weak var alertSwitch: UISwitch!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    subscribeToRemoteEdges()
    tableView.register(UINib(nibName: "AlertCell", bundle: nil), forCellReuseIdentifier: "AlertCell")
    tableView.register(UINib(nibName: "IoTCell", bundle: nil), forCellReuseIdentifier: "IoTCell")
    
    
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem
  }
  
  // MARK: - Functions
  func subscribeToRemoteEdges() {
    edgesPublisher?
      .sink(receiveCompletion: { (completion) in
        switch completion {
        case .finished:
          print("🟢 All edges retrieved")
        case .failure:
          print("🔴 Failure to retrieve edges")
        }
      }, receiveValue: {[weak self] (edges) in
        guard let self = self else { return }
        self.edges = edges
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      })
      .store(in: &combineSubscribers)
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
      cell.cellLabel.text = "\(Int.random(in: 1..<48))"
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
  
  /*
   // Override to support conditional editing of the table view.
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the specified item to be editable.
   return true
   }
   */
  
  /*
   // Override to support editing the table view.
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
   if editingStyle == .delete {
   // Delete the row from the data source
   tableView.deleteRows(at: [indexPath], with: .fade)
   } else if editingStyle == .insert {
   // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }
   }
   */
  
  /*
   // Override to support rearranging the table view.
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
   
   }
   */
  
  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the item to be re-orderable.
   return true
   }
   */
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
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
    print("Did switched")
//    BuildingUseCase()
//      .toogleAlarm(remoteAPI: BuildingAmplifyAPI(), buildingID: "id001", isInEmergency: isActive)
//      .store(in: &combineSubscribers)
  }
}
