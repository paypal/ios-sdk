import Foundation

class MockURLSession: URLSession {

    var data: Data?
    var urlResponse: URLResponse?
    var error: Error?
    
    var onDataTaskWithRequest: ((URLRequest) -> Void)?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        onDataTaskWithRequest?(request)
        completionHandler(data, urlResponse, error)
        return MockURLSessionDataTask()
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    override func resume() {
        // no-op
    }
}
