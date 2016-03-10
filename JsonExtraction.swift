//
//  JsonExtraction.swift
//  MyScheme
//
//  Created by Florian Schut on 05/10/15.
//  Copyright © 2015 Florian Schut. All rights reserved.
//

import Foundation

class JsonExtraction {
    
    //Local storage for all that get extracted by callJson
    var jsonOutput: Dictionary<String,Array<String>>?
    
    //The base URL where all the data is stored on the server
    let baseURL = "http://brc.florianschut.nl/IMP/"
    
    //Function to get data from the Json Files with a file parameter that states the file to be extracted
    func callJson(file: String, handleData: ((Dictionary<String,Array<String>>?)->Void) ){
        //the url that stores the json file consisting of the base url and the file name and a .json at the end
        let jsonUrl = "\(self.baseURL)\(file).json"
        
        //some generic stuff to parse json files
        let session = NSURLSession.sharedSession()
        let shotsUrl = NSURL(string: jsonUrl)
        let task = session.dataTaskWithURL(shotsUrl!){
            (data, response, error) -> Void in
            
            do{
                //Tries to get the data from server
                self.jsonOutput = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? Dictionary<String,Array<String>>
            }
            catch _ {
                //Code gets called when shit hits the fan
                print("Catch up called!")
                //Rerurns a error to be shown
                self.jsonOutput = ["error": ["Rooster niet beschikbaar..."]]
            }
            handleData(self.jsonOutput)
        }
        task.resume()
    }
}