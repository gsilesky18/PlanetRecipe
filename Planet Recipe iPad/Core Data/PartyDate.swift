//
//  PartyDate.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/17/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class PartyDate: NSManagedObject {
    
    static func loadDateAndGuestString(date:Date, gString:String, context:NSManagedObjectContext)-> PartyDate {
        var partyDate:PartyDate!
        partyDate = PartyDate(context: context)
        partyDate.date = date
        partyDate.gString = gString
        return partyDate
    }
}
