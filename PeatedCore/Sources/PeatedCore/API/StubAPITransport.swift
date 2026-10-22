#if DEBUG
    import Foundation
    import HTTPTypes
    import OpenAPIRuntime

    /// Answers generated-client calls from canned responses instead of the network.
    ///
    /// Responses are keyed by the generated operation id. Each operation hands out
    /// its responses in order and repeats the last one, so a test can script
    /// "fail once, then succeed". An operation with no responses answers 404 so
    /// the calling screen shows its normal failure state instead of hanging.
    ///
    /// Package tests build one directly. UI tests describe the same table in the
    /// launch environment and the app's debug harness installs it through
    /// `APIClient.launchTransport`.
    public final class StubAPITransport: ClientTransport, @unchecked Sendable {
        public struct Response: Sendable {
            public var status: Int
            public var body: Data
            public var contentType: String

            public init(status: Int = 200, body: Data = Data(), contentType: String = "application/json") {
                self.status = status
                self.body = body
                self.contentType = contentType
            }

            /// A response whose body is the given JSON text.
            public static func json(_ status: Int = 200, _ text: String) -> Response {
                Response(status: status, body: Data(text.utf8))
            }

            /// A 200 response whose body is the given server-sent events text.
            public static func eventStream(_ text: String) -> Response {
                Response(body: Data(text.utf8), contentType: "text/event-stream")
            }
        }

        private let lock = NSLock()
        private var queues: [String: [Response]]
        private var unansweredOperations: [String] = []

        public init(_ responses: [String: [Response]]) {
            queues = responses
        }

        /// Operation ids that were requested without a stubbed response.
        public var unstubbedOperations: [String] {
            lock.withLock { unansweredOperations }
        }

        public func send(
            _: HTTPRequest,
            body _: HTTPBody?,
            baseURL _: URL,
            operationID: String
        ) async throws -> (HTTPResponse, HTTPBody?) {
            let response = next(for: operationID)
                ?? .json(404, #"{"message":"No stubbed response for \#(operationID)"}"#)

            var head = HTTPResponse(status: .init(code: response.status))
            head.headerFields[.contentType] = response.contentType
            return (head, HTTPBody(response.body))
        }

        private func next(for operationID: String) -> Response? {
            lock.withLock {
                guard var queue = queues[operationID], let response = queue.first else {
                    unansweredOperations.append(operationID)
                    return nil
                }
                if queue.count > 1 {
                    queue.removeFirst()
                    queues[operationID] = queue
                }
                return response
            }
        }
    }
#endif
