//
//  MasterTableViewCell.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 11/24/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit

class MasterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var recipePhoto: UIImageView!
    @IBOutlet weak var recipeLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
