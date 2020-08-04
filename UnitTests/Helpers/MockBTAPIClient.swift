class MockBTAPIClient: BTAPIClient {

    var postedAnalyticsEvents: [String : [AnyHashable : Any]] = [:]

    override func sendSDKEvent(_ eventName: String, with additionalData: [AnyHashable : Any]) {
        postedAnalyticsEvents[eventName] = additionalData
    }
}
