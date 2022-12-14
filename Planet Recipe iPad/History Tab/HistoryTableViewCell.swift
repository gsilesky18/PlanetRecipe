//
//  HistoryTableViewCell.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/10/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var guestLabel: UILabel!
    
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
