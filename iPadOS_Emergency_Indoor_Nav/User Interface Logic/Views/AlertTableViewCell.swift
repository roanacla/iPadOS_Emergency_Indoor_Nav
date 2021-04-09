//
//  AlertCellTableViewCell.swift
//  iPadOS_Emergency_Indoor_Nav
//
//  Created by Roger Navarro on 4/9/21.
//

import UIKit
protocol AlertTableViewCellDelegate {
  func didSwitched(cell: AlertTableViewCell, uiSwitch: UISwitch)
}

class AlertTableViewCell: UITableViewCell {
  
  var delegate: AlertTableViewCellDelegate?
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  @IBAction func toggleAlarm(_ sender: Any) {
    let uiSwitch = sender as! UISwitch
    delegate?.didSwitched(cell: self, uiSwitch: uiSwitch)
  }
  
}
