//
//  InstructionsViewController.swift
//  Planet Recipe iPad
//
//  Created by H Steve Silesky on 12/4/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import WebKit

class InstructionsViewController: UIViewController {
    
    
    @IBOutlet var instructionWK: WKWebView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Instructions"
        let bundle = Bundle.main
        if let instrURL  = bundle.url(forResource: "Instructions", withExtension: "pdf") {
            let request = URLRequest(url: instrURL)
            instructionWK.load(request)
        }
        navigationController?.navigationBar.tintColor = UIColor(red: 0.3, green: 0.65, blue: 0.35, alpha: 1.0)
    }
}
