//
//  Menu.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/17/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class Menu: NSManagedObject {
    
    static func loadMenu(menuDict:Dictionary<String,String>, partyDate:PartyDate, context: NSManagedObjectContext) {
        var menuItem:Menu!
        menuItem = Menu(context: context)
        menuItem.appetizer = menuDict["Appetizer"]
        menuItem.side = menuDict["Side"]
        menuItem.other = menuDict["Other"]
        menuItem.entree = menuDict["Entree"]
        menuItem.dessert = menuDict["Dessert"]
        menuItem.whichDate = partyDate
    }
}
