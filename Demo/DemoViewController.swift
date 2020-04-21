class DemoViewController: UIViewController, BTViewControllerPresentingDelegate {

    // MARK: - Properties

    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var expirationDateTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var cvvTextField: UITextField!
    @IBOutlet weak var payeeEmailTextField: UITextField!
    @IBOutlet weak var orderResultLabel: UILabel!
    @IBOutlet weak var processOrderButton: UIButton!
    @IBOutlet weak var checkoutResultLabel: UILabel!
    @IBOutlet weak var uatLabel: UILabel!
    @IBOutlet weak var otherCheckoutStackView: UIStackView!
    
    private var orderID: String?
    private var payPalValidatorClient: PPCValidatorClient?

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let applePayButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .whiteOutline)
        applePayButton.addTarget(self, action: #selector(applePayCheckoutTapped(_:)), for: .touchUpInside)
        otherCheckoutStackView.addArrangedSubview(applePayButton)
        
        generateUAT()
    }

    override func viewWillAppear(_ animated: Bool) {
        amountTextField.text = "10.00"
        payeeEmailTextField.text = DemoSettings.payeeEmailAddress

        generateUAT()
        processOrderButton.setTitle("\(DemoSettings.intent.capitalized) Order", for: .normal)
    }

    // MARK: - IBActions

    @IBAction func cardCheckoutTapped(_ sender: UIButton) {
        guard let orderID = orderID, let card = createBTCard() else { return }

        updateCheckoutLabel(withText: "Validating card...")
        payPalValidatorClient?.checkoutWithCard(orderID: orderID, card: card) { (validatorResult, error) in
            if ((error) != nil) {
                self.updateCheckoutLabel(withText: "\(error?.localizedDescription ?? "Card checkout error")")
                return
            }

            guard let orderID = validatorResult?.orderID else { return }
            self.updateCheckoutLabel(withText: "Validate card success: \(orderID)")
            self.processOrderButton.isEnabled = true
        }
    }

    @IBAction func payPalCheckoutTapped(_ sender: UIButton) {
        guard let orderID = orderID else { return }

        updateCheckoutLabel(withText: "Checking out with PayPal...")

        payPalValidatorClient?.checkoutWithPayPal(orderID: orderID, completion: { (validatorResult, error) in
            if ((error) != nil) {
                self.updateCheckoutLabel(withText: "\(error?.localizedDescription ?? "PayPal Checkout error")")
                return
            }

            guard let orderID = validatorResult?.orderID else { return }
            self.updateCheckoutLabel(withText: "PayPal checkout complete: \(orderID)")
            self.processOrderButton.isEnabled = true
        })
    }

    @IBAction func applePayCheckoutTapped(_ sender: PKPaymentButton) {
        guard let orderID = orderID else { return }

        let paymentRequest = PKPaymentRequest()

        // Set other PKPaymentRequest properties here
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Sock", amount: NSDecimalNumber(string: self.amountTextField.text))
        ]

        self.updateCheckoutLabel(withText: "Checking out with Apple Pay ...")
        payPalValidatorClient?.checkoutWithApplePay(orderID: orderID, paymentRequest: paymentRequest, completion: { (validatorResult, error, applePayResultHandler) in
            guard let validatorResult = validatorResult, let resultHandler = applePayResultHandler else {
                self.updateCheckoutLabel(withText: "ApplePay Error: \(error?.localizedDescription ?? "error")")
                return
            }

            self.updateCheckoutLabel(withText: "ApplePay successful: \(validatorResult.orderID)")
            self.processOrderButton.isEnabled = true

            resultHandler(true)
        })
    }

    @IBAction func processOrderTapped(_ sender: Any) {
        guard let orderID = orderID else { return }

        updateCheckoutLabel(withText: "Processing order...")

        let params = ProcessOrderParams(orderId: orderID, intent: DemoSettings.intent, countryCode: DemoSettings.countryCode)

        DemoMerchantAPI.sharedService.processOrder(processOrderParams: params) { (transactionResult, error) in
            guard let transactionResult = transactionResult else {
                self.updateCheckoutLabel(withText: "Transaction failed: \(error?.localizedDescription ?? "error")")
                return
            }

            self.updateCheckoutLabel(withText: "\(DemoSettings.intent.capitalized) Status: \(transactionResult.status)")
        }
    }

    @IBAction func generateOrderTapped(_ sender: Any) {
        updateOrderLabel(withText: "Creating order...", color: UIColor.black)
        updateCheckoutLabel(withText: "")
        self.processOrderButton.isEnabled = false

        let amount = amountTextField.text!
        let payeeEmail = payeeEmailTextField.text!
        let currencyCode = DemoSettings.currencyCode

        let orderRequestParams = CreateOrderParams(intent: DemoSettings.intent.uppercased(),
                                                   purchaseUnits: [PurchaseUnit(amount: Amount(currencyCode: currencyCode, value: amount),
                                                                                payee: Payee(emailAddress: payeeEmail))])

        DemoMerchantAPI.sharedService.createOrder(countryCode: DemoSettings.countryCode, orderParams: orderRequestParams) { (orderResult, error) in
            guard let order = orderResult, error == nil else {
                self.updateOrderLabel(withText: "Error: \(error!.localizedDescription)", color: UIColor.red)
                return
            }

            self.orderID = order.id
            self.updateOrderLabel(withText: "Order ID: \(order.id)", color: UIColor.black)
        }
    }

    @IBAction func settingsTapped(_ sender: Any) {
        let settingsViewController = IASKAppSettingsViewController()
        settingsViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        present(navigationController, animated: true, completion: nil)

        // Wipe orderID when settings page is accessed
        updateOrderLabel(withText: "Order ID: None", color: UIColor.lightGray)
        orderID = nil
    }
    
    @IBAction func refreshTapped(_ sender: Any) {
        generateUAT()
    }

    // MARK: - Construct order/request helpers

    func createBTCard() -> BTCard? {
        let card = BTCard()

        guard let cardNumber = self.cardNumberTextField.text else {
            return nil
        }

        guard let expiry = self.expirationDateTextField.text else {
            return nil
        }

        guard let cvv = self.cvvTextField.text else {
            return nil
        }

        // TODO: Apply proper regulations on card info UITextFields.
        // Will not work properly if expiration not in "01/22" format.
        if (cardNumber == "" || expiry == "" || cvv == "" || expiry.count < 5) {
            showAlert(message: "Card entry form incomplete.")
            return nil
        }

        card.number = cardNumber
        card.cvv = cvv
        card.expirationMonth = String(expiry.prefix(2))
        card.expirationYear = "20" + String(expiry.suffix(2))
        return card
    }

    func generateUAT() {
        updateUATLabel(withText: "Fetching UAT...")
        DemoMerchantAPI.sharedService.generateUAT(countryCode: DemoSettings.countryCode) { (uat, error) in
            guard let uat = uat, error == nil else {
                self.updateUATLabel(withText: "Failed to fetch UAT: \(error!.localizedDescription). Tap refresh to try again.")
                return
            }

            self.updateUATLabel(withText: "Fetched UAT: \(uat)")
            self.payPalValidatorClient = PPCValidatorClient(accessToken: uat)
            self.payPalValidatorClient?.presentingDelegate = self
        }
    }

    // MARK: - UI Helpers

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Incomplete Fields", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    private func updateOrderLabel(withText text: String, color: UIColor) {
        DispatchQueue.main.async {
            self.orderResultLabel.text = text
            self.orderResultLabel.textColor = color
        }
    }

    private func updateCheckoutLabel(withText text: String) {
        DispatchQueue.main.async {
            self.checkoutResultLabel.text = text
        }
    }

    private func updateUATLabel(withText text: String) {
        DispatchQueue.main.async {
            self.uatLabel.text = text
        }
    }

    // MARK: - BTViewControllerPresentingDelegate

    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        self.present(viewController, animated: true)
    }

    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        self.dismiss(animated: true)
    }
}

// MARK: - IASKSettingsDelegate
extension DemoViewController: IASKSettingsDelegate {
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        sender.dismiss(animated: true)
        // TODO - reload
    }
}
