# ServerHandler
This library is used to easily send server requests.

## Installation
To install use swift package manager
URL:
``

## Usage

- First Import Library
`import ServerHandler`

- Setting initial configuration
Setting up intial configuration for some values to be reused easily.

```swift
ServerHandlerConstants.shared.configure(baseURL: "", // Provide base url for server
                                        authorizationBearerToken: "", // Optional: Header: Authorization : Bearer\(key). Can be assigned later.
                                        headers: [String : String]) // Optional: Extra headers to be assigned with api. Can be assigned later.
                                        
/// Optional: Func to assign bearer authorization at later stage, probably after login
ServerHandlerConstants.shared.setBearerAuthorizationToken(token: "")

/// Optional: Func to assign headers at later stage
ServerHandlerConstants.shared.setHeaders([String : String])
```

- Creating JSON response struct
To create struct for json response, the struct must conform to `CodableJsonProtocol`.

```swift
struct JSONResponse: CodableJsonProtocol {
    let status: Bool
    let code: Int
    let message: String
}
```

- Creating URLBuilder
The url builder is created for each request along with JSON response struct. To create a url builder, create a struct and conform it `APIURLBuilderProtocol`

```swift
struct ExampleURLBuilder: APIURLBuilderProtocol {
    typealias TJSON = JSONResponse /// Provide response type for JSON
    
    /// Provide path components with reference to base url, provide each path component seperately
    /// e.g. If complete url is 'https://www.example.com/path/path_to_resource',
    /// 'https://www.example.com' can be assigned as baseURL in initial configuration, then
    /// provide 'path', 'path_to_resource' as pathComponents seperately as individual strings in the array
    var pathComponents: [String] {
        return [] /// Provide each path component
    }
    
    /// Provide each parameter in an array
    /// e.g. URLQueryItem(name: "", value: "")
    var queryStrings: [URLQueryItem] {
        return [] // Return empty array if none required
    }
}
``` 
The above implementation contains the minimum required properties in order for `APIURLBuilderProtocol` to work.

The `APIURLBuilderProtocol` also contains some optional properties for which the implementation can be provided in each URLBuilder

```swift
public protocol APIURLBuilderProtocol {

    var baseURL: URL? {get} /// can be used to provide seperate baseURL for current implementation. Default is `ServerHandlerConstants.baseURL`
    
    var httpMethod: HTTPMethods {get} /// default is .get, available values .get, .post, .put, .delete
    
    var authorizationToken: String? {get} /// can be used to provide bearer authorization token for current implementation. Default is `ServerHandlerConstants.authorizationToken`
    
    var headers: [String: String]? {get} /// can be used to provide headers for current implementation. Default is `ServerHandlerConstants.customHeaders`
    
    func buildURL() -> URL? /// can be used to provide URL for current implementation
    
    func buildURLRequest() -> URLRequest? /// can be used to provide URLRequest for current implementation
    
}
```

- Last step: Use URLBuilder to send server request and receive response
There are two ways to send server requests

1- Using `async await`.

```swift
Task {
    let builder = ExampleURLBuilder()
                
    do {
            let result = try await builder.fetch() /// calling fetch() function on builder sends the request
            result.jsonObj /// get the response from jsonObj, type will be TJSON provided in URLBuilder
            result.requestURL /// get the request url
        } catch let error {
            (error as? APIErrors)?.localizedDescription /// error is type of APIErrors
        }
}
```

2- Using Closure callback.

```swift
let builder = ExampleURLBuilder()
            
builder.fetch { response in
    switch response {
    case .success(let result):
        result.jsonObj /// get the response from jsonObj, type will be TJSON provided in URLBuilder
        result.requestURL /// get the request url
        
    case .failure(let error):
        error.localizedDescription /// error is type of APIErrors
    }
}
```

## Samples

- APIErrors
```swift
public enum APIErrors: Error {
    case notFound /// incase of decoding if any key or value not found
    
    case urlError /// incase the url is not a valid url
    
    case networkUnavailable /// incase the server request sending failed
    
    case mismatchType /// incase the json response type provided doesnot match with json received from server
    
    case decodingError /// incase of general decoding error
}
```
