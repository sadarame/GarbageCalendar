"""Verify postal normalization, responses, and multiple address handling without network."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / 'GarbageCalendar/Models/ApiResponseModel.swift').read_text()
source += (root / 'GarbageCalendar/Models/GarbageAreaConvModel.swift').read_text()
source += r'''
final class PostalMockProtocol: URLProtocol {
    static var body = ""
    static var status = 200
    static var failure: URLError?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        precondition(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.contains(URLQueryItem(name: "zipcode", value: "3360911")) == true)
        precondition(request.timeoutInterval == 20)
        if let failure = Self.failure { client?.urlProtocol(self, didFailWithError: failure); return }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
func check() async throws {
    for input in ["3360911", "336-0911", "〒３３６－０９１１", " 336 0911 "] {
        precondition(try PostalCodeLookup.normalize(input) == "3360911")
    }
    for input in ["", "336091", "33609111", "abc3360911", "336a0911"] {
        do { _ = try PostalCodeLookup.normalize(input); fatalError("Accepted invalid input") }
        catch PostalCodeLookup.LookupError.invalid {}
    }
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [PostalMockProtocol.self]
    let session = URLSession(configuration: config)
    let address = #"{"address1":"埼玉県","address2":"さいたま市緑区","address3":"三室","kana1":"","kana2":"","kana3":"","prefcode":"11","zipcode":"3360911"}"#
    PostalMockProtocol.body = "{\"status\":200,\"results\":[" + address + "," + address + "]}"
    let addresses = try await PostalCodeLookup.addresses(for: "336-0911", session: session)
    precondition(addresses.count == 2, "Keep all choices rather than silently taking first")
    precondition(addresses[0].geocodingAddress == "埼玉県さいたま市緑区三室")
    for body in [#"{"status":200,"results":null}"#, #"{"status":200,"results":[]}"#] {
        PostalMockProtocol.body = body
        do { _ = try await PostalCodeLookup.addresses(for: "3360911", session: session); fatalError("Expected notFound") }
        catch PostalCodeLookup.LookupError.notFound {}
    }
    PostalMockProtocol.body = #"{"status":500,"results":null}"#
    do { _ = try await PostalCodeLookup.addresses(for: "3360911", session: session); fatalError("Expected unavailable") }
    catch PostalCodeLookup.LookupError.unavailable {}
    PostalMockProtocol.status = 503
    do { _ = try await PostalCodeLookup.addresses(for: "3360911", session: session); fatalError("Expected HTTP error") }
    catch PostalCodeLookup.LookupError.unavailable {}
    PostalMockProtocol.status = 200
    PostalMockProtocol.body = "invalid json"
    do { _ = try await PostalCodeLookup.addresses(for: "3360911", session: session); fatalError("Expected decoding error") }
    catch is DecodingError {}
    for code in [URLError.notConnectedToInternet, .timedOut] {
        PostalMockProtocol.failure = URLError(code)
        do { _ = try await PostalCodeLookup.addresses(for: "3360911", session: session); fatalError("Expected network error") }
        catch let error as URLError { precondition(error.code == code) }
    }
    PostalMockProtocol.failure = nil
    PostalMockProtocol.body = "{\"status\":200,\"results\":[" + address + "]}"
    let recovered = try await PostalCodeLookup.addresses(for: "3360911", session: session)
    precondition(recovered.count == 1)
    for value in ["javascript:alert(1)", "file:///tmp/a", "invalid", "https://"] {
        precondition(CollectionReference(scheduleId: "a", sourceUrl: value).url == nil)
    }
    let reference = CollectionReference(scheduleId: "district", sourceUrl: "https://example.jp/calendar.pdf")
    let restored = try JSONDecoder().decode(CollectionReference.self, from: JSONEncoder().encode(reference))
    precondition(restored.scheduleId == "district" && restored.url == reference.url)
    let old = try JSONDecoder().decode(CollectionReference.self, from: Data(#"{"scheduleId":"district"}"#.utf8))
    precondition(old.url == nil)
    print("PASS: postal validation, response errors, offline, timeout, recovery, reference URL and decoding")
}
Task {
    do { try await check(); exit(0) }
    catch { print("FAIL: \(error)"); exit(1) }
}
RunLoop.main.run()
'''
source = source.replace('precondition(try PostalCodeLookup.normalize(input) == "3360911")', 'let normalized = try PostalCodeLookup.normalize(input)\n        precondition(normalized == "3360911")')
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / 'PostalLookup.swift'
    path.write_text(source)
    subprocess.run(['xcrun', 'swift', str(path)], check=True, timeout=60)
