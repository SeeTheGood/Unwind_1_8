import Foundation
import Combine

class UnwindAPI {
    private let baseURL = "https://api.openai.com/v1"
    private let apiKey = "sk-proj-2lzYP1IhM1Y04jojYbialeiyXKFJPxHVQHf7jE1LQeRKxvWdHh2kV0z6PutBAiiKrx14FNksjlT3BlbkFJXJ8-ft_qWRLR-Fhv7xeJ1FSGEpw3iv-T-w16uKeRMi7g89-uVrqZouxxuSug6skvrQjUkDmSY" // Replace with your actual API key
    private let assistantId = "asst_2yAxYpU77d6m3pv0dBtxwKRW" // Replace with your actual Assistant ID

    private var cancellables = Set<AnyCancellable>()
      
    // MARK: - Poll until completion
    func pollUntilCompletion(threadId: String, initialInterval: TimeInterval = 20.0, maxRetries: Int = 15, maxQueuedRetries: Int = 5, completion: @escaping (String?) -> Void) {
        var retryCount = 0               // Track the total number of polling attempts
        var queuedRetryCount = 0         // Track the number of consecutive "queued" statuses
        var currentInterval = initialInterval  // Start with the initial interval and increase as needed
        
        Timer.publish(every: currentInterval, on: .main, in: .common)
            .autoconnect()
            .flatMap { _ -> AnyPublisher<String, Error> in
                retryCount += 1
                if retryCount > maxRetries {
                    return Fail(error: NSError(domain: "PollingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Polling exceeded maximum retries."])).eraseToAnyPublisher()
                }
                return self.pollRunStatusPublisher(threadId: threadId)
            }
            .sink(receiveCompletion: { completionResult in
                if case .failure(let error) = completionResult {
                    print("Polling failed with error: \(error)")
                    completion("Error: \(error.localizedDescription)")
                }
            }, receiveValue: { status in
                print("Current Status: \(status)")

                if status == "completed" {
                    // Stop polling and retrieve the final data
                    self.cancellables.removeAll()
                    self.retrieveFinalData(threadId: threadId, completion: completion)
                    
                } else if status == "queued" {
                    // Increment queued count and check if it exceeds maxQueuedRetries
                    queuedRetryCount += 1
                    if queuedRetryCount >= maxQueuedRetries {
                        print("Polling stopped as status remained 'queued' for too long.")
                        self.cancellables.removeAll()
                        completion("The request has been queued for too long. Please try again later.")
                        
                    } else {
                        // Increase the interval for the next polling attempt (backoff)
                        currentInterval = min(currentInterval * 2, 60.0) // Cap the interval at 60 seconds
                        print("Status is still queued. Backing off and continuing to poll with a new interval of \(currentInterval) seconds.")
                    }
                    
                } else if status == "running" {
                    // Reset queuedRetryCount if status progresses to "running"
                    queuedRetryCount = 0
                    print("Status is running. Continuing to poll...")

                } else {
                    // Stop polling on any unexpected status
                    self.cancellables.removeAll()
                    print("Unexpected status or error received: \(status)")
                    completion("Unexpected status or error received: \(status)")
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Create a new conversation thread
      func createThreadPublisher() -> AnyPublisher<String, Error> {
          let request = buildRequest(endpoint: "/threads", method: "POST")
          
          return URLSession.shared.dataTaskPublisher(for: request)
              .tryMap { data, response in
                  print("Raw Thread Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                  
                  if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                     let error = jsonObject["error"] as? [String: Any],
                     let errorMessage = error["message"] as? String {
                      throw NSError(domain: "OpenAIAPIError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                  }
                  
                  let threadResponse = try JSONDecoder().decode(ThreadResponse.self, from: data)
                  return threadResponse.id
              }
              .mapError { $0 as Error }
              .eraseToAnyPublisher()
      }

      // MARK: - Send a message in a thread
      func sendMessagePublisher(threadId: String, content: String, role: String = "user") -> AnyPublisher<Void, Error> {
          let requestBody = MessageRequest(role: role, content: content)
          guard let bodyData = encodeToJSON(requestBody) else {
              return Fail(error: NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message request"]))
                  .eraseToAnyPublisher()
          }
          
          let request = buildRequest(endpoint: "/threads/\(threadId)/messages", method: "POST", body: bodyData)
          
          return URLSession.shared.dataTaskPublisher(for: request)
              .tryMap { data, response in
                  print("Raw Send Message Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                  
                  if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                     let error = jsonObject["error"] as? [String: Any],
                     let errorMessage = error["message"] as? String {
                      throw NSError(domain: "OpenAIAPIError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                  }
                  
                  return ()
              }
              .mapError { $0 as Error }
              .eraseToAnyPublisher()
      }

      // Helper function to retrieve final data when status is "completed"
      private func retrieveFinalData(threadId: String, completion: @escaping (String?) -> Void) {
          let request = buildRequest(endpoint: "/threads/\(threadId)/results", method: "GET")

          URLSession.shared.dataTaskPublisher(for: request)
              .tryMap { data, response in
                  print("Final Data Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                  
                  let finalResponse = try JSONDecoder().decode(FinalDataResponse.self, from: data)
                  return finalResponse.content
              }
              .sink(receiveCompletion: { completionResult in
                  if case .failure(let error) = completionResult {
                      print("Failed to retrieve final data with error: \(error)")
                      completion(nil)
                  }
              }, receiveValue: { (finalContent: String) in
                  print("Final Content: \(finalContent)")
                  completion(finalContent)
              })
              .store(in: &cancellables)
      }

      // MARK: - Poll for the assistant's response in a thread
      func pollRunStatusPublisher(threadId: String) -> AnyPublisher<String, Error> {
          let requestBody = RunRequest(assistant_id: assistantId)
          guard let bodyData = encodeToJSON(requestBody) else {
              return Fail(error: NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode run request"]))
                  .eraseToAnyPublisher()
          }
          
          let request = buildRequest(endpoint: "/threads/\(threadId)/runs", method: "POST", body: bodyData)
          
          return URLSession.shared.dataTaskPublisher(for: request)
              .tryMap { data, response in
                  print("Raw Run Status Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                  
                  if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                     let error = jsonObject["error"] as? [String: Any],
                     let errorMessage = error["message"] as? String {
                      throw NSError(domain: "OpenAIAPIError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                  }
                  
                  let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
                  return runResponse.status
              }
              .mapError { $0 as Error }
              .eraseToAnyPublisher()
      }
      
      // MARK: - Helper: Build URLRequest with Authorization and Required Headers
      private func buildRequest(endpoint: String, method: String, body: Data? = nil) -> URLRequest {
          let url = URL(string: "\(baseURL)\(endpoint)")!
          var request = URLRequest(url: url)
          request.httpMethod = method
          request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
          request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
          if let body = body {
              request.httpBody = body
              request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          }
          return request
      }

      private func encodeToJSON<T: Encodable>(_ object: T) -> Data? {
          do {
              return try JSONEncoder().encode(object)
          } catch {
              print("Failed to encode object to JSON: \(error)")
              return nil
          }
      }
  }

  // MARK: - Helper Structs for JSON Decoding and Encoding

  struct ThreadResponse: Codable {
      let id: String
  }

  struct MessageRequest: Codable {
      let role: String
      let content: String
  }

  struct RunRequest: Codable {
      let assistant_id: String
  }

  struct RunResponse: Codable {
      let status: String
  }

  struct FinalDataResponse: Codable {
      let content: String
  }
