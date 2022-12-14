//
//  EditViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 12/4/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

protocol SetRecipeFromEditDelegate {
    func setRecipeFromEdit(eRecipe:Recipe)
}


class EditViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate,
                           UITextFieldDelegate, UICollisionBehaviorDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, CloudkitDelegate {
    
    
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var recipeNameTextfield: UITextField!
    @IBOutlet weak var directionsTextView: UITextView!
    @IBOutlet weak var ingredientsTextField: UITextField!
    @IBOutlet weak var deptTextField: UITextField!
    @IBOutlet weak var deptTableView: UITableView!
    @IBOutlet weak var ingredTableView: UITableView!
    @IBOutlet weak var categoryTableView: UITableView!
    @IBOutlet weak var categoryButton: UIButton!
    
    let model:CloudKitHelper = CloudKitHelper.sharedInstance()
    let categories:[String] = ["Appetizer", "Entree", "Side", "Dessert"]
    var isBeingEdited:Bool!
    var isRevising:Bool!
    var recipe:Recipe!
    var context: NSManagedObjectContext!
    var delegate:SetRecipeFromEditDelegate?
    var sortHoldString = "aa"
    var sortedDept:[String] = [String]()
    var ingredientOrder:[String] = [String]()
    var tableViewDict = [String : String]()
    var sortedIngredients = [String]()
    var ingredArray = [[String : String]]()
    var smallData: Data! // holds coreData photo
    var largeData: Data! // holds iCloud photo
    var favorite:Bool!
    let defaults = UserDefaults.standard
    let secretNumber = UserDefaults.standard.integer(forKey: "Maximum Photos")
    
    lazy var animator:UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.directionsTextView)
        return lazilyCreatedDynamicAnimator
    }()
    let gravity = UIGravityBehavior()
    let collider = UICollisionBehavior()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        model.delegate = self
        collider.collisionDelegate = self
        categoryTableView.isHidden = true
        animator.addBehavior(gravity)
        gravity.magnitude = 0.5
        gravity.angle = 3.7
        animator.addBehavior(collider)
        let leftPt = CGPoint(x: 0.0, y: 0.0)
        let rtPoint = CGPoint(x: view.bounds.width, y: 0.0)
        collider.addBoundary(withIdentifier: "top" as NSCopying, from: leftPt, to: rtPoint)
        if isBeingEdited == true {
            categoryButton.isEnabled = false
            categoryButton.setTitle(recipe.category, for: .disabled)
            categoryButton.setTitleColor(UIColor.black, for: .disabled)
            recipeNameTextfield.borderStyle = .none
            populateEditScene()
            createDictionaries()
            sortedIngredients = Array(tableViewDict.keys)
            sortedIngredients.sort(by: < )
        }
        ingredTableView.isEditing = false
        isRevising = false
        //load and sort departments
        let deptPath:String = Bundle.main.path(forResource: "department", ofType: "plist")!
        sortedDept = NSArray(contentsOfFile: deptPath) as! [String]
        sortedDept.sort(by: < )
        let ingredOrderPath:String = Bundle.main.path(forResource: "ingredOrder", ofType: "plist")!
        ingredientOrder = NSArray(contentsOfFile: ingredOrderPath) as! [String]
        
    }
    //Populate name and directions
    func populateEditScene() {
        directionsTextView.text = recipe.directions
        recipeNameTextfield.text = recipe.name
        recipeNameTextfield.isUserInteractionEnabled = false
        
    }
    //Create dictionaries for editing ingredients
    func createDictionaries() {
        for ingred in recipe.ingredients! {
            var ingredDict = [String:String]()
            let ingredient = (ingred as! Ingredients).item
            let dept = (ingred as! Ingredients).dept
            ingredDict["item"] = ingredient
            ingredDict["dept"] = dept
            tableViewDict[ingredient!] = dept
            self.ingredArray.append(ingredDict)
        }
    }
    @objc func keyboardWillShow(notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 && ingredientsTextField.isFirstResponder {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self.view.window)
        ingredArray.removeAll()
        tableViewDict.removeAll()
    }
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Warning", message: "Yes will delete all changes!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { (action) ->
            Void in
            self.navigationController?.popViewController(animated: true)}))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    @IBAction func saveRecipeButton(_ sender: UIBarButtonItem) {
        
        //check for at least 1 ingredient
        if ingredArray.count < 1 {
            let alert = UIAlertController(title: "No Ingredients", message: "All recipes must have at least 1 ingredient", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }else{
            if recipeNameTextfield != nil && directionsTextView != nil
                && recipeNameTextfield.text != ""  && directionsTextView.text != "" && categoryButton.titleLabel?.text != "Category"{
                startSpinner()
                
                if isBeingEdited == true {
                    let photo:Data = recipe.photo!
                    favorite = recipe.favorite
                    context.delete(recipe)
                    if smallData == nil {
                        smallData = photo
                    }
                    if largeData == nil {
                        largeData = UIImage(named: "no_photo_400.png")!.pngData()
                    }
                }
                recipeIntoDatabase()
                do{
                    try context.save() }
                catch {
                    let error:NSError? = nil
                    print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                }
                self.navigationController?.popViewController(animated: true)
            }else{
                let alert = UIAlertController(title: "Blank field!", message: "All fields must be filled and a category chosen", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func startSpinner() {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.color = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        spinner.startAnimating()
    }
    
    func recipeIntoDatabase() {
        let databaseUsed:String!
        var recipeDict = [String : Any]()
        recipeDict["category"] = categoryButton.titleLabel?.text
        recipeDict["directions"] = directionsTextView.text
        recipeDict["recipeName"] = recipeNameTextfield.text
        recipeDict["favorite"] = favorite
        recipeDict["ingredArray"] = ingredArray
        let modified:Bool = recipe?.modified ?? false
        recipeDict["modified"] = modified
        //Tag User recipe
        if secretNumber != 8845 && isBeingEdited == false {
            recipeDict["modified"] = true
        }
       
        //Is User Administrator
        if secretNumber == 8845 {
            databaseUsed = "publicDB"
        }else {
            databaseUsed = "privateDB"
        }
        if smallData == nil {
            self.smallData = UIImage(named: "no_photo.png")!.pngData()
        }
        if largeData == nil {
           self.largeData = UIImage(named: "no_photo_400.png")!.pngData()
        }
        recipeDict["photo"] = smallData
        let editedRecipe = Recipe.loadRecipes(recipeDict as NSDictionary, context: context)  //nil value must be tested
        let _ = Ingredients.loadIngredients(recipeDict: recipeDict as NSDictionary, context: context)
        if isBeingEdited == true { //update edited recipes for DetailController
            self.delegate?.setRecipeFromEdit(eRecipe: editedRecipe)
        }
        if secretNumber == 8845 && isBeingEdited == true  {
            cloudKitHelper.saveModifiedRecipesToCloud(databaseUsed, largePhoto: largeData, recipeDict: recipeDict as NSDictionary)
        }else if secretNumber != 8845 && isBeingEdited == true && recipe.modified == false {
            print("do not save to cloudKit")
        }else if secretNumber != 8845 && isBeingEdited == true && recipe.modified == true {
            print("got to saving")
            cloudKitHelper.saveModifiedRecipesToCloud(databaseUsed, largePhoto: largeData, recipeDict: recipeDict as NSDictionary)
        }else{
            cloudKitHelper.saveNewRecipesToCloud(databaseUsed, largePhoto: largeData, recipeDict: recipeDict as NSDictionary)
        }
    }
    
    @IBAction func saveIngredButton(_ sender: AnyObject) {
        if deptTextField != nil && ingredientsTextField != nil && deptTextField.text != "" && ingredientsTextField.text != "" {
            var theIngred:String = sortHoldString + ingredientsTextField.text!
            //order ingredients for new recipes
            if isBeingEdited == false {
                theIngred = ingredientOrder[ingredArray.count] + ingredientsTextField.text!
            }
            let dept = deptTextField.text
            //set up an array of dictionaries with each representing an ingredient
            var ingredientDict = [String : String]()
            ingredientDict["item"] = theIngred
            ingredientDict["dept"] = dept
            self.ingredArray.append(ingredientDict)
            
            //setup dictionary array for tableView
            tableViewDict[theIngred] = dept
            sortedIngredients = Array(tableViewDict.keys)
            sortedIngredients.sort(by: { $0.compare($1) == ComparisonResult.orderedAscending})
            ingredTableView.reloadData()
            deptTextField.text = ""
            ingredientsTextField.text = ""
            isRevising = false
        }else{
            let alert = UIAlertController(title: "Blank field!", message: "Both fields must have entries", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func arrangeIngredButton(_ sender: UIBarButtonItem) { //Ingredient Edit barbutton
        if ingredTableView.isEditing == true {
            sender.tintColor = UIColor(red: 0.30, green: 0.65, blue: 0.35, alpha: 1.0)
            sender.title = "Edit"
            ingredTableView.isEditing = false
        }else{
            sender.tintColor = UIColor.red
            sender.title = "Done"
            ingredTableView.isEditing = true
        }
    }
    //MARK - Photo selection methods
    @IBAction func takePhotoButton(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)   {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            picker.modalPresentationStyle = UIModalPresentationStyle.popover
            self.present(picker, animated: true, completion: nil)
            let popper = picker.popoverPresentationController
            popper!.barButtonItem = sender
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        print("didFinishPickingPhoto")
        //create large photo
        let orig: UIImage = info["UIImagePickerControllerOriginalImage"] as! UIImage
        let reducedPhoto: CGSize = CGSize(width: 400.0, height: 400.0)
        UIGraphicsBeginImageContext(reducedPhoto)
        orig.draw(in: CGRect(x: 0, y: 0, width: reducedPhoto.width, height: reducedPhoto.height))
        let largeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        largeData = largeImage.pngData()
        
        //reduce resolution for small coreData photo
        let reducedThumbnail:CGSize  = CGSize(width: 75.0, height: 75.0)
        UIGraphicsBeginImageContext(reducedThumbnail)
        orig.draw(in: CGRect(x: 0, y: 0, width: reducedThumbnail.width, height: reducedThumbnail.height))
        let smallPhoto:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.smallData = smallPhoto.pngData()
        animatePhotoSave(smallPhoto)
        
    }
    
    func animatePhotoSave(_ savedImage: UIImage){
        let frame = determminePhotoFrame()
        let recipePhoto:UIImageView = UIImageView(image:savedImage)
        recipePhoto.frame = frame
        self.directionsTextView.addSubview(recipePhoto)
        gravity.addItem(recipePhoto)
        collider.addItem(recipePhoto)
    }
    
    //determine frame of dropping photo
    func determminePhotoFrame()->CGRect {
        let ipadWidth = self.view.bounds.width
        let rect = CGRect(x: ipadWidth - 200, y: 300.0, width: 100.0, height: 100.0)
        return rect
    }
    
    //MARK - Collision Behavior Delegate Method
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        print("collision")
        gravity.removeItem(item)
        collider.removeItem(item)
        (item as! UIView).removeFromSuperview()
    }
    
    
    @IBAction func selectCategoryButton(_ sender: UIButton) {
        if categoryTableView.isHidden == true {
            categoryTableView.isHidden = false
        }else {
            categoryTableView.isHidden = true
        }
    }

    
    // MARK: - TableView DataSource & Delegate methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == ingredTableView {
            return self.tableViewDict.count
        } else
            if tableView == deptTableView {
                return self.sortedDept.count
            } else {
                return self.categories.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == ingredTableView {
            return 40.0
        }else{
            return 25.0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == deptTableView {
            return "Departments"
        }else{
            return nil
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == ingredTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ingredientCell", for: indexPath) as! IngredientTableViewCell
            cell.ingredCellLabel.text = (sortedIngredients[indexPath.row] as NSString).substring(from: 2)
            cell.deptCellLabel.text = tableViewDict[sortedIngredients[indexPath.row] as String]
            return cell
        }else if tableView == deptTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "deptCell", for: indexPath)
            cell.textLabel?.text = sortedDept[indexPath.row]
            return cell
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
            cell.textLabel?.text = categories[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == ingredTableView {
            return true
        }else{
            return false
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            var index = 0
            var indexToRemove:Int!
            for dict in ingredArray {
                if (dict["item"]! as NSString).substring(from: 2) == (sortedIngredients[indexPath.row] as NSString).substring(from: 2) {
                    indexToRemove = index
                }
                index += 1
            }
            ingredArray.remove(at: indexToRemove)
            tableViewDict.removeValue(forKey: sortedIngredients[indexPath.row])
            sortedIngredients.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if tableView == ingredTableView {
            return true
        }else{
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if tableView == ingredTableView {
            if (sourceIndexPath.row == destinationIndexPath.row) {
                return
            }else{
                let object:String = sortedIngredients[sourceIndexPath.row]
                sortedIngredients.remove(at: sourceIndexPath.row)
                sortedIngredients.insert(object, at: destinationIndexPath.row)
                reconfigureSortingPrefixes()
            }
        }
    }
    
    func reconfigureSortingPrefixes() {
        var i = 0
        var newIngredArray = [[String : String]]()
        for ingred in sortedIngredients {
            for dict in ingredArray{
                if (dict["item"]! as NSString).substring(from: 2) == (ingred as NSString).substring(from: 2) {
                    let item = ingredientOrder[i] + (ingred as NSString).substring(from: 2)
                    let dept = dict["dept"]!
                    let newDict = ["item":item , "dept":dept]
                    newIngredArray.append(newDict)
                }
            }
            i += 1
        }
        ingredArray = newIngredArray
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == categoryTableView {
            let buttonLabel: String = self.categories[indexPath.row]
            categoryButton.setTitle(buttonLabel, for: UIControl.State.normal)
            categoryButton.setTitleColor(UIColor.black, for: UIControl.State.normal )
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.isHidden = true
            
        }else if tableView == deptTableView {
            deptTextField.text = self.sortedDept[indexPath.row]
            tableView.deselectRow(at: indexPath, animated: true)
        }else{
            if isRevising == true {
                let alert = UIAlertController(title: "Attempting to edit again before saving", message: "First save your edit", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }else {
                ingredientsTextField.text = (sortedIngredients[indexPath.row] as NSString).substring(from: 2)
                sortHoldString = (sortedIngredients[indexPath.row] as NSString).substring(to: 2)
                deptTextField.text = tableViewDict[sortedIngredients[indexPath.row]]
                var index = 0
                var indexToRemove:Int!
                for dict in ingredArray {
                    if (dict["item"]! as NSString).substring(from: 2) == (sortedIngredients[indexPath.row] as NSString).substring(from: 2) {
                        indexToRemove = index
                    }
                    index += 1
                }
                ingredArray.remove(at: indexToRemove)
                tableViewDict.removeValue(forKey: sortedIngredients[indexPath.row])
                sortedIngredients.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
                isRevising = true
            }
        }
    }
    
    // MARK: - TextField Delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
       /* if textField ==  ingredientsTextField && keybdIsShowing == true {
            self.view.frame.origin.y = 0
        }else{
            self.view.frame.origin.y = 50
        }
        self.view.frame.origin.y = 0 */
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
       /* if textField ==  ingredientsTextField && keybdIsShowing == true {
            self.view.frame.origin.y = -275
        }else{
            self.view.frame.origin.y = -50
        }
 */
    }
    
    // MARK: - CloudHelper Delegate Methods
    
    func progressUpdate(records:Int) {
        
    }
    
    func errorUpdating(_ error: NSError) {
        DispatchQueue.main.async(execute: {
            let message = error.localizedDescription
            let alert = UIAlertController(title: "Error loading Data", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    func noFiletoImport() {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: "No file to import", message: "Try again", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    func noAuthentication(){
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: "iCloud sign-in required", message: "Please go to Settings and sign in.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    func modelUpdated(){
        print("model updated")
    }
    
    func dataUpdated(records:Int) {}

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
