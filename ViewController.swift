//
//  ViewController.swift
//  MyScheme
//
//  Created by Florian Schut on 05/10/15.
//  Copyright © 2015 Florian Schut. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    //MARK: Variables
    var jsonExtraction = JsonExtraction()
    //An array with every "leerling nummer" of every student
    var students: Array<String>?
    //An array with the lectures to be displayed
    //Using Dictionarys for both this and changes beacause of the way a tableView is populated
    var schemeDictionary:[String:Array<String>] = ["Maandag":[], "Dinsdag":[], "Woensdag":[], "Donderdag":[], "Vrijdag":[]]
    //Booleans for every lecture true if to be made red
    var changesDictionary:[String:Array<Bool>] = ["Maandag":[], "Dinsdag":[], "Woensdag":[], "Donderdag":[], "Vrijdag":[]]
    //The amount of lessons for every day
    //Used to dertirmine the amount of rows per section
    var lecturesPerDay:[Int] = []
    //Data for populateScheme function
    var schemeArray:[String] = []
    var changesArray:[String] = []
    //Used as key for schemeDictionary and header titles
    let days = ["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag"]
    var shownID: String?
    var userID: String?
    //True if the scheme is done loading
    var gotScheme = false
    //Show when stuff goes shouth... Or is loading
    var errorMessage = "Aan het laden..."
    
    //Adding UI Ellements
    @IBOutlet weak var schemeTableView: UITableView!
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("toSettingsSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.schemeTableView.dataSource = self
        self.schemeTableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //Called when the view is shown
        if Reachability.isConnectedToNetwork(){
            //Using this over the standard viewDidLoad since it's imposible to call segue's before the view is loaded.
            let defaults = NSUserDefaults.standardUserDefaults()
            //checks if both values are pressent and sets leerlingNr and studentID to nr and id respectively and loads the jsondata
            //else send the user to the settings page
            if let shownID = defaults.stringForKey("shownID"){
                if let id = defaults.stringForKey("userID"){
                    self.shownID = shownID
                    self.userID = id
                    self.jsonExtraction.callJson(id, handleData: self.outputHandler)
                }else{
                    self.performSegueWithIdentifier("toSettingsSegue", sender: self)
                }
            }else{
                self.performSegueWithIdentifier("toSettingsSegue", sender: self)
            }
        }else{
            dispatch_async(dispatch_get_main_queue(), {
                self.errorMessage = "No internet connection"
                self.schemeTableView.reloadData()
            })
        }
    }
    
    //MARK: Setting up tableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //The code to set the number of rows
        if self.gotScheme{
            return self.lecturesPerDay[section]
        }else{
            //only one for the error/waiting message
            return 1
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //if all days are populated (lecturesPerDay contains 5 items) the value is set to 5 else to 1
        //This is for the message before the scheme is loaded.
        if self.gotScheme{
            return 5
        }else{
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //The code to set what is displayed in a row of the tableView
        let cell = tableView.dequeueReusableCellWithIdentifier("schemeCell", forIndexPath:indexPath)
        if self.gotScheme{
            //Puts the hour and lecture in an array to be propperly displayed
            let dataPerDay = self.schemeDictionary[self.days[indexPath.section]]![indexPath.row].componentsSeparatedByString(":")
            //Using Days[] for the key and row for array index to populate label from schemeDict
            cell.detailTextLabel!.text = dataPerDay[0]
            cell.detailTextLabel!.font = UIFont.italicSystemFontOfSize(16)
            cell.textLabel!.text = dataPerDay[1]
            if self.changesDictionary[days[indexPath.section]]![indexPath.row]{
                //Checks for changes and sets a more outstanding color
                cell.textLabel!.textColor = UIColor.redColor()
                print("\(indexPath.row),\(self.schemeDictionary[days[indexPath.section]]![indexPath.row])")
            }else{
                cell.textLabel!.textColor = UIColor.blackColor()
            }
        }else{
            dispatch_async(dispatch_get_main_queue(), {
                cell.textLabel!.text = self.errorMessage
                cell.detailTextLabel!.text = ""
            })
        }
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //Sets the headers to the appropriate day or a message telling the data isn't loaded (yet)
        if self.gotScheme{
            return self.days[section]
        }else{
            return "Rooster niet geladen..."
        }
    }
    
    func outputHandler(output: Dictionary<String,Array<String>>?){
        if output != nil {
            if output!["error"] == nil {
                print(output)
                //Checks if required data is in output to be able to force unwrap
                if (output?["scheme"] != nil && output?["changes"] != nil && output?["scheme"]!.count == 30 && output?["changes"]!.count == 30){
                    self.schemeArray = output!["scheme"]!
                    self.changesArray = output!["changes"]!
                    //Checks if there is something in output[id] and compares it to shownID
                    if (output?["id"] != nil && !output!["id"]!.isEmpty && (output!["id"]!)[0] == self.shownID!){
                        dispatch_async(dispatch_get_main_queue(), {
                            self.populateScheme()
                            return
                        })
                    }
                }
            }else{
                dispatch_async(dispatch_get_main_queue(), {
                    print(output!["error"])
                    self.errorMessage = output!["error"]![0]
                    self.schemeTableView.reloadData()
                })
                return
            }
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.errorMessage = "Laden rooster mislukt..."
            self.schemeTableView.reloadData()
        })
    }
    
    func populateScheme(){
        var lecture = 0
        for var printedDay = 0; printedDay < 5; ++printedDay{
            //A loop that runs through all days of the week
            //The amount of lectures on one day to be passed into lecturesPerDay
            //Upped at every shown lecture
            var lengthOfDay = 0
            //Key for schemeDictinary
            let schemeKey = self.days[printedDay]
            
            for ; (lecture + 1) <= ((printedDay + 1) * 6); ++lecture {
                //An other loop that runs through each hour of the day
                
                //The code to show one hour
                let changes = self.changesArray[lecture]
                //Uses the changes array to determine the style (plain, red, red-strikethrough)
                switch changes {
                    //checks for changes if it is something to take notice of: sets it in an array to be marked red when filling the tableView
                    //0: Normal -> Black (default in this switch)
                    //1: Changed -> Red
                    //2: Droped lesson -> Red
                case "1":
                    self.schemeDictionary[schemeKey]!.append("\((lecture+1) - 6*printedDay):\(self.schemeArray[lecture])")
                    self.changesDictionary[schemeKey]!.append(true)
                    ++lengthOfDay
                case "2":
                    self.schemeDictionary[schemeKey]!.append("\((lecture+1) - 6*printedDay):Les uitgevallen")
                    self.changesDictionary[schemeKey]!.append(true)
                    ++lengthOfDay
                default:
                    if self.schemeArray[lecture] != "VRIJ VRIJ VRIJ"{
                        ++lengthOfDay
                        self.schemeDictionary[schemeKey]!.append("\((lecture+1) - 6*printedDay):\(self.schemeArray[lecture])")
                        self.changesDictionary[schemeKey]!.append(false)
                    }
                }
            }
            //Adds the lenght of the day at the end of the loop into the array
            self.lecturesPerDay.append(lengthOfDay)
        }
        //Repopulates the tableView
        self.gotScheme = true
        self.schemeTableView.reloadData()
    }
}