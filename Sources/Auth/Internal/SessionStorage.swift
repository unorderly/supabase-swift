//
//  SessionStorage.swift
//
//
//  Created by Guilherme Souza on 24/10/23.
//

import _Helpers
import Foundation

import Logging

/// A locally stored ``Session``, it contains metadata such as `expirationDate`.
struct StoredSession: Codable {
  var session: Session
  var expirationDate: Date

  var isValid: Bool {
    expirationDate > Date().addingTimeInterval(60)
  }

  init(session: Session, expirationDate: Date? = nil) {
    self.session = session
    self.expirationDate = expirationDate
      ?? session.expiresAt.map(Date.init(timeIntervalSince1970:))
      ?? Date().addingTimeInterval(session.expiresIn)
  }
}

struct SessionStorage: Sendable {
    static let persistentLogger = Logging.Logger(label: Bundle.main.bundleIdentifier!)
  var getSession: @Sendable () throws -> StoredSession?
  var storeSession: @Sendable (_ session: StoredSession) throws -> Void
  var deleteSession: @Sendable () throws -> Void
}

extension SessionStorage {
  static let live: Self = {
    @Dependency(\.configuration.localStorage) var localStorage: any AuthLocalStorage

    return Self(
      getSession: {
        try localStorage.retrieve(key: "supabase.session").flatMap {
          try AuthClient.Configuration.jsonDecoder.decode(StoredSession.self, from: $0)
        }
      },
      storeSession: {
        try localStorage.store(
          key: "supabase.session",
          value: AuthClient.Configuration.jsonEncoder.encode($0)
        )
      },
      // When is delete session called?
      deleteSession: {
          persistentLogger.info("Deleting session")
          return try localStorage.remove(key: "supabase.session")
      }
    )
  }()
}
