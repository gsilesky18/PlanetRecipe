//
//  DetailViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 11/22/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData
import MessageUI
import CloudKit

class DetailViewController: UIViewController, UIPopoverPresentationControllerDelegate, UICollisionBehaviorDelegate, MFMailComposeViewControllerDelegate,SetRecipeFromEditDelegate{
    
    var favButton:UIButton!
    var spinner:UIActivityIndicatorView!
    var imageView:UIImageView!
    var ingredients = [String]()
    var shoppingDict:Dictionary = [String:String]()
    
    @IBOutlet weak var splashImageView: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var scrollView: UIScrollView!
    var context:NSManagedObjectContext!
    var width:CGFloat!  
    var container: CKContainer
    var publicDB: CKDatabase
    var recipe: Recipe?
    
    required init(coder aDecoder:NSCoder) {
        container = CKContainer(identifier: "iCloud.com.zanysocksapps.PRPhoneS")
        publicDB = container.publicCloudDatabase
        super.init(coder: aDecoder)!
    }
    
    func configureView() {
        guard let recipe else { return }
        self.title = recipe.name
        var totalHeight:CGFloat = 0.0
        createSpinner()
        createFavButton()
        loadPhoto()
        totalHeight = totalHeight + 415.0
        totalHeight = loadHeading(yLoc: totalHeight) + totalHeight
        totalHeight = loadIngredients(yLoc: totalHeight) + totalHeight
        totalHeight = loadDirectionsHeading(yLoc: totalHeight) + totalHeight
        totalHeight = loadDirections(yLoc: totalHeight) + totalHeight
        scrollView.contentSize = ContentSize.getContentSize(width: view.bounds.width, recipe: recipe)
    }
    
    func setRecipeFromEdit(eRecipe: Recipe) {
        recipe = eRecipe
        configureView()
    }
    
    //Create feature to drop recipe into list
    lazy var animator:UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: scrollView)
        return lazilyCreatedDynamicAnimator
    }()
    let gravity = UIGravityBehavior()
    let collider = UICollisionBehavior()
    
    //Create path for saving and reading shopping list
    func listFilePath() ->String {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = (documents as NSString).appendingPathComponent("shoppingList.plist")
        return writePath
    }
    
    //create alternative splash images
    func splashImage()->UIImage {
        switch (arc4random()%4) {
        case 0: return UIImage(named: "splash1.png")!
        case 1: return UIImage(named: "splash2.png")!
        case 2: return UIImage(named: "splash3.png")!
        case 3: return UIImage(named: "splash4.png")!
        default: return UIImage(named: "splash1.png")!
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ingredients.removeAll()
        let subViews = self.scrollView.subviews
        for subview in subViews{
            subview.removeFromSuperview()
        }
        configureView()
        navigationItem.leftBarButtonItem?.title = "Recipe List"
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationItem.leftBarButtonItem?.title = "Recipe List"
    }
    override func viewDidLoad() {
        //Read Shopping file if it exists
        if FileManager.default.fileExists(atPath: listFilePath()) {
            shoppingDict = NSDictionary(contentsOfFile: listFilePath()) as! Dictionary
        }
        NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        collider.collisionDelegate = self
        animator.addBehavior(gravity)
        gravity.magnitude = 0.5
        animator.addBehavior(collider)
        
        let ptLeft = CGPoint(x: 0, y: scrollView.contentSize.height)
        let ptRight = CGPoint(x: view.bounds.width, y: scrollView.contentSize.height)
        collider.addBoundary(withIdentifier: "bottom" as NSCopying, from: ptLeft, to: ptRight)
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = false
        navigationController?.navigationBar.tintColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        navigationItem.leftBarButtonItem?.title = "Recipe List"
        navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        splashImageView.image = splashImage()
        if let _ = self.recipe {
            splashImageView.isHidden = true
            scrollView.isHidden = false
        }else{
            scrollView.isHidden = true
            splashImageView.isHidden = false
        }
    }
    
    @objc func rotated(){
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            let subViews = self.scrollView.subviews
            for subview in subViews{
                subview.removeFromSuperview()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(UIDevice.orientationDidChangeNotification)
    }
    
    //Construct ScrollView contentSize
    
    func loadHeading(yLoc: CGFloat) -> CGFloat {
        let height:CGFloat = 75.0
        let headingFrame = CGRect(x: 50.0, y: yLoc, width: view.bounds.width, height: height)
        let headingLabel = UILabel(frame: headingFrame)
        headingLabel.text = "INGREDIENTS"
        headingLabel.font = UIFont(name: "Helvetica-Bold", size: 20)
        headingLabel.textColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        headingLabel.textAlignment = .left
        scrollView.addSubview(headingLabel)
        return height
    }
    
    func loadIngredients(yLoc:CGFloat) -> CGFloat {
        guard let recipe else { return  0 }
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
            let height = ingredStr.height(withConstrainedWidth: view.bounds.width, font: ingredFont!)
            let ingredFrame = CGRect(x: 50.0, y: yLoc + totHeight, width: view.bounds.width, height: height)
            let ingredLabel = UILabel(frame: ingredFrame)
            ingredLabel.font = ingredFont
            ingredLabel.text = ingredStr
            ingredLabel.textColor = UIColor.black
            ingredLabel.textAlignment = .left
            ingredLabel.numberOfLines = 2
            scrollView.addSubview(ingredLabel)
            totHeight += height
        }
        return totHeight
    }
    func loadDirectionsHeading(yLoc:CGFloat) ->CGFloat {
        let height:CGFloat = 75.0
        let headingFrame = CGRect(x: 50.0, y: yLoc, width: view.bounds.width, height: height)
        let headingLabel = UILabel(frame: headingFrame)
        headingLabel.text = "DIRECTIONS"
        headingLabel.font = UIFont(name: "Helvetica-Bold", size: 20)
        headingLabel.textColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        headingLabel.textAlignment = .left
        scrollView.addSubview(headingLabel)
        return height
    }
    func loadDirections(yLoc:CGFloat) -> CGFloat {
        guard let recipe else { return 0 }
        let directions = recipe.directions
        let dirFont = UIFont(name: "Helvetica", size: 16.0)
        let indent:CGFloat = 50.0
        let height = directions?.height(withConstrainedWidth: view.bounds.width - (2.0 * indent), font: dirFont!)
        let dirFrame = CGRect(x: indent, y: yLoc, width: view.bounds.width - (2.0 * indent), height: height!)
        let dirLabel = UILabel(frame: dirFrame)
        dirLabel.text = directions
        dirLabel.font = dirFont
        dirLabel.textColor = UIColor.black
        dirLabel.textAlignment = .left
        dirLabel.numberOfLines = 150
        scrollView.addSubview(dirLabel)
        return height! + 20.0
    }
    
    //create imageView for photo
    func loadPhoto() {
        guard let recipe else { return }
        let xLoc = (view.bounds.width / 2.0) - 200.0
        let photoFrame = CGRect(x: xLoc, y: 15.0, width: 400.0, height: 400.0)
        imageView = UIImageView(frame: photoFrame)
        scrollView.addSubview(imageView)
        retrievePhotoImage(recipe.name!)
    }
    
    func createSpinner() {
        let spinnerFrame = CGRect(x: view.bounds.width / 2.0, y: 200.0, width: 30.0, height: 30.0)
        spinner = UIActivityIndicatorView(frame: spinnerFrame)
        spinner.hidesWhenStopped = true
        spinner.style = UIActivityIndicatorView.Style.large
        spinner.color = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        scrollView.addSubview(spinner)
    }
    
    func createFavButton() {
        let labelFrame = CGRect(x: 30.0, y: 30.0, width: 80.0, height: 30.0)
        let favLabel = UILabel(frame: labelFrame)
        favLabel.text = "Favorite"
        favLabel.font = UIFont(name: "Helvetica", size: 16.0)
        favLabel.textAlignment = .center
        favLabel.textColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
        scrollView.addSubview(favLabel)
        let favButtonFrame = CGRect(x: 110.0, y: 30.0, width: 30.0, height: 30.0)
        favButton = UIButton(frame: favButtonFrame)
        favButton.isEnabled = true
        favButton.addTarget(self, action: #selector(favButtonTapped), for: .touchUpInside)
        scrollView.addSubview(favButton)
        if recipe?.favorite == true {
            favButton.setImage(UIImage(named: "heart30"), for: .normal)
        }else{
            favButton.setImage(UIImage(named: "noHeart30"), for: .normal)
        }
    }
    
    @objc func favButtonTapped() {
        if favButton.image(for: .normal) == UIImage(named: "noHeart30") {
            favButton.setImage(UIImage(named: "heart30"), for: .normal)
            recipe?.favorite = true
        }else {
            favButton.setImage(UIImage(named: "noHeart30"), for: .normal)
            recipe?.favorite = false
        }
        do {
            try context.save()
        } catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
    }
    
    //retrieve image from cloudkit
    func retrievePhotoImage(_ name:String) {
        var dataBase:CKDatabase
        var recArray = [CKRecord]()
        spinner.startAnimating()
        let reachability = Reachability()
        if reachability.isConnectedToNetwork() == false {
            spinner.stopAnimating() }
        if recipe?.modified == false {
            dataBase = self.container.publicCloudDatabase
        }else {
            dataBase = self.container.privateCloudDatabase
        }
        let predicate = NSPredicate(format: "recipeName = %@", name)
        let query = CKQuery(recordType: "RecipeFile", predicate: predicate)
        let queryOpertion = CKQueryOperation(query: query)
        dataBase.add(queryOpertion)
        queryOpertion.qualityOfService = QualityOfService.userInteractive

        queryOpertion.recordFetchedBlock = { record in
            recArray.append(record)
            if recArray.isEmpty {
                let mainQueue = OperationQueue.main
                mainQueue.addOperation(){
                    self.imageView.image = UIImage(named: "no_photo_400")
                    self.spinner.stopAnimating()
                }
            }
            let image = record["photo"] as? CKAsset
            if let _  = image { // check for missing photo
                if let url = image?.fileURL {
                    let imageData = try? Data(contentsOf: url)
                    let mainQueue = OperationQueue.main
                    mainQueue.addOperation(){
                        self.spinner.stopAnimating()
                        self.imageView.image = UIImage(data: imageData!)
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func addtoList(_ sender: UIBarButtonItem) {
        guard let recipe else { return }
        if FileManager.default.fileExists(atPath: listFilePath()) {
            shoppingDict = NSDictionary(contentsOfFile: listFilePath()) as! Dictionary
        }
        let frame = determinePhotoFrame()
        let recipePhoto:UIImageView = UIImageView(image: UIImage(data: recipe.photo!))
        recipePhoto.frame = frame
        scrollView.addSubview(recipePhoto)
        gravity.addItem(recipePhoto)
        collider.addItem(recipePhoto)
         print("\(shoppingDict) preload")
        for ingr in recipe.ingredients! {
            let item:String = (ingr as! Ingredients).item!
            let dept:String = (ingr as! Ingredients).dept!
            shoppingDict[item] = dept
        }
        (shoppingDict as NSDictionary).write(toFile: listFilePath(), atomically: true)
       
    }
    
    func determinePhotoFrame() -> CGRect {
        let rect = CGRect(x: (view.bounds.width / 2.0) - 50.0, y: 415.0, width: 100.0, height: 100.0)
        return rect
    }
    
    //Mail Methods
    
    @IBAction func mailRecipe(_ sender: UIBarButtonItem) {
        guard let recipe else { return }
        let mailMessage = "RECIPE: " + recipe.name! + "\n" + "\nINGREDIENTS" + getIngredientsForMail(recipe)
            + "\n" + "\nDIRECTIONS\n" + recipe.directions! + "\n\n" + "Get the App: https://itunes.apple.com/us/app/planet-recipe/id590878471?mt=8"
        let mailComposeViewController = configuredMailComposeViewController(mailMessage as String)
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController(_ textView: String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposerVC.setSubject(recipe!.name!)
        mailComposerVC.setMessageBody(textView, isHTML: false)
        mailComposerVC.navigationBar.tintColor = UIColor(red: 0.30, green: 0.65, blue: 0.35, alpha: 1.0)
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: UIAlertController.Style.alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: { print("Mail sent") })
    }
    
    func getIngredientsForMail(_ recipe:Recipe) -> String {
        var correctedIngredients = String()
        var ingredients:[String] = [String]()
        for object in recipe.ingredients! {
            let item:String = (object as! Ingredients).item!
            ingredients.append(item)
        }
        ingredients.sort(by: { $0.compare($1) == ComparisonResult.orderedAscending })
        for objects in ingredients {
            let strippedIngred = (objects as NSString).substring(from: 2)
            correctedIngredients += "\n-" + strippedIngred
        }
        return correctedIngredients
    }
     //MARK CollisionBehavior Delegate Method
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        gravity.removeItem(item)
        collider.removeItem(item)
        (item as! UIView).removeFromSuperview()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toIinstructions" {
            
        }
        if segue.identifier == "shopping" {
            let shoppingContoller = segue.destination as! ListViewController
            let controller = shoppingContoller.popoverPresentationController
            if controller != nil {
                controller?.delegate = self
            }
        }
        if segue.identifier == "toNew" {
            //check for passed context
            if context == nil {
                self.dismiss(animated: true, completion: nil)
                let alert = UIAlertController(title: "Existing recipe must be first selected", message: "Then select + to add new recipe", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }else{
                let newRecipeController = segue.destination as! EditViewController
                newRecipeController.title = "Enter New Recipe"
                newRecipeController.isBeingEdited = false
                newRecipeController.context = context
                newRecipeController.title = "Enter New Recipe"
            }
        }
        if segue.identifier == "toEdit" {
            let editController = segue.destination as! EditViewController
            editController.recipe = recipe
            editController.isBeingEdited = true
            editController.delegate = self
            editController.context = context
            editController.title = "Edit Recipe"
        }
        if segue.identifier == "toPartyPlanner" {
            let ppc = segue.destination as! HistoryDetailViewController
            ppc.context = context
        }
    }
}




//Extensions for finding space required for given amount of text with a specific font
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}

