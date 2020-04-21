import Foundation

class MockPPDataCollector: PPDataCollector {

    public static var didFetchClientMetadataID = false

    override class func clientMetadataID(_ pairingID: String?) -> String {
        didFetchClientMetadataID = true
        return "fake-metadata-id"
    }
}
