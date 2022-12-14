//
//  ListViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 12/4/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import MessageUI

class ListViewController: UIViewController, MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var listTableV: UITableView!
    @IBOutlet weak var onHandTableV: UITableView!
    @IBOutlet weak var separationLabel: UILabel!
    var shoppingList = [String:String]()
    var onHandList = [String:String]()
    
    //Mark: FilesPaths
    func listFilePath() ->String {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = (documents as NSString).appendingPathComponent("shoppingList.plist")
        return writePath
    }
    
    func onHandPath() ->String {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = (documents as NSString).appendingPathComponent("onHandList.plist")
        return writePath
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        separationLabel.layer.borderWidth = 1.5
        separationLabel.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if FileManager.default.fileExists(atPath: listFilePath()) {
            shoppingList = NSDictionary(contentsOfFile: listFilePath())! as! [String : String]
            print("\(shoppingList) after")
        }
        if FileManager.default.fileExists(atPath: onHandPath()) {
            onHandList = NSDictionary(contentsOfFile: onHandPath())! as! [String : String]
        }
        listTableV.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool){
        super.viewWillDisappear(animated)
        (shoppingList as NSDictionary).write(toFile: listFilePath(), atomically: true)
        (onHandList as NSDictionary).write(toFile: onHandPath(), atomically: true)
        print("\(shoppingList)")
    }

    @IBAction func clearButton(_ sender: UIBarButtonItem) {
        shoppingList.removeAll()
        onHandList.removeAll()
        listTableV.reloadData()
        onHandTableV.reloadData()
    }
    
    @IBAction func mailButton(_ sender: UIBarButtonItem) {
        if shoppingList.count < 1 {
            let alert = UIAlertController(title: "Cannot share list", message: "You must first create shopping list", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }else{
            let mailComposeViewController = configuredMailComposeViewController(createMailShoppingList())
            if MFMailComposeViewController.canSendMail() {
                present(mailComposeViewController, animated: true, completion: nil)
            }else{
                showSendMailErrorAlert()
            }
        }
    }
    
    //MARK: - mailing shopping list
    func createMailShoppingList() ->String {
        let departments:NSArray = createDeptArray(shoppingList)
        var groceryList:String = String()
        for dept in departments {
            let ingredArray = createIngredPerSectionArray(dept as! String)
            if ingredArray.count > 0 {
                groceryList.append("\n" + (dept as AnyObject).uppercased + "\n")
            }
            for ingred in ingredArray {
                groceryList.append("-" + (ingred as! String) + "\n")
            }
        }
        return groceryList
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: UIAlertController.Style.alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController(_ textView: String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposerVC.setSubject("My Shopping List")
        mailComposerVC.setMessageBody(textView, isHTML: false)
        mailComposerVC.navigationBar.tintColor = UIColor(red: 0.30, green: 0.65, blue: 0.35, alpha: 1.0)
        return mailComposerVC
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: { print("mail sent") })
    }
    
    //MARK: - methods to create tableView arrays
    //Shopping list Arrays
    func createDeptArray(_ shoppingList: Dictionary<String,String>) -> NSArray {
        let departments: NSMutableSet = NSMutableSet()
        for ingred in shoppingList.keys {
            let dept: String = shoppingList[ingred]!
            departments.add(dept)
        }
        let sortDescriptor = NSSortDescriptor(key: nil, ascending: true)
        let sortedDepartments = departments.sortedArray(using: [sortDescriptor])
        return sortedDepartments as NSArray
    }
    
    func createIngredPerSectionArray(_ deptKey:String)->NSArray {
        var sectionIngredients:[String] = [String]()
        for (ingred, _) in shoppingList {
            if deptKey == shoppingList[ingred]  {
                let ingredient:String = (ingred as NSString).substring(from: 2)
                sectionIngredients.append(ingredient)
            }
        }
        sectionIngredients.sort(by: { $0.compare($1) == ComparisonResult.orderedAscending })
        return sectionIngredients as NSArray
    }
    //OnHand Arrays
    func createOHArray(_ onHandDict: Dictionary<String,String>) -> NSArray {
        var ingredients:[String] = [String]()
        for ingred in onHandDict.keys{
            let ingredNS = ingred as NSString
            ingredients.append(ingredNS.substring(from: 2))
        }
        ingredients.sort(by: { $0.compare($1) == ComparisonResult.orderedAscending })
        return ingredients as NSArray
    }
    
    //Move from Needed to OnHand
    func shoppingListItemSelected(_ ingredient: String, indexpath: IndexPath) {
        var item:String!
        var department:String!
        for (key, value) in shoppingList {
            if (key as NSString).substring(from: 2) == ingredient {
                department = value as String
                item = key as String
            }
        }
        shoppingList.removeValue(forKey: item)
        onHandList[item] = department
        listTableV.deselectRow(at: indexpath, animated: true)
        self.perform(#selector(ListViewController.listReload), with: nil, afterDelay: 0.5)
        onHandTableV.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    @objc func listReload() {
        listTableV.reloadData()
    }
    
    //Move from OnHand to Needed
    func onHandItemSelected(_ ingredient: NSString) {
        var item:String!
        var department:String!
        for (key, value) in onHandList {
            if (key as NSString).substring(from: 2) == ingredient as String {
                department = value
                item = key
            }
        }
        onHandList.removeValue(forKey: item)
        shoppingList[item] = department
        self.perform(#selector(ListViewController.listReload), with: nil, afterDelay: 0.5)
        onHandTableV.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    // Mark: - TableView Delegate methods
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 220/255, green: 230/255, blue: 220/255, alpha: 1)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == listTableV {
            let sect = self.createDeptArray(self.shoppingList).object(at: section) as? String
            return sect
        }else{
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == listTableV {
            return self.createDeptArray(self.shoppingList).count
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == listTableV {
            let key:String = createDeptArray(shoppingList).object(at: section) as! String
            return createIngredPerSectionArray(key).count
        }else{
            return createOHArray(onHandList).count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == listTableV {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath)
            let section:NSInteger = indexPath.section
            let key = createDeptArray(shoppingList).object(at: section)
            let ingredientArray = createIngredPerSectionArray(key as! String)
            cell.textLabel!.text = ingredientArray[indexPath.row] as? String
            cell.imageView!.image = UIImage(named: "UnChecked.png")
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "OnHandCell", for: indexPath)
            cell.textLabel?.text = createOHArray(onHandList).object(at: indexPath.row) as? String
            cell.imageView!.image = UIImage(named: "Checked.png")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == listTableV {
            tableView.cellForRow(at: indexPath)?.imageView?.image = UIImage(named: "Checked.png")
            let section:NSInteger = indexPath.section
            let key:String = createDeptArray(shoppingList).object(at: section) as! String
            let ingredArray:NSArray = createIngredPerSectionArray(key)
            let ingredient:String = ingredArray.object(at: indexPath.row) as! String
            shoppingListItemSelected(ingredient, indexpath: indexPath)
        }else{
            tableView.cellForRow(at: indexPath)?.imageView?.image = UIImage(named: "UnChecked.png")
            Thread.sleep(forTimeInterval: 0.5)
            let ingredient:String = createOHArray(onHandList).object(at: indexPath.row) as! String
            onHandItemSelected(ingredient as NSString)
        }
    }

}
