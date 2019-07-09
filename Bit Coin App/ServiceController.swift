//
//  ServiceController.swift
//  Bit Coin App
//
//  Created by Luis javier perez torres on 6/25/19.
//  Copyright © 2019 Xavier. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ServiceController: UIViewController{
    
    @IBOutlet weak var rateLabel: UILabel!
    var varForCoinType: CoinType?
    var lastButtonTapped: String?
    @IBOutlet weak var buttonGBP: UIButton!
    @IBOutlet weak var buttonUSD: UIButton!
    @IBOutlet weak var buttonEUR: UIButton!
    var defaultColor: UIColor?
    
    var coins: [String: CoinProps] = [:]
    var requestCoins: [CoinProps] = []
    
    
    struct CoinType: Codable{
        //bpi segment in the recived json
        let bpi: CoinStruct
        enum CodingKeys: String, CodingKey{
            case bpi
        }
    }
    
    struct CoinStruct: Codable{
        /* Catch the data of all the money type, used this way insted of
         array of CoinProps because is easier to retreve the data this way */
        let EUR: CoinStructProps
        let USD: CoinStructProps
        let GBP: CoinStructProps
        private enum CodingKeys: String, CodingKey {
            case EUR
            case USD
            case GBP
        }
    }
    
    struct CoinStructProps: Codable { //"Coin Properties"
        //Code may be: USD, EUR, GBP and respective rate.
        let code: String
        let rate: String
        enum CodingKeys: String, CodingKey {
            case code
            case rate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.defaultColor = buttonUSD.backgroundColor
        
        connectionToAPI("USD")
        //Load from database
//        let fetchRequest: NSFetchRequest<CoinProps> = CoinProps.fetchRequest()
//        getFromDataBase(fetchRequest)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Buttons should be disable until the connection is complete
        if coins.isEmpty {
            enableButtons(false)
        }
    }
    
    
    func connectionToAPI(_ code:String){
        guard let url = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json") //Create a URL with the actual url
            else{
                print("Error with the URL!")
                return
        }
        
        let task = URLSession.shared.dataTask(with: url){ //URLseassion is a GET method
            (data, response, error) in guard let _ = data, error == nil //Check if we got any kind of data and that there are no errors
                else { //if error...
                    print("Error(1):")
                    print(error?.localizedDescription ?? "Response Error")
                    //Display alert message
                    DispatchQueue.main.async{
                        let fetchRequest: NSFetchRequest<CoinProps> = CoinProps.fetchRequest()
                        if self.fetchRequestIsEmpty(fetchRequest){ //IF the data base is empty, then there must be an error
                            self.rateLabel.text = "Connection error."
                            self.enableButtons(false)
                        } else{ //If data base has values inside, then it should load rates from there.
                            self.enableButtons(true)
                            self.getFromDataBase(fetchRequest)
                            self.showDataInLabel(code)
                        }
                        print("coins not empty")
                    }
                    let alert = UIAlertController(title: "There seems to be a problem", message: error?.localizedDescription ?? "Response Error", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert,animated: true)
                    return
            }
            
            do{
                //If everything went ok
                let decoder = JSONDecoder()
                
                //let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
                let jsonResponse = try decoder.decode(CoinType.self, from: data!) //put the date in the CoinType Struct
                self.varForCoinType = jsonResponse
                DispatchQueue.main.async { //call a thread that updates the rateLabel
                    self.enableButtons(true)
                    self.createCoreDataObject()
                    self.showDataInLabel(code)
                    /*
                    if code == "USD"{
                        self.rateLabel.text = code + ": \n $" +  jsonResponse.bpi.USD.rate
                    }
                    else if code == "GBP"{
                        self.rateLabel.text = code + ": \n " +  jsonResponse.bpi.GBP.rate
                    }
                    else if code == "Euro"{
                        self.rateLabel.text = "EUR: \n " +  jsonResponse.bpi.EUR.rate
                    }*/
                }
            } catch let parsingError {
                print("Error(2):", parsingError) //if there was an error with the decoder
            }
        }
        task.resume() //Excecute task
    }
    
    func createCoreDataObject(){
        print("create data object")
        let fetchRequest: NSFetchRequest<CoinProps> = CoinProps.fetchRequest()
        
        //check if the data base is empty
        if fetchRequestIsEmpty(fetchRequest){ //if is empty, create new objects for the data base, and save it
            print("DB is empty")
            let coinUSD = CoinProps(context: PersistenceService.context)
            let coinGBP = CoinProps(context: PersistenceService.context)
            let coinEUR = CoinProps(context: PersistenceService.context)
            
            coinUSD.code = varForCoinType!.bpi.USD.code
            coinUSD.rate = varForCoinType!.bpi.USD.rate
            coins["USD"] = coinUSD
            
            coinEUR.code = varForCoinType!.bpi.EUR.code
            coinEUR.rate = varForCoinType!.bpi.EUR.rate
            coins["EUR"] = coinEUR
            
            coinGBP.code = varForCoinType!.bpi.GBP.code
            coinGBP.rate = varForCoinType!.bpi.GBP.rate
            coins["GBP"] = coinGBP
            PersistenceService.saveContext()
        }
        else{ //If it isn't empty, uptade each one in the data base.
            getFromDataBase(fetchRequest)
            coins["USD"]?.rate = varForCoinType!.bpi.USD.rate
            coins["EUR"]?.rate = varForCoinType!.bpi.EUR.rate
            coins["GBP"]?.rate = varForCoinType!.bpi.GBP.rate
            PersistenceService.saveContext()
        }
    }
    
    func fetchRequestIsEmpty(_ request: NSFetchRequest<CoinProps>) -> Bool{
        do{
            self.requestCoins = try PersistenceService.context.fetch(request)
            if self.requestCoins.isEmpty {
                return true
            } else {
                return false
            }
        } catch {
            
        }
        return false
    }
    
    func getFromDataBase(_ request: NSFetchRequest<CoinProps>){
        //var fetchIsEmpty = false
//        do {
            //Search for each item in the data base, because we don't know what order does it have if we
            //call it for the whole request.
//            request.predicate = NSPredicate(format: "code == %@", "USD")
//            var coinReturn = try PersistenceService.context.fetch(request)
//            fetchIsEmpty = loadCoreDataObject(coinReturn, "USD")
//
//            request.predicate = NSPredicate(format: "code == %@", "EUR")
//            coinReturn = try PersistenceService.context.fetch(request)
//            fetchIsEmpty = loadCoreDataObject(coinReturn, "EUR")
//
//            request.predicate = NSPredicate(format: "code == %@", "GBP")
//            coinReturn = try PersistenceService.context.fetch(request)
//            fetchIsEmpty = loadCoreDataObject(coinReturn, "GBP")
            addPredicateToRequest(request, "USD")
            addPredicateToRequest(request, "EUR")
            addPredicateToRequest(request, "GBP")
//        } catch let parsingError {
//            print("(!) Error:", parsingError)
//
//            //connectionToAPI("USD") //Default call must be USD
//        }
//
//        if fetchIsEmpty == true {
//            print("(!) forcing update from API")
//            //connectionToAPI("USD")
//        } else {
//            print("loaded from DB")
//            //enableButtons(true)
//            //showDataInLabel("USD")
//        }
    }
    
    func addPredicateToRequest(_ request: NSFetchRequest<CoinProps>, _ code: String){
        do{
            request.predicate = NSPredicate(format: "code == %@", code)
            let coinReturn = try PersistenceService.context.fetch(request)
            loadCoreDataObject(coinReturn, code)
        } catch {
            print("(!) Error in the predicate")
        }
    }
    
    func loadCoreDataObject(_ fetchList: [CoinProps], _ code: String){
        if fetchList.isEmpty{
            print("(!) \(code) Empty")
            //return true
            return
        }
        //take the returned item of the data base and save it in the dictionary.
        coins[code] = fetchList.last
        
        print("NotEmpty \(String(describing: coins[code]!.rate))")
        //return false
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        
        guard !coins.isEmpty else {
            return
        }
        setLastButtonTapped(sender.titleLabel!.text!)
        showDataInLabel(sender.titleLabel!.text!)
    }
    
    @IBAction func reloadTapped(_ sender: Any) {
        connectionToAPI(lastButtonTapped ?? "USD")
    }

    func enableButtons(_ status: Bool){
        buttonEUR.isEnabled = status
        buttonGBP.isEnabled = status
        buttonUSD.isEnabled = status
        
        if status == false{
            buttonUSD.backgroundColor = UIColor.gray
            buttonGBP.backgroundColor = UIColor.gray
            buttonEUR.backgroundColor = UIColor.gray
        } else {
            buttonUSD.backgroundColor = defaultColor
            buttonGBP.backgroundColor = defaultColor
            buttonEUR.backgroundColor = defaultColor
        }
    }
    
    func setLastButtonTapped(_ code: String){
        lastButtonTapped = code
        print("Button tapped: \(lastButtonTapped!)")
    }
    
    func showDataInLabel(_ code: String){
        self.rateLabel.text = "\(code): \n\(coins[code]!.rate!)"
    }
}
