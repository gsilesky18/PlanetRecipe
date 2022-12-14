//
//  MasterViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 11/22/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData


class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISplitViewControllerDelegate,CloudkitDelegate {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var favoritesSegment: UISegmentedControl!
    @IBOutlet weak var categorySegment: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var fetchedResultsController = NSFetchedResultsController<Recipe>()
    var shouldShowSearchresults = false
    var searchString = ""
    var context: NSManagedObjectContext!
    var detailViewController: DetailViewController? = nil
    let model: CloudKitHelper = CloudKitHelper.sharedInstance()
    let secretNumber = UserDefaults.standard.integer(forKey: "Maximum Photos")
    
    //Date to which begin updating recipes
    func findLastModDate()->Date {
        
        var date:Date!
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "lastMod") == nil {
            date = Date()
            userDefaults.set(Date(), forKey: "lastMod")
        }else{
            date = userDefaults.object(forKey: "lastMod") as! NSDate as Date
            userDefaults.set(Date(), forKey: "lastMod")
        }
        return date
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.isHidden = true
        splitViewController?.preferredDisplayMode = .automatic
        splitViewController?.maximumPrimaryColumnWidth = 320.0
        searchBar.delegate = self
        tableView.sectionIndexColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
        shouldShowSearchresults = false
        searchBar.text = ""
        searchString = ""
        searchBar.resignFirstResponder()
        setupFetchResults()
    }
    
    func configureView(){
        self.model.delegate = self
        let reachability = Reachability()
        if reachability.isConnectedToNetwork() == false {
            let alert = UIAlertController(title: "Network not available", message: "Try later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else {
            //Check for empty database
            let request = NSFetchRequest<Recipe>(entityName: "Recipe")
            request.predicate = NSPredicate(value: true)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            request.fetchLimit = 2
            let fetchResults:Array = try! context.fetch(request)
            if fetchResults.count <= 0 {
                //Load recipes from iCloud if user has 1 minutes
               
                let alert = UIAlertController(title: "First Time Recipe Load", message: "Requires 1 minute with WiFi", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { (action) ->
                    Void in
                    //exit(0)
                }))
                alert.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { (action) ->
                    Void in
                    self.progressView.isHidden = false
                    self.spinner.startAnimating()
                    cloudKitHelper.addExistingRecords(context: self.context)
                    //cloudKitHelper.importNewAndModified(self.findLastModDate(), context: self.context) //When loading dev data
                }))
                self.present(alert, animated: true, completion: nil)
            }else {
                if secretNumber != 8845 {
                    spinner.startAnimating()
                    cloudKitHelper.importNewAndModified(findLastModDate(), context: context)
                }
            }
        }
    }
    
    func setupFetchResults() {
        let request = fetchRequest()
        request.predicate = getPredicate()
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "name", cacheName: nil)
        fetchedResultsController.delegate = self
        do {
        try fetchedResultsController.performFetch()
        }catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
        let recipeNumber = fetchedResultsController.fetchedObjects?.count
        let recipeCount = recipeNumber?.description
        self.title = recipeCount! + " Recipes"
        tableView.reloadData()
    }
    
    //Structs for categories and favorites selection
    
    struct Category {
        static let all = 0
        static let apptzr = 1
        static let entree = 2
        static let side = 3
        static let dessert = 4
    }
    
    func getCategory() ->String {
        switch categorySegment.selectedSegmentIndex {
        case Category.all: return "All"
        case Category.apptzr: return "Appetizer"
        case Category.entree: return "Entree"
        case Category.side: return "Side"
        case Category.dessert: return "Dessert"
        default: return "Entree"
        }
    }
    
    struct Favorite {
        static let all = 0
        static let fav = 1
    }
    
    //setup sort and predicates
    
    func fetchRequest() -> NSFetchRequest<Recipe> {
        let fRequest = NSFetchRequest<Recipe>(entityName: "Recipe")
        fRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return fRequest
    }
    
    func getPredicate() -> NSPredicate {
        var predicate:NSPredicate!
        if shouldShowSearchresults == true { //Using Search
            searchString = searchBar.text!
            if categorySegment.selectedSegmentIndex == Category.all {
                let pred1 = NSPredicate(value: true)
                let pred2 = NSPredicate(format: "name CONTAINS[c]%@", searchString)
                predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [pred1, pred2])
            }else{
                let pred1 = NSPredicate(format: "category = %@", getCategory())
                let pred2 = NSPredicate(format: "name CONTAINS[c]%@", searchString)
                predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [pred1, pred2])
            }
            //Not using Search
        }else {
            if ((favoritesSegment.selectedSegmentIndex == Favorite.all) && (categorySegment.selectedSegmentIndex == Category.all)) {
                predicate = NSPredicate(value: true)
            }
            if favoritesSegment.selectedSegmentIndex == Favorite.all && categorySegment.selectedSegmentIndex != Category.all {
                predicate = NSPredicate(format: "category = %@", getCategory())
            }
            if favoritesSegment.selectedSegmentIndex == Favorite.fav && categorySegment.selectedSegmentIndex == Category.all {
                let pred1 = NSPredicate(value: true)
                let pred2 = NSPredicate(format: "favorite == %@", NSNumber(value: true))
                predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [pred1, pred2])
            }
            if favoritesSegment.selectedSegmentIndex == Favorite.fav && categorySegment.selectedSegmentIndex != Category.all {
                let pred1 = NSPredicate(format: "category = %@", getCategory())
                let pred2 = NSPredicate(format: "favorite == %@", NSNumber(value: true))
                predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [pred1, pred2])
            }
        }
        return predicate
        
    }
    
    
    @IBAction func favoritesChanged(_ sender: UISegmentedControl) {
        setupFetchResults()
    }
    
    @IBAction func categoryChanged(_ sender: UISegmentedControl) {
        setupFetchResults()
    }
    
    
    // MARK: - TableView Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
     func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var databaseUsed:String!
            let defaults = UserDefaults.standard
            let secretNumber:Int = defaults.integer(forKey: "Maximum Photos")
            //Is the User Administrator?
            if secretNumber == MaxPhotos.admin {
                databaseUsed = "publicDB"
            }else {
                databaseUsed = "privateDB"
            }
            let recipe:Recipe = self.fetchedResultsController.object(at: indexPath)
            cloudKitHelper.deleteRecordFromIcloud(databaseUsed, name: recipe.name!)
            context.delete(recipe)
            do {
                try context.save()
            } catch {
                let error:NSError? = nil
                print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
            }
        }
    }
    
    struct MaxPhotos {
       static let admin = 8845
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    //MARK: - TableView DataSource
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        self.configureCell(cell: cell as! MasterTableViewCell, atIndexPath: indexPath as NSIndexPath)
        return cell
    }
    
    func configureCell(cell: MasterTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let recipe: Recipe = self.fetchedResultsController.object(at: indexPath as IndexPath)
        cell.recipeLabel.text = recipe.name
        let photoImage = UIImage(data: recipe.photo!)
        cell.recipePhoto.image = photoImage
    }
    
    // MARK: - CloudHelper Delegate Methods
    func errorUpdating(_ error: NSError) {
        DispatchQueue.main.async(execute: {
            self.spinner.stopAnimating()
            let message = error.localizedDescription
            let alert = UIAlertController(title: "Error loading Data", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
        
    }
    
    func progressUpdate(records: Int) {
        DispatchQueue.main.async(execute: {
            if (Float(records) / 225.0) >= 1.0 {
                self.progressView.setProgress(1.0, animated: true)
            }else {
                self.progressView.setProgress(Float(records) / 225.0, animated: true)
            }
        })
    }
    
    func modelUpdated(){
        DispatchQueue.main.async(execute: {
            self.spinner.stopAnimating()
            self.progressView.isHidden = true
            self.setupFetchResults()
        })
    }
    
    func dataUpdated(records:Int) {
        let number = String(records)
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            if records > 0 {
                let alert = UIAlertController(title: "Database updated", message: number + " updated recipe(s)", preferredStyle: UIAlertController.Style.alert)
                self.present(alert, animated: true, completion: nil)
                Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.dismissAlert(_:)), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func dismissAlert(_: UIAlertController){
        dismiss(animated: true, completion: nil)
        
    }
    
    func noFiletoImport() {
        DispatchQueue.main.async(execute: {
            self.spinner.stopAnimating()
            let alert = UIAlertController(title: "No file to import", message: "Try again", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    func noAuthentication(){
        DispatchQueue.main.async(execute: {
            
            self.spinner.stopAnimating()
            let alert = UIAlertController(title: "iCloud sign-in required", message: "Please go to Settings and sign in.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    // MARK: - SearchBar Delegates
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        shouldShowSearchresults = true
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        shouldShowSearchresults = false
        searchBar.resignFirstResponder()
        setupFetchResults()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        shouldShowSearchresults = false
        searchBar.text = ""
        searchString = ""
        setupFetchResults()
        searchBar.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchString = searchText
        shouldShowSearchresults = true
        setupFetchResults()
    }
    
    // MARK: - FetchedResults Delegate Methods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)  {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            self.tableView.reloadData()
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default :
            break
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let recipe:Recipe = self.fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.recipe = recipe
                controller.context = context
                self.splitViewController?.toggleMasterView()
            }
        }
    }
}

extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        barButtonItem.tintColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        UIApplication.shared.sendAction(barButtonItem.action!, to: barButtonItem.target, from: nil, for: nil)
    }
}
