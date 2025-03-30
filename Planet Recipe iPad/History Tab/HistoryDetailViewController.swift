//
//  HistoryDetailViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 3/3/18.
//  Copyright © 2018 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

class HistoryDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchbar: UISearchBar!
    
    var searchString = ""
    var shouldShowSearchresults = false
    var context:NSManagedObjectContext?
    var fetchedResultsController = NSFetchedResultsController<PartyDate>()
    
    /*func pathURL() -> URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("dictionary.plist")
    }*/

    override func viewDidLoad() {
        super.viewDidLoad()
        searchbar.delegate = self
        setupFetchResults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldShowSearchresults = false
        searchbar.text = ""
        searchString = ""
        searchbar.resignFirstResponder()
    }
    
    func fetchRequest() -> NSFetchRequest<PartyDate> {
        let fRequest = NSFetchRequest<PartyDate>(entityName: "PartyDate")
        fRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return fRequest
    }
    
    func getPredicate() ->NSPredicate {
        var predicate:NSPredicate!
        if shouldShowSearchresults == true { //Using Search
            searchString = searchbar.text!
            predicate = NSPredicate(format: "gString CONTAINS[c]%@", searchString)
        }else{
            predicate = NSPredicate(value: true)
        }
        return predicate
    }
    
    func setupFetchResults() {
        guard let context else { return }
        let request = fetchRequest()
        request.predicate = getPredicate()
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "date", cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        }catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
        if fetchedResultsController.sections?.count == 0 {
            let message = "Tap \"+\" to enter new event"
            let alert = UIAlertController(title: "No events yet entered", message:message , preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(self.dismissAlert(_:)), userInfo: nil, repeats: false)
        }
        tableView.reloadData()
    }
    
    @objc func dismissAlert(_: UIAlertController){
        dismiss(animated: true, completion: nil)
        
    }

    @IBAction func unwindToHistoryDetailMenu(sender: UIStoryboardSegue)
    {
      setupFetchResults()
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
    /*func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sectionIndexTitles
    }*/
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let context else { return }
        if editingStyle == .delete {
            let partyDate:PartyDate = self.fetchedResultsController.object(at: indexPath)
            context.delete(partyDate)
            do {
                try context.save()
            } catch {
                let error:NSError? = nil
                print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
            }
        }
    }
    
   
    
    //MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        self.configureCell(cell: cell as! HistoryTableViewCell, atIndexPath: indexPath as NSIndexPath)
        return cell
    }
    
    func configureCell(cell: HistoryTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let partyDate: PartyDate = self.fetchedResultsController.object(at: indexPath as IndexPath)
        let date:Date = partyDate.date!
        let myDateFormat = DateFormatter()
        myDateFormat.dateStyle = (DateFormatter.Style.medium)
        myDateFormat.dateFormat = " LLL d, yyyy "
        let eventDate = myDateFormat.string(from: date)
        //Create attributed text for label
        let themeColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        let themeAttribute:[NSAttributedString.Key : Any] = [.foregroundColor:themeColor]
        let gString = NSMutableAttributedString(string: "Guests ", attributes: themeAttribute)
        gString.append(NSAttributedString(string: eventDate))
        cell.dateLabel.attributedText = gString
        cell.guestLabel.text = HistoryLabelCreator.createGuestLabel(partyDate: partyDate)
        cell.menuLabel.attributedText = HistoryLabelCreator.createMenuLabel(partyDate: partyDate)
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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDinnerEntry" {
            let dec = segue.destination as! DinnerEntryViewController
            dec.context = context
        }
        if segue.identifier == "toEdit" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let partyDate:PartyDate = self.fetchedResultsController.object(at: indexPath)
                let dec = segue.destination as! DinnerEntryViewController
                dec.context = context
                dec.partyDate = partyDate
                dec.willEdit = true
            }
        }
    }
}
