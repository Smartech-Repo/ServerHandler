//
//  APIHandler.swift
//
//
//  Created by Ahsan Ateeq on 19/02/2024.
//

import Foundation

public class APIHandler<resultJSONType:CodableJsonProtocol> {
    
    public typealias apiResults = (jsonObj: resultJSONType?, requestURL: URL?)
    public typealias apiResultsCompletion = Result<(jsonObj: resultJSONType?, requestURL: URL?), APIErrors>
    
    /// fetch Asynchronous contents of API
    /// - Parameter url_builder: url builder for the API, use initialize one of the APIs_urlBuilder structure types and pass it here
    /// - Parameter completionHandler: results of fetched API, and error of type: APIErrors
    internal class func fetchAPI<urlBuilder: APIURLBuilderProtocol>(forURL url_builder: urlBuilder,
                                                           inSession session: URLSessionProtocol = URLSession.init(configuration: .default)) async throws -> apiResults
    {

        guard url_builder.JSONType is resultJSONType.Type else {
            throw APIErrors.mismatchType
        }
        
        guard let jsonURL = url_builder.buildURL(), let jsonURLRequest = url_builder.buildURLRequest() else {
            throw APIErrors.urlError
        }

        do {
            if #available(iOS 15.0, *) {
                let (data, _) = try await session._data(for: jsonURLRequest, delegate: nil)
                print(String(data:data, encoding: .utf8)!)
                return try await parse(data: data, jsonURL: jsonURL)
            } else {
                return try await withCheckedThrowingContinuation { continuation in
                    let task = session._dataTask(with: jsonURLRequest) { data, response, error in
                        
                        guard let data = data else {
                            print("data is nil: \(jsonURL)")
                            if let err = error {
                                print(err)
                            }

                            if let respnse = response {
                                print("response: ", respnse)
                            }

                            continuation.resume(with: .failure(APIErrors.networkUnavailable))
                            return
                        }

                        Task {
                            let parseResult =  try await parse(data: data, jsonURL: jsonURL)
                            continuation.resume(returning: parseResult)
                        }
                    }
                    
                    task.resume()
                }
            }
            
        } catch let error {
            print("data is nil: \(jsonURL)")
            print(error)
            throw APIErrors.networkUnavailable
        }
    }
    
    
    
    internal class func fetchAPI<urlBuilder: APIURLBuilderProtocol>(forURL url_builder: urlBuilder,
                                                           inSession session: URLSessionProtocol = URLSession.init(configuration: .default),
                                                           _ completion: @escaping ((apiResultsCompletion) -> Void))
    {

        guard url_builder.JSONType is resultJSONType.Type else {
            completion(.failure(APIErrors.mismatchType))
            return
        }
        
        guard let jsonURL = url_builder.buildURL(), let jsonURLRequest = url_builder.buildURLRequest() else {
            completion(.failure(APIErrors.urlError))
            return
        }

        let task = session._dataTask(with: jsonURLRequest) { data, response, error in
            
            guard let data = data else {
                print("data is nil: \(jsonURL)")
                if let err = error {
                    print(err)
                }

                if let respnse = response {
                    print("response: ", respnse)
                }

                completion(.failure(APIErrors.networkUnavailable))
                return
            }

            Task {
                let parseResult =  try await parse(data: data, jsonURL: jsonURL)
                completion(.success(parseResult))
            }
        }
        
        task.resume()
    }
    
    internal class func parse(data: Data, jsonURL:  URL?) async throws -> apiResults {
        
        do {
            
            let decoder = JSONDecoder()
            
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "YYYY-MM-DD HH:mm:ss"
            dateFormat.locale = Locale(identifier: "en_US_POSIX")
            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .formatted(dateFormat)
            let ItemJSON = try decoder.decode(resultJSONType.self, from: data)
            
            return (jsonObj: ItemJSON, requestURL: jsonURL)
            
            
        } catch let DecodingError.keyNotFound(key, keysContext) {
            
            print("error decoding key: \(key) context: \(keysContext) \n\n url: \(jsonURL?.absoluteString ?? "") \n\n")
            throw APIErrors.notFound
            
        } catch let DecodingError.valueNotFound(value, valuesContext) {
            
            print("error decoding value: \(value) \(valuesContext) \n\n url: \(jsonURL?.absoluteString ?? "") \n\n")
            throw APIErrors.notFound
            
        } catch let DecodingError.typeMismatch(type, context) {
            
            print("type problem: \(type), \(context)")
            throw APIErrors.mismatchType
            
            
        } catch let DecodingError.dataCorrupted(context) {
            
            print("data corrupted \(context) , url:\(String(describing: jsonURL)), data: \(String(data: data, encoding: .utf8) ?? "")")
            throw APIErrors.decodingError
            
        } catch {
            
            throw APIErrors.networkUnavailable
            
        }
        
    }
    
}

public protocol URLSessionProtocol {
        
    func _dataTask(with urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
    @available(iOS 15.0, *)
    func _data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)

}

public protocol URLSessionDataTaskProtocol {
    
    func resume()
    
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {
    
}

extension URLSession : URLSessionProtocol {
 
    public func _dataTask(with urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return self.dataTask(with: urlRequest, completionHandler: completionHandler) as URLSessionDataTask
    }
    
    @available(iOS 15.0, *)
    public func _data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {

        do {
            let retVal = try await self.data(for: request, delegate: delegate)
            return retVal
            
        } catch let error {
            throw error
        }
    }
}
