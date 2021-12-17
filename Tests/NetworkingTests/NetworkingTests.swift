import XCTest
import Combine

@testable import Networking

public final class XBCDClient: APIClient {
    
    public var token: String? = nil
    
    // Default URL Constructor Elements
    private let host: String = "xkcd.com"
    private let scheme: String = "https"
    
    lazy public var baseUrlComponents: URLComponents = {
        var comp = URLComponents()
        comp.host = host
        comp.scheme = scheme
        return comp
    }()
    
    public var session: URLSession = URLSession.shared
}

extension APIRequest {
    public var method: RequestMethod { return .get }
    public var contentType: String { return "application/json" }
    public var queryParams: [String: String]? { return nil }
    public var body: [String: Any]? { return nil }
    public var headers: [String: String]? { return nil }
}

public struct Comic: Codable {
    let month: String
    let num: Int
    let link, year, news, safeTitle: String
    let transcript, alt: String
    let img: String
    let title, day: String
    
    enum CodingKeys: String, CodingKey {
        case month, num, link, year, news
        case safeTitle = "safe_title"
        case transcript, alt, img, title, day
    }
}

public final class FetchComicRequest: APIRequest {
    public var body: Data? = nil
    
    public func localizedErrorDescription(statusCode: ResponseStatus) -> String? {
        return "FAILED"
    }
    
    public typealias ReturnType = Comic
    
    private let endpath = "info.0.json"
    
    var id: Int? = nil
    
    public var path: String? {
        if let id = id {
            return "\(id)/" + endpath
        } else {
            return endpath
        }
    }
}

final class NetworkingTests: XCTestCase {
    let client = XBCDClient()
    private var cancellables: Set<AnyCancellable> = []

    func testBuildUrl() {
        let url = client.buildUrl(FetchComicRequest())
        
        XCTAssertEqual(url?.absoluteString, "https://xkcd.com/info.0.json")
    }
    
    func testFetchComic() {
        let expectation = self.expectation(description: "FetchComic")
        var networkError: NetworkRequestError?
        var fetchedComic: Comic?
        
        client.send(FetchComicRequest()).sink { completion in
            switch completion {
            case .finished:
                break
            case let .failure(error):
                networkError = error
            }
            
            expectation.fulfill()
        } receiveValue: { comic in
            fetchedComic = comic
        }.store(in: &cancellables)
        
        
        // Awaiting fulfilment of our expecation before
        // performing our asserts:
        waitForExpectations(timeout: 10)

        // Asserting that our Combine pipeline yielded the
        // correct output:
        XCTAssertNil(networkError)
        XCTAssertNotNil(fetchedComic, "No comic")
    }
}
