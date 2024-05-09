import _Helpers
import Foundation

struct SessionRefresher: Sendable {
  var refreshSession: @Sendable (_ refreshToken: String) async throws -> Session
}

actor SessionManager {
  private var task: Task<Session, any Error>?

  private var storage: any AuthLocalStorage {
    Current.configuration.localStorage
  }

  private var sessionRefresher: SessionRefresher {
    Current.sessionRefresher
  }

  func session(shouldValidateExpiration: Bool) async throws -> Session {

    guard let currentSession = try storage.getSession() else {
      throw AuthError.sessionNotFound
    }


    if currentSession.isValid || !shouldValidateExpiration {
      return currentSession.session
    }

    if let task {
      return try await task.value
    }
    task = Task {
      defer { task = nil }

      let session = try await sessionRefresher.refreshSession(currentSession.session.refreshToken)
      try update(session)
      return session
    }

    return try await task!.value
  }

  func update(_ session: Session) throws {
      logger?.debug("Updating session")
    try storage.storeSession(StoredSession(session: session))
  }

  func remove() {
    try? storage.deleteSession()
  }
}
