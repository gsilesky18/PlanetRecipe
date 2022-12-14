//
//  Guests.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/17/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class Guests: NSManagedObject {
    
    static func loadGuests(guestArray:Array<String>, partyDate:PartyDate, context: NSManagedObjectContext) {
        var guest:Guests!
        for guestName in guestArray {
            if guestName != "" {
                guest = Guests(context: context)
                guest.name = guestName
                guest.whichDate = partyDate
            }
        }
    }
}
