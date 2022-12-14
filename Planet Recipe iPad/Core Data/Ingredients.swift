//
//  Ingredients.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 11/24/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class Ingredients: NSManagedObject {

    class func loadIngredients(recipeDict:NSDictionary, context: NSManagedObjectContext) -> Ingredients {
        var ingredient: Ingredients!
        let ingredientArray = NSArray(array: recipeDict["ingredArray"] as! NSArray)
        for ingr in ingredientArray {
            ingredient = Ingredients(context: context)
            ingredient.item = (ingr as! NSDictionary)["item"] as? String
            ingredient.dept = (ingr as! NSDictionary)["dept"] as? String
            ingredient.whichRecipe = Recipe.recipeWithname(recipeDict.value(forKey: "recipeName") as!String, context: context)
        }
        return ingredient
    }
}
