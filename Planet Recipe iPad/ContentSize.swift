//
//  ContentSize.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 12/5/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ContentSize:NSObject {
    
    class func getContentSize(width:CGFloat, recipe:Recipe) -> CGSize {
        var totalHeight:CGFloat = 0.0
        totalHeight = Heights.photoHeight + totalHeight
        totalHeight = Heights.ingredHeading + totalHeight
        totalHeight = totalHeight + loadIngredientsHeight(recipe: recipe, width: width)
        totalHeight = totalHeight + Heights.DirHeading
        totalHeight = totalHeight + loadDirectionsHeight(recipe: recipe, width: width)
        return CGSize(width: width, height: totalHeight)
    }
    
    class func loadIngredientsHeight(recipe:Recipe, width:CGFloat) -> CGFloat {
        var ingredients = [String]()
        for ingr in recipe.ingredients! {
            let item:String = (ingr as! Ingredients).item!
            ingredients.append(item)
        }
        ingredients.sort(by: {$0.compare($1) ==
            ComparisonResult.orderedAscending})
        var totHeight:CGFloat = 0.0
        for object in ingredients {
            let ingredStr = (object as NSString).substring(from: 2)
            let ingredFont = UIFont(name: "Helvetica", size: 16.0)
            let height = ingredStr.height(withConstrainedWidth: width, font: ingredFont!)
            totHeight = totHeight + height
        }
        return totHeight
    }
    
    class func loadDirectionsHeight(recipe:Recipe, width:CGFloat) -> CGFloat {
        let directions = recipe.directions
        let dirFont = UIFont(name: "Helvetica", size: 16.0)
        let indent:CGFloat = 50.0
        let height = directions?.height(withConstrainedWidth: width - (2.0 * indent), font: dirFont!)
        return height! + 20.0
    }
    struct Heights {
        static let photoHeight:CGFloat = 415.0
        static let ingredHeading:CGFloat = 75.0
        static let DirHeading:CGFloat = 75.0
    }
    
}
