//
//  HistoryLabelCreator.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/11/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import Foundation
import UIKit

class HistoryLabelCreator: NSObject {
    
    struct DictArrays {
    static let menu = 0
    static let guest = 1
    }
    
    static func createMenuLabel(partyDate:PartyDate) ->NSAttributedString {
        var rString = NSMutableAttributedString()
        for item in partyDate.menu!  {
            let themeColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
            let themeAttribute:[NSAttributedString.Key : Any] = [.foregroundColor:themeColor]
            
            if (item as! Menu).appetizer != "" {
                rString = NSMutableAttributedString(string: "Appetizer: ", attributes: themeAttribute)
                let appetite:NSAttributedString = NSAttributedString(string: (item as! Menu).appetizer! + "\n")
                rString.append(appetite)
            }
            if (item as! Menu).entree != "" {
                let entreeString = NSMutableAttributedString(string: "Entree: ", attributes: themeAttribute)
                rString.append(entreeString)
                let entree = NSAttributedString(string: (item as! Menu).entree! + "\n")
                rString.append(entree)
            }
            if (item as! Menu).dessert != "" {
                let dessertString = NSMutableAttributedString(string: "Dessert: ", attributes: themeAttribute)
                rString.append(dessertString)
                let dessert = NSAttributedString(string: (item as! Menu).dessert! + "\n")
                rString.append(dessert)
            }
            if (item as! Menu).side != "" {
                let sideString = NSMutableAttributedString(string: "Side: ", attributes: themeAttribute)
                rString.append(sideString)
                 let side = NSAttributedString(string: (item as! Menu).side! + "\n")
                rString.append(side)
            }
            if (item as! Menu).other != "" {
                let otherString = NSMutableAttributedString(string: "Other: ", attributes: themeAttribute)
                rString.append(otherString)
                 let other = NSAttributedString(string: (item as! Menu).other! + "\n")
                rString.append(other)
            }
        }
       return rString
    }
    
    static func createGuestLabel(partyDate:PartyDate) -> String {
        var n = 1
        var menuString:String = ""
        for item in partyDate.guests! {
            if (item as! Guests).name != "" {
                if n == 5 {
                    menuString += (item as! Guests).name!
                }else{
                    menuString += (item as! Guests).name! + "\n"
                }
                n += 1
            }
        }
        return menuString
    }
    
}
