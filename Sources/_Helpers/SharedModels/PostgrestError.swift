//
//  PostgrestError.swift
//
//
//  Created by Guilherme Souza on 27/01/24.
//

import Foundation

public struct PostgrestError: Error, Codable, Sendable {
  public let detail: String?
  public let hint: String?
  public let code: String?
  public let message: String

  public init(
    detail: String? = nil,
    hint: String? = nil,
    code: String? = nil,
    message: String
  ) {
    self.hint = hint
    self.detail = detail
    self.code = code
    self.message = message
  }
}

extension PostgrestError: LocalizedError {
  public var errorDescription: String? {
    message
  }
}

public struct HTTPError: Error, Sendable {
    public let response: HTTPURLResponse
    public let data: Data

    public var statusCode: Int {
        response.statusCode
    }

    public init(response: HTTPURLResponse, data: Data) {
        self.response = response
        self.data = data
    }
}

extension HTTPError: LocalizedError {
    public var errorDescription: String? {
        var message = "Status Code: \(self.statusCode)"
        if let body = String(data: data, encoding: .utf8) {
            message += " Body: \(body)"
        }
        return message
    }
}
