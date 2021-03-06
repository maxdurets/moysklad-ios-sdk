//
//  Employee+Convertible.swift
//  MoyskladNew
//
//  Created by Anton Efimenko on 26.10.16.
//  Copyright © 2016 Andrey Parshakov. All rights reserved.
//

import Foundation

extension MSEmployee : DictConvertable {
	public func dictionary(metaOnly: Bool) -> Dictionary<String, Any> {
        var dict = [String: Any]()
        
        dict["meta"] = meta.dictionary()
        
        guard !metaOnly else { return dict }
        
        dict.merge(info.dictionary())
        // тут должны быть остальные поля объекта, если они понадобятся
        
        return dict
	}
	
	public static func from(dict: Dictionary<String, Any>) -> MSEntity<MSEmployee>? {
		guard let meta = MSMeta.from(dict: dict.msValue("meta"), parent: dict) else {
			return nil
		}
		
		guard let lastName: String = dict.value("lastName"), lastName.characters.count > 0 else {
			return MSEntity.meta(meta)
		}
		
		return MSEntity.entity(MSEmployee(meta: meta,
		                                  id: MSID(dict: dict),
		                                  info: MSInfo(dict: dict),
		                                  accountId: dict.value("accountId") ?? "",
		                                  code: dict.value("code"),
		                                  externalCode: dict.value("externalCode"),
		                                  archived: dict.value("archived") ?? false,
		                                  uid: dict.value("uid") ?? "",
		                                  email: dict.value("email"),
		                                  phone: dict.value("phone"),
		                                  firstName: dict.value("firstName"),
		                                  middleName: dict.value("middleName"),
		                                  lastName: lastName,
		                                  city: dict.value("city"),
		                                  postalAddress: dict.value("postalAdress"),
		                                  postalCode: dict.value("postalCode"),
		                                  fax: dict.value("fax"),
		                                  icqNumber: dict.value("icqNumber"),
		                                  skype: dict.value("skype"),
		                                  fullName: dict.value("fullName"),
		                                  shortFio: dict.value("shortFio"),
		                                  cashier: nil,
		                                  permissions: MSUserPermissions.from(dict: dict.msValue("permissions"))))
	}
}

extension MSGroup : DictConvertable {
	public func dictionary(metaOnly: Bool) -> Dictionary<String, Any> {
        var dict = [String: Any]()
        
        dict["meta"] = meta.dictionary()
        
        guard !metaOnly else { return dict }
        
        dict["name"] = name
        // тут должны быть остальные поля объекта, если они понадобятся
        
        return dict
	}
	
	public static func from(dict: Dictionary<String, Any>) -> MSEntity<MSGroup>? {
		guard let meta = MSMeta.from(dict: dict["meta"] as? [String: Any] ?? [:], parent: dict) else {
			return nil
		}
		
		guard let name: String = dict.value("name"), name.characters.count > 0 else {
			return MSEntity.meta(meta)
		}
		
		return MSEntity.entity(MSGroup(meta: meta, name: name))
	}
}
