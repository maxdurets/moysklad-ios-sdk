//
//  Positions.swift
//  MoyskladNew
//
//  Created by Kostya on 26/10/2016.
//  Copyright © 2016 Andrey Parshakov. All rights reserved.
//

//import Money
import Foundation

public class MSPosition : Metable {
	public let meta : MSMeta
	public let id : MSID
	public var assortment : MSEntity<MSAssortment>
	public var quantity : Double
    public var reserve: Double
    public var shipped: Double
	public var price : Money
	public var discount : Double
	public var vat : Int
    
    public init(meta : MSMeta,
    id : MSID,
    assortment : MSEntity<MSAssortment>,
    quantity : Double,
    reserve: Double,
    shipped: Double,
    price : Money,
    discount : Double,
    vat : Int) {
        self.meta = meta
        self.id = id
        self.assortment = assortment
        self.quantity = quantity
        self.reserve = reserve
        self.shipped = shipped
        self.price = price
        self.discount = discount
        self.vat = vat
    }
    
    public func copy() -> MSPosition {
        return MSPosition(meta: meta,
                          id: id,
                          assortment: assortment,
                          quantity: quantity,
                          reserve: reserve,
                          shipped: shipped,
                          price: price,
                          discount: discount,
                          vat: vat)
    }
}
