//
//  CloudKitHelper.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 11/24/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

protocol CloudkitDelegate {
    func errorUpdating(_ error: NSError)
    func modelUpdated()
    func dataUpdated(records:Int)
    func noFiletoImport()
    func noAuthentication()
    func progressUpdate(records:Int)
}

let cloudKitHelper = CloudKitHelper()

class CloudKitHelper {
    var container: CKContainer
    var publicDB: CKDatabase
    var delegate: CloudkitDelegate?
    var recDictArray: [CKRecord]
    var backgroundQueue: OperationQueue!
    var recordCount = 0
    class func sharedInstance() -> CloudKitHelper {
        return cloudKitHelper
    }
    
    init() {
        container = CKContainer(identifier: "iCloud.com.zanysocksapps.PRPhoneS")
        publicDB = container.publicCloudDatabase
        recDictArray = []
        backgroundQueue = OperationQueue()
    }
    // Bring existing recipes to coredata for first time load
    func addExistingRecords(context:NSManagedObjectContext) {
        
        CKContainer.default().accountStatus { (accountStatus, error) in
            if accountStatus == CKAccountStatus.noAccount {
                print("no auth")
                self.delegate?.noAuthentication()
            }else {
                self.backgroundQueue.addOperation() {
                    let dataBase = self.container.publicCloudDatabase
                    let predicate = NSPredicate(value: true)
                    let query = CKQuery(recordType: "RecipeFile", predicate: predicate)
                    let queryOperation = CKQueryOperation(query: query)
                    queryOperation.resultsLimit = CKQueryOperation.maximumResults
                    dataBase.add(queryOperation)
                    queryOperation.recordFetchedBlock = { record in
                        self.recordCount += 1
                        self.delegate?.progressUpdate(records: self.recordCount)
                        self.recDictArray.append(record)
                    }
                    queryOperation.queryCompletionBlock = { cursor, error in
                        if error != nil {
                            print(error!.localizedDescription)
                            self.delegate?.errorUpdating(error! as NSError)
                        }else {
                            if cursor != nil {
                                print("total records: \(self.recDictArray.count)")
                                self.queryServer(cursor!, context: context)
                            }else{
                                print("completed query")
                                context.performAndWait {
                                    for record in self.recDictArray {
                                        let rDictData: Data = record.object(forKey: "recipeDict") as! Data
                                        let recipeDict: NSDictionary = (try! PropertyListSerialization.propertyList(from: rDictData, options: PropertyListSerialization.MutabilityOptions(), format: nil)) as! NSDictionary
                                        let _ = Recipe.loadRecipes(recipeDict, context: context)
                                        let _ = Ingredients.loadIngredients(recipeDict: recipeDict, context: context)
                                    }
                                    print("total records added CoreData: \(self.recDictArray.count)")
                                    do {
                                        try context.save() }
                                    catch { let error:NSError? = nil
                                        print("Unresolved error \(String(describing: error)), \(error!.userInfo)")  }
                                    self.delegate?.modelUpdated()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //Import remaining records from ICloud
    func queryServer(_ cursor:CKQueryOperation.Cursor, context:NSManagedObjectContext) {
        let dataBase = container.publicCloudDatabase
        let queryOperation = CKQueryOperation(cursor: cursor)
        queryOperation.resultsLimit = CKQueryOperation.maximumResults
        queryOperation.recordFetchedBlock = { record in
            self.recordCount += 1
            self.delegate?.progressUpdate(records: self.recordCount)
            self.recDictArray.append(record)
        }
        print("\(self.recDictArray.count)")
        queryOperation.queryCompletionBlock = { cursor, error in
            if error != nil {
                print(error!.localizedDescription)
                self.delegate?.errorUpdating(error! as NSError)
            }else {
                if cursor != nil {
                    print("total records: \(self.recDictArray.count)")
                    self.queryServer(cursor!, context: context)
                } else {
                    print("completed query")
                    context.performAndWait {
                        for record in self.recDictArray {
                            let rDictData: Data = record.object(forKey: "recipeDict") as! Data
                            let recipeDict: NSDictionary = (try! PropertyListSerialization.propertyList(from: rDictData, options: PropertyListSerialization.MutabilityOptions(), format: nil)) as! NSDictionary
                            let _ = Recipe.loadRecipes(recipeDict, context: context)
                            let _ = Ingredients.loadIngredients(recipeDict: recipeDict, context: context)
                        }
                        print("total records added CoreData: \(self.recDictArray.count)")
                        do {
                            try context.save() }
                        catch { let error:NSError? = nil
                            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")  }
                        self.delegate?.modelUpdated()
                    }
                }
            }
        }
        dataBase.add(queryOperation)
    }
    
    //Import new and modified records
    func importNewAndModified(_ lastDate: Date, context: NSManagedObjectContext) {
        self.recDictArray.removeAll()
        CKContainer.default().accountStatus { (accountStatus, error) in
            if accountStatus == CKAccountStatus.noAccount {
                self.delegate?.noAuthentication()
            }else {
                var recordCount:Int = 0
                let dataBase = self.container.publicCloudDatabase
                //let predicate = NSPredicate(value: true) //for loading dev data
                let predicate = NSPredicate(format: "date > %@", lastDate as CVarArg)
                let query = CKQuery(recordType: "RecipeFile", predicate: predicate)
                let queryOperation = CKQueryOperation(query: query)
                queryOperation.resultsLimit = CKQueryOperation.maximumResults
                dataBase.add(queryOperation)
                queryOperation.recordFetchedBlock = { record in
                    recordCount += 1
                    self.recDictArray.append(record)
                }
                queryOperation.queryCompletionBlock = { cursor, error in
                    if error != nil {
                        print(error!.localizedDescription)
                        self.delegate?.errorUpdating(error! as NSError)
                    }else{
                        for record in self.recDictArray {
                            let rDictData: Data = record.object(forKey: "recipeDict") as! Data
                            let recipeDict: NSDictionary = (try! PropertyListSerialization.propertyList(from: rDictData, options: PropertyListSerialization.MutabilityOptions(), format: nil)) as! NSDictionary
                            // delete existing records in core data
                            context.performAndWait {
                                let recipeName: String = record.object(forKey: "recipeName") as! String
                                Recipe.DeleteRecipeWithName(recipeName, context: context)
                                // insert newobject
                                let _ = Recipe.loadRecipes(recipeDict, context: context)
                                let _ = Ingredients.loadIngredients(recipeDict: recipeDict, context: context)
                                do {
                                    try context.save() }
                                catch { let error:NSError? = nil
                                    print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                                    
                                }
                            }
                        }
                        self.delegate?.dataUpdated(records: recordCount)
                    }
                }
            }
        }
    }
    
    //Delete record
    func deleteRecordFromIcloud(_ typeDB:String, name:String) {
        CKContainer.default().accountStatus { (accountStatus, error) in
            if accountStatus == CKAccountStatus.noAccount {
                self.delegate?.noAuthentication()
            }else {
                var dataBase:CKDatabase!
                if typeDB == "privateDB" {
                    dataBase = self.container.privateCloudDatabase
                }else {
                    dataBase = self.container.publicCloudDatabase
                }
                print("\(name) deleted")
                let predicate = NSPredicate(format: "recipeName = %@", name )
                let query = CKQuery(recordType: "RecipeFile", predicate: predicate)
                let queryOperation = CKQueryOperation(query: query)
                queryOperation.resultsLimit = 1
                dataBase.add(queryOperation)
                queryOperation.recordFetchedBlock = { record in
                    let recordToDeleteID = record.recordID
                    dataBase.delete(withRecordID: recordToDeleteID, completionHandler: { recordID, error in
                        if error != nil {
                        print(error?.localizedDescription ?? "error deleting record")
                        }
                    })
                }
            }
        }
    }
    
    //Modify record
    func saveModifiedRecipesToCloud(_ typeDB:String, largePhoto:Data, recipeDict:NSDictionary) {
        let fileURL = self.generateFileURL()
        CKContainer.default().accountStatus { (accountStatus, error) in
            if accountStatus == CKAccountStatus.noAccount {
                self.delegate?.noAuthentication()
            }else {
                var dataBase:CKDatabase!
                if typeDB == "privateDB" {
                    dataBase = self.container.privateCloudDatabase
                }else {
                    dataBase = self.container.publicCloudDatabase
                }
                if let recipeData:Data = try? PropertyListSerialization.data(fromPropertyList: recipeDict, format: PropertyListSerialization.PropertyListFormat.binary, options: 0), let fullRecipeName = recipeDict["recipeName"] as? String {
                    var substringRecipeName = fullRecipeName
                    if fullRecipeName.count >= 30 {
                        let index = fullRecipeName.index(fullRecipeName.startIndex, offsetBy: 29)
                        substringRecipeName = String(fullRecipeName[..<index])
                    }
                    let predicate = NSPredicate(format: "recipeName BEGINSWITH %@", substringRecipeName)
                    let query = CKQuery(recordType: "RecipeFile", predicate: predicate)
                    let queryOperation = CKQueryOperation(query: query)
                    queryOperation.resultsLimit = 1
                    dataBase.add(queryOperation)
                    queryOperation.recordFetchedBlock = { record in
                        do {
                            try largePhoto.write(to: fileURL, options: .atomicWrite)
                        } catch { print("Error writing photo")
                        }
                        let asset = CKAsset(fileURL: fileURL)
                        let newDate = Date()
                        record.setValue(newDate, forKey: "date")
                        record.setValue(recipeData, forKey: "recipeDict")
                        //must check for larger photo before writing (not blank photo representation)
                        if largePhoto.count > 30000 {
                            record.setObject(asset, forKey: "photo")
                        }
                        dataBase.save(record, completionHandler: {
                            record, error in
                            if error != nil{
                                print(error?.localizedDescription ?? "error saving this record")
                            }
                            self.delegate?.modelUpdated()
                        })
                    }
                    queryOperation.queryCompletionBlock = { cursor, error in
                        if error != nil {
                            print(error!.localizedDescription)
                            self.delegate?.errorUpdating(error! as NSError)
                        }
                    }
                }
            }
        }
    }
    
    //Add new record
    func saveNewRecipesToCloud(_ typeDB:String, largePhoto:Data, recipeDict:NSDictionary){
        let fileURL = self.generateFileURL()
        CKContainer.default().accountStatus { (accountStatus, error) in
            if accountStatus == CKAccountStatus.noAccount {
                self.delegate?.noAuthentication()
            }else {
                var database:CKDatabase!
                if typeDB == "privateDB" {
                    database = self.container.privateCloudDatabase
                }else {
                    database = self.container.publicCloudDatabase
                }
                let recipeData:Data = try! PropertyListSerialization.data(fromPropertyList: recipeDict, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
                let name = recipeDict["recipeName"] as! String
                do {
                    try largePhoto.write(to: fileURL, options: .atomicWrite)
                } catch { let error:NSError? = nil
                    print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                }
                let asset = CKAsset(fileURL: fileURL)
                let newRecipe = CKRecord(recordType: "RecipeFile")
                let newDate = Date()
                newRecipe.setValue(newDate, forKey: "date")
                newRecipe.setValue(recipeData, forKey: "recipeDict")
                newRecipe.setValue(name, forKey: "recipeName")
                newRecipe.setObject(asset, forKey: "photo")
                database.save(newRecipe, completionHandler: {
                    record, error in
                    if error != nil {
                        print(error?.localizedDescription ?? "error saving record")
                    }
                    self.delegate?.modelUpdated()
                })
            }
        }
    }

    func generateFileURL() -> URL {
        let fileManager = FileManager.default
        let fileArray: NSArray = fileManager.urls(for: .cachesDirectory, in: .userDomainMask) as NSArray
        let fileURL = (fileArray.lastObject as! NSURL).appendingPathExtension(UUID().uuidString)?.appendingPathExtension("png")
        if let filePath = (fileArray.lastObject! as AnyObject).path as String? {
            if !fileManager.fileExists(atPath: filePath) {
                do {
                    try fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    let error:NSError? = nil
                    print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                }
            }
        }
        return fileURL!
    }
}
    

