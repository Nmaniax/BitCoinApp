//
//  CoinProps+CoreDataProperties.swift
//  Bit Coin App
//
//  Created by Luis javier perez torres on 7/2/19.
//  Copyright © 2019 Xavier. All rights reserved.
//
//

import Foundation
import CoreData


extension CoinProps {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoinProps> {
        return NSFetchRequest<CoinProps>(entityName: "CoinProps")
    }

    @NSManaged public var code: String?
    @NSManaged public var rate: String?

}
