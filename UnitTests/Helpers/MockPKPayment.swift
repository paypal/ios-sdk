class MockPKPayment: PKPayment {

    private let _billingContact: PKContact
    private let _shippingContact: PKContact
    private let _shippingMethod: PKShippingMethod

    override var billingContact: PKContact {
        return _billingContact
    }

    override var shippingContact: PKContact {
        return _shippingContact
    }

    override var shippingMethod: PKShippingMethod {
        return _shippingMethod
    }

    init(shippingContact: PKContact, billingContact: PKContact, shippingMethod: PKShippingMethod) {
        self._shippingContact = shippingContact
        self._billingContact = billingContact
        self._shippingMethod = shippingMethod
    }
}
