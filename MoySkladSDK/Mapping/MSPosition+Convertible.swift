//
//  MSPosition+Convertible.swift
//  MoyskladNew
//
//  Created by Anton Efimenko on 31.10.16.
//  Copyright © 2016 Andrey Parshakov. All rights reserved.
//

//import Money

extension MSPosition : DictConvertable {
    public func dictionary() -> Dictionary<String, Any> {
        return [String:Any]()
    }
    
    public static func from(dict: Dictionary<String, Any>) -> MSEntity<MSPosition>? {
        guard let meta = MSMeta.from(dict: dict.msValue("meta"), parent: dict),
            let assortment = MSAssortment.from(dict: dict.msValue("assortment")) else {
            return nil
        }
        
        return MSEntity.entity(MSPosition(meta: meta,
                   id: MSID(dict: dict),
                   assortment: assortment,
                   quantity: dict.value("quantity") ?? 0,
                   reserve: dict.value("reserve") ?? 0,
                   shipped: dict.value("shipped") ?? 0,
                   price: Money(minorUnits: dict.value("price") ?? 0),
                   discount: dict.value("discount") ?? 0,
                   vat: dict.value("vat") ?? 0))
    }
}
