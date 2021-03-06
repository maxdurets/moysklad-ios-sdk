//
//  Extensions.swift
//  MoyskladNew
//
//  Created by Anton Efimenko on 11.11.16.
//  Copyright © 2016 Andrey Parshakov. All rights reserved.
//

import Foundation

func newDocumentUrl(type: MSObjectType) -> MSApiRequest? {
    switch type {
    case MSObjectType.customerorder: return MSApiRequest.customerOrderNew
    case MSObjectType.demand: return MSApiRequest.demandNew
    case MSObjectType.invoiceout: return MSApiRequest.invoiceOutNew
    default: return nil
    }
}

func createdDocumentError(type: MSObjectType) -> MSError {
    switch type {
    case MSObjectType.customerorder: return MSError.genericError(errorText: LocalizedStrings.incorrectCustomerOrderTemplateResponse.value)
    case MSObjectType.demand: return MSError.genericError(errorText: LocalizedStrings.incorrectDemandTemplateResponse.value)
    case MSObjectType.invoiceout: return MSError.genericError(errorText: LocalizedStrings.incorrectInvoiceOutTemplateResponse.value)
    default: return MSError.genericError(errorText: LocalizedStrings.genericDeserializationError.value)
    }
}

func emptyMeta(type: MSObjectType) -> MSMeta {
    return MSMeta(name: "", href: "", type: type)
}

public extension MSMeta {
    func dictionaryForTemplate() -> Dictionary<String, Any> {
        return ["template": ["meta": ["href":href, "mediaType":mediaType, "type":type.rawValue]]]
    }
}

func dictToDocFrom(type: MSObjectType, dict: [String: AnyObject]) -> MSGeneralDocument? {
    switch type {
    case .customerorder:
        return MSCustomerOrder.from(dict: dict)?.value()
    case .demand:
        return MSDemand.from(dict: dict)?.value()
    case .invoiceout:
        return MSInvoice.from(dict: dict)?.value()
    default: return nil
    }
}

func emptyDocumentPositionMeta(type: MSObjectType) -> MSMeta {
    switch type {
    case MSObjectType.customerorder: return MSMeta(name: "", href: "", type: .customerorderposition)
    case MSObjectType.demand: return MSMeta(name: "", href: "", type: .demandposition)
    case MSObjectType.invoiceout: return MSMeta(name: "", href: "", type: .invoiceposition)
    default: return MSMeta(name: "", href: "", type: .customerorderposition)
    }
}

extension Array {
    func toDictionary(_ key: (Element) -> String) -> [String: Element] {
        var dict = [String: Element]()
        forEach { dict[key($0)] = $0 }
        return dict
    }
}

extension Dictionary {
    subscript(jsonKey key: Key) -> [String:Any]? {
        get {
            return self[key] as? [String:Any]
        }
        set {
            self[key] = newValue as? Value
        }
    }
    
    subscript(jsonArrayKey key: Key) -> [Any]? {
        get {
            return self[key] as? [Any]
        }
        set {
            self[key] = newValue as? Value
        }
    }
    
    subscript(jsonString key: Key) -> String? {
        return self[key] as? String
    }
}

extension MSAgent: MSRequestEntity {
    public func requestUrl() -> MSApiRequest? {
        if meta.type == .counterparty {
            return MSApiRequest.counterparty
        } else {
            return MSApiRequest.organization
        }
    }
    
    public func deserializationError() -> MSError {
        switch meta.type {
        case MSObjectType.organization: return MSError.genericError(errorText: LocalizedStrings.incorrectOrganizationResponse.value)
        case MSObjectType.counterparty: return MSError.genericError(errorText: LocalizedStrings.incorrectCounterpartyResponse.value)
        default: return MSError.genericError(errorText: LocalizedStrings.genericDeserializationError.value)
        }
    }
}

extension MSGeneralDocument {    
    public func requestUrl() -> MSApiRequest? {
        switch meta.type {
        case MSObjectType.customerorder: return .customerorder
        case MSObjectType.demand: return .demand
        case MSObjectType.invoiceout: return .invoiceOut
        default: return nil
        }
    }
    
    public func deserializationError() -> MSError {
        switch meta.type {
        case MSObjectType.customerorder: return MSError.genericError(errorText: LocalizedStrings.incorrectCustomerOrdersResponse.value)
        case MSObjectType.demand: return MSError.genericError(errorText: LocalizedStrings.incorrectDemandsResponse.value)
        case MSObjectType.invoiceout: return MSError.genericError(errorText: LocalizedStrings.incorrectCustomerOrdersResponse.value)
        default: return MSError.genericError(errorText: LocalizedStrings.genericDeserializationError.value)
        }
    }
    
    func templateBody() -> [String: Any]? {
        switch self {
        case let o as MSCustomerOrder: return ["customerOrder": o.dictionary(metaOnly: true)]
        case let o as MSDemand: return ["demands": [o.dictionary(metaOnly: true)]]
        case let o as MSInvoice: return ["invoicesOut": [o.dictionary(metaOnly: true)]]
        default: return nil
        }
    }
}

extension UserDefaults {
    var moySkladHost: String {
        get {
            guard let host = string(forKey: "moySkladHost") else { return "online.moysklad.ru" }
            return host
        }
        set {
            set(newValue, forKey: "moySkladHost")
        }
    }
}

public protocol OptionalType {
    associatedtype Wrapped
    func map<U>(_ f: (Wrapped) throws -> U) rethrows -> U?
}

extension Optional: OptionalType {}

public extension Sequence where Iterator.Element: OptionalType {
    public func removeNils() -> [Iterator.Element.Wrapped] {
        var result: [Iterator.Element.Wrapped] = []
        for element in self {
            if let element = element.map({ $0 }) {
                result.append(element)
            }
        }
        return result
    }
}

public extension Dictionary {
    public mutating func merge<S>(_ other: S)
        where S: Sequence, S.Iterator.Element == (key: Key, value: Value) {
            for (k, v) in other {
                self[k] = v
            }
    }
    
    public func merged<S>(_ other: S) -> Dictionary<Key, Value>
        where S: Sequence, S.Iterator.Element == (key: Key, value: Value) {
            var new = self
            new.merge(other)
            return new
    }
}

public extension Date {
    public func toLongDate() -> String {
        return Date.msDateFormatter.string(from: self)
    }
    
    public func beginningOfDay() -> Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    
    public func toShortDate() -> String {
        return Date.msShortDateFormatter.string(from: self)
    }
    
    public func toShortTime() -> String {
        return Date.msHourAndMinuteFormatter.string(from: self)
    }
    
    public static var msShortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    public static var msHourAndMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    public static var msDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        return formatter
    }()
    
    public static func fromMSDate(_ value: String) -> Date? {
        guard value.characters.count > 0 else {
            return nil
        }
        return Date.msDateFormatter.date(from: value)
    }
    
    static var msLongDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    /// Date format: dd MMMM yyyy HH:mm
    func toMSLongDateTime() -> String {
        return Date.msLongDateTimeFormatter.string(from: self)
    }
    
    static var msCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }()
    
    func startOfWeek() -> Date {
        let date = Date.msCalendar.date(from: Date.msCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        let dslTimeOffset = TimeZone(identifier: "Europe/Moscow")!.daylightSavingTimeOffset(for: date)
        return date.addingTimeInterval(dslTimeOffset)
    }
    
    func endOfWeek() -> Date {
        return Date.msCalendar.date(byAdding: .second, value: 604799, to: self.startOfWeek())!
    }
    
    func startOfMonth() -> Date {
        let components = Date.msCalendar.dateComponents([.year, .month], from: self)
        return Date.msCalendar.date(from: components)!
    }
    
    func endOfMonth() -> Date {
        var comps2 = DateComponents()
        comps2.month = 1
        comps2.second = -1
        return Date.msCalendar.date(byAdding: comps2, to: startOfMonth())!
    }
    
    func endOfDay() -> Date {
        return Date.msCalendar.date(bySettingHour: 23, minute: 59, second: 59, of: self)!
    }
}

public extension NSDecimalNumber {
    public func toMoneyString() -> String {
        return NSDecimalNumber.msMoneyNumberFormatter.string(from: self) ?? "0"
    }
    
    @nonobjc public static var msMoneyNumberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.decimalSeparator = ","
        nf.groupingSeparator = " "
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        return nf
    }()
}

public extension Double {
    public func toMSDoubleString(showPositiveSign: Bool = false) -> String {
        guard showPositiveSign else {
            return Double.msDoubleFormatter.string(from: NSNumber(floatLiteral: self)) ?? "0"
        }
        
        return Double.msDoubleFormatterWithPositiveSign.string(from: NSNumber(floatLiteral: self)) ?? "0"
    }
    
    @nonobjc public static var msDoubleFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.decimalSeparator = ","
        nf.groupingSeparator = " "
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 4
        return nf
    }()
    
    @nonobjc public static var msDoubleFormatterWithPositiveSign: NumberFormatter = {
        let nf = NumberFormatter()
        nf.decimalSeparator = ","
        nf.groupingSeparator = " "
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 4
        nf.positivePrefix = nf.plusSign
        return nf
    }()
}
