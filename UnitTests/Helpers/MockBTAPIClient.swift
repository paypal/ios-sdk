class MockBTAPIClient: BTAPIClient {

    var postedAnalyticsEvents: [String : [String:Any]] = [:]

    override func sendSDKEvent(_ eventName: String, with additionalData: [String:Any]) {
        postedAnalyticsEvents[eventName] = additionalData
    }
}
