//
//  IoTTableViewCell.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/9/21.
//

import UIKit

protocol IoTTableViewCellDelegate {
  func ioTCelldidSwitched(cell: IoTTableViewCell, uiSwitch: UISwitch)
}

class IoTTableViewCell: UITableViewCell {
  
  @IBOutlet weak var cellLabel: UILabel!
  
  var delegate: IoTTableViewCellDelegate?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  @IBAction func toggleAlarm(_ sender: Any) {
    let uiSwitch = sender as! UISwitch
    delegate?.ioTCelldidSwitched(cell: self, uiSwitch: uiSwitch)
  }
  
}
