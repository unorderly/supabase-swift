import _Helpers
import ConcurrencyExtras
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The builder class for creating and executing requests to a PostgREST server.
public class PostgrestBuilder: @unchecked Sendable {
  /// The configuration for the PostgREST client.
  let configuration: PostgrestClient.Configuration
  let http: HTTPClient

  struct MutableState {
    var request: Request

    /// The options for fetching data from the PostgREST server.
    var fetchOptions: FetchOptions
  }

  let mutableState: LockIsolated<MutableState>

  init(
    configuration: PostgrestClient.Configuration,
    request: Request
  ) {
    self.configuration = configuration
    http = HTTPClient(logger: configuration.logger, fetchHandler: configuration.fetch)

    mutableState = LockIsolated(
      MutableState(
        request: request,
        fetchOptions: FetchOptions()
      )
    )
  }

  convenience init(_ other: PostgrestBuilder) {
    self.init(
      configuration: other.configuration,
      request: other.mutableState.value.request
    )
  }

  /// Executes the request and returns a response of type Void.
  /// - Parameters:
  ///   - options: Options for querying Supabase.
  /// - Returns: A `PostgrestResponse<Void>` instance representing the response.
  @discardableResult
  public func execute(
    options: FetchOptions = FetchOptions()
  ) async throws -> PostgrestResponse<Void> {
    try await execute(options: options) { _ in () }
  }

  /// Executes the request and returns a response of the specified type.
  /// - Parameters:
  ///   - options: Options for querying Supabase.
  /// - Returns: A `PostgrestResponse<T>` instance representing the response.
  @discardableResult
  public func execute<T: Decodable>(
    options: FetchOptions = FetchOptions()
  ) async throws -> PostgrestResponse<T> {
    try await execute(options: options) { [configuration] data in
      do {
        return try configuration.decoder.decode(T.self, from: data)
      } catch {
        configuration.logger?.error("Fail to decode type '\(T.self) with error: \(error)")
        throw error
      }
    }
  }

  private func execute<T>(
    options: FetchOptions,
    decode: (Data) throws -> T
  ) async throws -> PostgrestResponse<T> {
    let request = mutableState.withValue {
      $0.fetchOptions = options

      if $0.fetchOptions.head {
        $0.request.method = .head
      }

      if let count = $0.fetchOptions.count {
        if let prefer = $0.request.headers["Prefer"] {
          $0.request.headers["Prefer"] = "\(prefer),count=\(count.rawValue)"
        } else {
          $0.request.headers["Prefer"] = "count=\(count.rawValue)"
        }
      }

      if $0.request.headers["Accept"] == nil {
        $0.request.headers["Accept"] = "application/json"
      }
      $0.request.headers["Content-Type"] = "application/json"

      if let schema = configuration.schema {
        if $0.request.method == .get || $0.request.method == .head {
          $0.request.headers["Accept-Profile"] = schema
        } else {
          $0.request.headers["Content-Profile"] = schema
        }
      }

      return $0.request
    }

    let response = try await http.fetch(request, baseURL: configuration.url)

    guard 200 ..< 300 ~= response.statusCode else {
        if let error = try? configuration.decoder.decode(PostgrestError.self, from: response.data) {
            throw error
        }
        
        throw HTTPError(response: response.response, data: response.data)
    }

    let value = try decode(response.data)
    return PostgrestResponse(data: response.data, response: response.response, value: value)
  }
}
