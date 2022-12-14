//
//  IngredientTableViewCell.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 12/24/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit

class IngredientTableViewCell: UITableViewCell {

    @IBOutlet weak var ingredCellLabel: UILabel!
    @IBOutlet weak var deptCellLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
