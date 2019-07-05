//
//  CoinModel.swift
//  Bit Coin App
//
//  Created by Luis javier perez torres on 7/2/19.
//  Copyright © 2019 Xavier. All rights reserved.
//

import Foundation
import CoreData

class Coin: NSManagedObject{
    @NSManaged var code: String?
    @NSManaged var rate: String?
    
}
