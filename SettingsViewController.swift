//
//  SettingsViewController.swift
//  MyScheme
//
//  Created by Florian Schut on 05/10/15.
//  Copyright © 2015 Florian Schut. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    //MARK: Propeties
    var jsonExtraction = JsonExtraction()
    var data: Dictionary<String,Array<String>>?
    //List of all the Students numbers
    var students: [String]?
    //The ID that reprecents the location on the server
    var userID: String?
    
    //Setting up UI Ellements
    @IBOutlet weak var leerlingNrLabel: UITextField!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBAction func loadPressed(sender: AnyObject) {
        print("Students")
        //Checks if the entered number exists in the Array of students
        if self.students!.contains(self.leerlingNrLabel.text!){
            //Checks the location in the students array and sets it in userID as a string...
            self.userID = String(self.students!.indexOf(self.leerlingNrLabel.text!)! + 1)
            //Makes sure the userID has 5 characters ex: 00024
            while self.userID!.characters.count < 5 {
                self.userID! = "0" + self.userID!
                print(userID!)
            }
            let defaults = NSUserDefaults.standardUserDefaults()
            //Sets userDefaults for use in ViewDidLoad
            defaults.setObject("student/\(self.userID!)", forKey: "userID")
            //shownID is the name/number as shown on the orriginal site
            defaults.setObject(self.leerlingNrLabel.text!, forKey: "shownID")
            //Gets back to main screen
            self.performSegueWithIdentifier("toMainSegue", sender: self)
        }else{
            print("Dat is geen geldig leerling nummer!")
            dispatch_async(dispatch_get_main_queue(), {
                self.errorLabel.text = "Dat is geen geldig leerling nummer."
                self.errorLabel.hidden = false
            })
        }
    }
    
   // var leerlingNrs: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.leerlingNrLabel.becomeFirstResponder()
        self.jsonExtraction.callJson("data", handleData: self.outputHandler)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func outputHandler(output: Dictionary<String,Array<String>>?){
        //Checks for data containing students
        if ((output != nil) && (output!["Students"] != nil)) {
            self.data = output
            //Takes the output from callJson and sets self.students
            self.students = self.data!["Students"]
            print(self.students!)
            dispatch_async(dispatch_get_main_queue(), {
                //Has to be in main tread to change UI elements
                self.loadButton.enabled = true
            })
        }else{
            dispatch_async(dispatch_get_main_queue(), {
                self.errorLabel.hidden = false
            })
            print("error: No output")
        }
    }
}