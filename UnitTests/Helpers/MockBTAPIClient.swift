class MockBTAPIClient: BTAPIClient {

    var postedAnalyticsEvents: [String] = []

    override func sendAnalyticsEvent(_ name: String) {
        postedAnalyticsEvents.append(name)
    }
}
