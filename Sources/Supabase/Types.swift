import _Helpers
import Auth
import Foundation
import PostgREST

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct SupabaseClientOptions: Sendable {
  public let db: DatabaseOptions
  public let auth: AuthOptions
  public let global: GlobalOptions

  public struct DatabaseOptions: Sendable {
    /// The Postgres schema which your tables belong to. Must be on the list of exposed schemas in
    /// Supabase.
    public let schema: String?

    /// The JSONEncoder to use when encoding database request objects.
    public let encoder: JSONEncoder

    /// The JSONDecoder to use when decoding database response objects.
    public let decoder: JSONDecoder

    public init(
      schema: String? = nil,
      encoder: JSONEncoder = PostgrestClient.Configuration.jsonEncoder,
      decoder: JSONDecoder = PostgrestClient.Configuration.jsonDecoder
    ) {
      self.schema = schema
      self.encoder = encoder
      self.decoder = decoder
    }
  }

  public struct AuthOptions: Sendable {
    /// A storage provider. Used to store the logged-in session.
    public let storage: any AuthLocalStorage

    /// Default URL to be used for redirect on the flows that requires it.
    public let redirectToURL: URL?

    /// OAuth flow to use - defaults to PKCE flow. PKCE is recommended for mobile and server-side
    /// applications.
    public let flowType: AuthFlowType

    /// The JSON encoder to use for encoding requests.
    public let encoder: JSONEncoder

    /// The JSON decoder to use for decoding responses.
    public let decoder: JSONDecoder

    public init(
      storage: any AuthLocalStorage,
      redirectToURL: URL? = nil,
      flowType: AuthFlowType = AuthClient.Configuration.defaultFlowType,
      encoder: JSONEncoder = AuthClient.Configuration.jsonEncoder,
      decoder: JSONDecoder = AuthClient.Configuration.jsonDecoder
    ) {
      self.storage = storage
      self.redirectToURL = redirectToURL
      self.flowType = flowType
      self.encoder = encoder
      self.decoder = decoder
    }
  }

  public struct GlobalOptions: Sendable {
    /// Optional headers for initializing the client, it will be passed down to all sub-clients.
    public let headers: [String: String]

    /// A session to use for making requests, defaults to `URLSession.shared`.
    public let session: URLSession

    /// The logger  to use across all Supabase sub-packages.
    public let logger: (any SupabaseLogger)?

    public init(
      headers: [String: String] = [:],
      session: URLSession = .shared,
      logger: (any SupabaseLogger)? = nil
    ) {
      self.headers = headers
      self.session = session
      self.logger = logger
    }
  }

  public init(
    db: DatabaseOptions = .init(),
    auth: AuthOptions,
    global: GlobalOptions = .init()
  ) {
    self.db = db
    self.auth = auth
    self.global = global
  }
}

extension SupabaseClientOptions {
  #if !os(Linux)
    public init(
      db: DatabaseOptions = .init(),
      global: GlobalOptions = .init()
    ) {
      self.db = db
      auth = .init()
      self.global = global
    }
  #endif
}

extension SupabaseClientOptions.AuthOptions {
  #if !os(Linux)
    public init(
      redirectToURL: URL? = nil,
      flowType: AuthFlowType = AuthClient.Configuration.defaultFlowType,
      encoder: JSONEncoder = AuthClient.Configuration.jsonEncoder,
      decoder: JSONDecoder = AuthClient.Configuration.jsonDecoder
    ) {
      self.init(
        storage: AuthClient.Configuration.defaultLocalStorage,
        redirectToURL: redirectToURL,
        flowType: flowType,
        encoder: encoder,
        decoder: decoder
      )
    }
  #endif
}
