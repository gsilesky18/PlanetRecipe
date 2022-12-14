//
//  Recipe.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 11/24/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class Recipe: NSManagedObject {
    //Enter recipes into data base
    class func recipeWithname(_ name:String, context: NSManagedObjectContext) -> Recipe {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "name = %@", name)
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let recipes:Array = try! context.fetch(request) as! [Recipe]
        let recipe = recipes.last
        return recipe!
    }
    
    //load CoreData
    class func loadRecipes(_ recipeDict: NSDictionary, context: NSManagedObjectContext) ->Recipe {
        var recipe:Recipe
        recipe = Recipe(context: context)
        recipe.name = recipeDict["recipeName"] as? String
        recipe.category = recipeDict["category"] as? String
        recipe.directions = recipeDict["directions"] as? String
        recipe.favorite = recipeDict["favorite"] as? Bool ?? false
        recipe.photo = recipeDict["photo"] as? Data
        recipe.modified = recipeDict["modified"] as? Bool ?? false
        recipe.notes = recipeDict["notes"] as? String ?? ""
        return recipe
    }
    
    // Delete recipe being replaced if it exists
    class func DeleteRecipeWithName(_ name:String, context: NSManagedObjectContext) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "name = %@", name)
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let recipes: NSArray = try! context.fetch(request) as! [Recipe] as NSArray
        if recipes.count > 0 {
            let recipe = recipes.lastObject as! Recipe
            context.delete(recipe)
        }
    }
}
