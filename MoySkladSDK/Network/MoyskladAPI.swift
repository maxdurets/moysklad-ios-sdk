//
//  MoyskladAPI.swift
//  MoyskladNew
//
//  Created by Andrey Parshakov on 13.10.16.
//  Copyright © 2016 Andrey Parshakov. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

public protocol UrlParameter {
    var urlParameters: [String: String] { get }
}

extension MSOffset : UrlParameter {
    public var urlParameters: [String : String] {
        return httpParameters
    }
}

public struct GenericUrlParameter : UrlParameter {
    public let name: String
    public let value: String
    public var urlParameters: [String : String] { return [name: value] }
}

/**
 Scope used for filtering assortment. 
 This parameter is useful only for filtering by product/varinant. Request will always return other entities (Bundles, Services etc)
*/
public enum AssortmentScope : String, UrlParameter {
    /// Request will return product and product variants
    case variant
    /// Request will return only product (product variandts will be skipped)
    case product
    
    public var urlParameters: [String: String] {
        switch self {
        case .variant: return ["scope": self.rawValue]
        case .product: return ["scope": self.rawValue]
        }
    }
}

extension Request {
    public func debugLog() -> Self {
        debugPrint(self)
        return self
    }
}

/**
 This object represents credentials for Basic authentication
*/
public struct Auth {
    public let username : String
    public let password : String
    
	public var header: [String: String] {
        let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public enum MSApiRequest : String {
    static var baseUrl: URL {
        guard let url = URL(string: "https://\(UserDefaults.standard.moySkladHost)/api/remap/1.1") else {
            return URL(string: "https://online.moysklad.ru/api/remap/1.1")!
        }
        return url
    }
	
    case register = "register"
	case contextEmployee = "context/employee"
	case companySettings = "entity/companysettings"
	case organization = "entity/organization"
	case counterparty = "entity/counterparty"
    case counterpartymetadata = "entity/counterparty/metadata"
	case customerorder = "entity/customerorder"
    case customerOrderNew = "entity/customerorder/new"
    case customerordermetadata = "entity/customerorder/metadata"
	case store = "entity/store"
	case contract = "entity/contract"
	case assortment = "entity/assortment"
    case demand = "entity/demand"
    case demandNew = "entity/demand/new"
    case demandmetadata = "entity/demand/metadata"
    case invoiceOut = "entity/invoiceOut"
    case invoiceOutNew = "entity/invoiceOut/new"
    case invoiceOutMetadata = "entity/invoiceOut/metadata"
    case dashboardDay = "report/dashboard/day"
    case dashboardWeek = "report/dashboard/week"
    case dashboardMonth = "report/dashboard/month"
    case stockAll = "report/stock/all"
    case stockByStore = "report/stock/bystore"
    case stockByOperation = "report/stock/byoperation"
    case salesByProduct = "report/sales/byproduct"
    case productFolder = "/entity/productfolder"
    case product = "/entity/product"
    case bundle = "/entity/bundle"
    case variant = "/entity/variant"
    case service = "/entity/service"
    case project = "/entity/project"
    case group = "/entity/group"
    case currency = "/entity/currency"
    case employee = "/entity/employee"
    case customEntity = "/entity/customentity"
    case entity = "/entity"
}

extension MSApiRequest {
	public var path : String {
		return self.rawValue
	}
	
	public var url: URL {
		return MSApiRequest.baseUrl.appendingPathComponent(path)
	}
}

enum HttpRequestContentType : String {
	case json
    case formUrlencoded
}

final class HttpClient {
    //static let responseQueue = DispatchQueue(label: "HttpClient.ResponseQueue", qos: .utility)
    
    static let manager: Alamofire.SessionManager = {
		
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "online.moysklad.ru": .disableEvaluation
        ]
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        let result = Alamofire.SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
        
        result.delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = URLSession.AuthChallengeDisposition.useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .cancelAuthenticationChallenge
                } else {
                    credential = result.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                    
                    if credential != nil {
                        disposition = .useCredential
                    }
                }
            }
            return (disposition, credential)
        }
        
        return result
    }()
    
    static func resultCreateFromData(_ url: URL) -> Observable<URL?> {
        return Observable.create { observer -> Disposable in
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent("localFile.pdf")
                return (fileURL, [.removePreviousFile])
            }
            
            #if DEBUG
                let request = Alamofire.download(url, to: destination).debugLog()
            #else
                let request = Alamofire.download(url, to: destination)
            #endif
            
            request.response { response in
                if let error = response.error {
                    switch error {
                    case let p as URLError where p.code == URLError.notConnectedToInternet:
                        observer.onError(MSError.genericError(errorText: LocalizedStrings.notOnline.value))
                    default: observer.onError(MSError.httpRequestFailure(error))
                    }
                    return
                }
                
                if response.response?.statusCode == 401 {
                    observer.onError(MSError.unauthorizedError())
                }
                
                guard let data = response.destinationURL else {
                    observer.onError(MSError.unknown)
                    return
                }
                
                observer.onNext(data)
                observer.onCompleted()
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    static func resultCreateFromHeader(_ router: HttpRouter) -> Observable<Dictionary<String,String>?> {
        return Observable.create { observer -> Disposable in
            manager.delegate.taskWillPerformHTTPRedirection = { (URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest? in
                return nil
            }
            #if DEBUG
                let request = manager.request(router).debugLog()
            #else
                let request = manager.request(router)
            #endif
            
            request.response { response in
                if let error = response.error {
                    switch error {
                    case let p as URLError where p.code == URLError.notConnectedToInternet:
                        observer.onError(MSError.genericError(errorText: LocalizedStrings.notOnline.value))
                    default: observer.onError(MSError.httpRequestFailure(error))
                    }
                    return
                }
                
                if response.response?.statusCode == 401 {
                    observer.onError(MSError.unauthorizedError())
                    return
                }
                
                if response.response?.statusCode == 412 {
                    observer.onError(MSError.preconditionFailedError())
                    return
                }
                
                guard let headers = response.response?.allHeaderFields else {
                    observer.onError(MSError.unknown)
                    return

                }
                
                guard let convertHeaders = headers as? HTTPHeaders else {
                    observer.onError(MSError.unknown)
                    return
                }
                
                observer.onNext(convertHeaders)
                observer.onCompleted()
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    static func resultCreate(_ router : HttpRouter) -> Observable<Dictionary<String,AnyObject>?> {
        return Observable.create { observer -> Disposable in
            #if DEBUG
                let request = manager.request(router).debugLog()
            #else
                let request = manager.request(router)
            #endif
            request.responseData { dataResponse in
                if let error = dataResponse.result.error {
                    switch error {
                    case let p as URLError where p.code == URLError.notConnectedToInternet:
                        observer.onError(MSError.genericError(errorText: LocalizedStrings.notOnline.value))
                    default: observer.onError(MSError.httpRequestFailure(error))
                    }
                    
                    return
                }
				
				// проверяем вернулись ли данные
				guard let data = dataResponse.result.value, !data.isEmpty else {
					guard dataResponse.response?.statusCode != 200 else {
						// если статус 200 и данные не вернулись, просто возвращаем nil и завершаем работу
						observer.onNext(nil); observer.onCompleted(); return
					}
					// если же данные не вернулись и код ответа не 200, то возвращаем неизвестную ошибку
					observer.onError(MSError.unknown)
					return
				}
				
				guard let responseDict = (try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String,AnyObject>) ?? nil else {
					observer.onError(MSError.unknown)
					return
				}
				
				guard dataResponse.response?.statusCode == 200 else {
                    observer.onError(convertToError(httpCode: dataResponse.response?.statusCode ?? -1, errorDict: responseDict));
                    return
                }
				
				observer.onNext(responseDict)
				observer.onCompleted()
			}
						
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    static func convertToError(httpCode: Int, errorDict: Dictionary<String, AnyObject>) -> MSError {
        guard let errors = errorDict["errors"] as? [Any] else { return MSError.unknown }
        var convertedErrors: [MSErrorStruct] = []
        for error in errors {
            guard let item = error as? Dictionary<String, Any> else {
                return MSError.unknown
            }
            convertedErrors.append(MSErrorStruct.init(error: item["error"] as? String ?? "",
                                                      message: item["error_message"] as? String,
                                                      parameter: item["parameter"] as? String,
                                                      code: item["code"] as? Int,
                                                      httpStatusCode: httpCode))
        }
        return MSError.errors(convertedErrors)
    }
}
