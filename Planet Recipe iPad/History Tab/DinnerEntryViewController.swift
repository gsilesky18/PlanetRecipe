//
//  DinnerEntryViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/3/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import UIKit
import Foundation
import CoreData


class DinnerEntryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var appetizerTextField: UITextField!
    @IBOutlet weak var entreeTextField: UITextField!
    @IBOutlet weak var sideTextField: UITextField!
    @IBOutlet weak var dessertTextField: UITextField!
    @IBOutlet weak var otherTextField: UITextField!
    @IBOutlet weak var guest1TextField: UITextField!
    @IBOutlet weak var guest2Textfield: UITextField!
    @IBOutlet weak var guest3Textfield: UITextField!
    @IBOutlet weak var guest4Textfield: UITextField!
    @IBOutlet weak var guest5Textfield: UITextField!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchString = ""
    var shouldShowSearchresults = false
    var fetchedResultsController = NSFetchedResultsController<Recipe>()
    var context:NSManagedObjectContext!
    var partyDate:PartyDate!
    var willEdit:Bool = false
    var guestArray:Array = [String]()

    //Example using URL for file path
    /*func pathURL() -> URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("dictionary.plist")
    }*/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.scrollView.contentSize = self.scrollView.frame.size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //editing guest and menu data
        if willEdit == true {
          preloadFields()
        }
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        searchBar.delegate = self
        menuTableView.sectionIndexColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        setupFetchResults()
    }
    
    func preloadFields() {
        self.datePicker.setDate((partyDate.date)!, animated:true)
        for guest in partyDate.guests! {
            guestArray.append((guest as! Guests).name!)
       }
        //test for out of range condition
        if guestArray.count > 0  {
            guest1TextField.text = guestArray[0]
        }
        if guestArray.count > 1  {
            guest2Textfield.text = guestArray[1]
        }
        if guestArray.count > 2  {
            guest3Textfield.text = guestArray[2]
        }
        if guestArray.count > 3  {
            guest4Textfield.text = guestArray[3]
        }
        if guestArray.count > 4  {
            guest5Textfield.text = guestArray[4]
        }
        
        for menu in partyDate.menu! {
            appetizerTextField.text = (menu as! Menu).appetizer
            entreeTextField.text = (menu as! Menu).entree
            sideTextField.text = (menu as! Menu).side
            dessertTextField.text = (menu as! Menu).dessert
            otherTextField.text = (menu as! Menu).other
        }
    }
    
    
    @objc func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets.zero
        } else {
            scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: keyboardViewEndFrame.height , right: 0)
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self.view.window)
    }

    func setupFetchResults() {
        let request = NSFetchRequest<Recipe>(entityName: "Recipe")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.predicate = getPredicate()
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "name", cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        }catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
        menuTableView.reloadData()
    }
    
    func getPredicate() ->NSPredicate {
        var predicate:NSPredicate!
        if shouldShowSearchresults == true { //Using Search
            searchString = searchBar.text!
            predicate = NSPredicate(format: "name CONTAINS[c]%@", searchString)
        }else{
            predicate = NSPredicate(value: true)
        }
        return predicate
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        let selectedDate = datePicker.date
        var menuDict = [String:String]()
        var guestArray = [String]()
        guestArray.append(guest1TextField.text!)
        guestArray.append(guest2Textfield.text!)
        guestArray.append(guest3Textfield.text!)
        guestArray.append(guest4Textfield.text!)
        guestArray.append(guest5Textfield.text!)
        
        menuDict["Appetizer"] = appetizerTextField.text
        menuDict["Entree"] = entreeTextField.text
        menuDict["Side"] = sideTextField.text
        menuDict["Dessert"] = dessertTextField.text
        menuDict["Other"] = otherTextField.text
        let gString:String = guestArray.reduce ("") { result, guestArray -> String in
            return result + guestArray }
        if willEdit == true {
            //Write over values
            context.delete(partyDate)
            partyDate = PartyDate(context: context)
            partyDate.date = datePicker.date
            partyDate.gString = gString
            Menu.loadMenu(menuDict: menuDict, partyDate: partyDate, context: context)
            Guests.loadGuests(guestArray: guestArray, partyDate: partyDate, context: context)
        }else{
            let partyDate:PartyDate = PartyDate.loadDateAndGuestString(date: selectedDate, gString: gString, context: context)
            Menu.loadMenu(menuDict: menuDict, partyDate: partyDate, context: context)
            Guests.loadGuests(guestArray: guestArray, partyDate: partyDate, context: context)
        }
        do {
            try context.save() }
        catch { let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")  }
        performSegue(withIdentifier: "unwindToHistory", sender:self)
    }
    
     // MARK:TableView delegate methods
    
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recipe:Recipe = self.fetchedResultsController.object(at: indexPath)
        switch recipe.category! as String {
        case "Appetizer":
            appetizerTextField.text = recipe.name
        case "Side":
            sideTextField.text = recipe.name
        case "Entree":
            entreeTextField.text = recipe.name
        case "Dessert":
            dessertTextField.text = recipe.name
        default:
            otherTextField.text = recipe.name
        }
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
        searchBar.resignFirstResponder()
        setupFetchResults()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchString = searchText
        shouldShowSearchresults = true
        setupFetchResults()
    }
    
    //MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        let recipe:Recipe = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = recipe.name
        return cell
    }
    
    
    // MARK: - FetchedResults Delegate Methods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        menuTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)  {
        switch type {
        case .insert:
            menuTableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            menuTableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            self.menuTableView.reloadData()
        case .move:
            menuTableView.deleteRows(at: [indexPath!], with: .automatic)
            menuTableView.insertRows(at: [newIndexPath!], with: .automatic)
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        menuTableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            menuTableView.insertSections(indexSet, with: .automatic)
        case .delete:
            menuTableView.deleteSections(indexSet, with: .automatic)
        default :
            break
        }
    }


    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    
   

}
