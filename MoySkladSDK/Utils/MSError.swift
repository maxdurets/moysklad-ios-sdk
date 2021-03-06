//
//  MSError.swift
//  MoySkladSDK
//
//  Created by Anton Efimenko on 20.04.17.
//  Copyright © 2017 Andrey Parshakov. All rights reserved.
//

import Foundation

public enum MSError: Error {
    case httpRequestFailure(Error)
    case errors([MSErrorStruct])
    case unknown
}

public struct MSErrorStruct: Error {
    public let error: String
    public let message: String?
    public let parameter: String?
    public let code: Int?
    public let httpStatusCode: Int
    
    public init(error: String, message: String?, parameter: String?, code: Int?, httpStatusCode: Int) {
        self.error = error
        self.message = message
        self.parameter = parameter
        self.code = code
        self.httpStatusCode = httpStatusCode
    }
}

public struct MSErrorCode {
    public static let generic = 1_000_000
    public static let unauthorized = 1056
    public static let accessDenied = 1016
    public static let preconditionFailed = 33002
}

extension MSError {
    static func preconditionFailedError() -> MSError {
        return MSError.errors([MSErrorStruct.init(error: LocalizedStrings.preconditionFailedError.value,
                                                  message: nil,
                                                  parameter: nil,
                                                  code: MSErrorCode.preconditionFailed,
                                                  httpStatusCode: 412)])
    }
    
    static func unauthorizedError() -> MSError {
        return MSError.errors([MSErrorStruct.init(error: LocalizedStrings.unauthorizedError.value,
                                                  message: nil,
                                                  parameter: nil,
                                                  code: MSErrorCode.unauthorized,
                                                  httpStatusCode: 401)])
    }
    
    public static func genericError(errorText: String, parameter: String? = nil) -> MSError {
        return MSError.errors([MSErrorStruct.init(error: errorText,
                                                  message: nil,
                                                  parameter: nil,
                                                  code: MSErrorCode.generic,
                                                  httpStatusCode: -1)])
    }
}
