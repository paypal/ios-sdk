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
    @IBOutlet weak var idTokenLabel: UILabel!
    @IBOutlet weak var otherCheckoutStackView: UIStackView!
    
    private var orderID: String?
    private var payPalClient: PYPLClient?

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let applePayButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .whiteOutline)
        applePayButton.addTarget(self, action: #selector(applePayCheckoutTapped(_:)), for: .touchUpInside)
        otherCheckoutStackView.addArrangedSubview(applePayButton)
        
        generateIDToken()
    }

    override func viewWillAppear(_ animated: Bool) {
        amountTextField.text = "10.00"
        payeeEmailTextField.text = DemoSettings.payeeEmailAddress

        generateIDToken()
        processOrderButton.setTitle("\(DemoSettings.intent.capitalized) Order", for: .normal)
    }

    // MARK: - IBActions

    @IBAction func cardCheckoutTapped(_ sender: UIButton) {
        guard let orderID = orderID, let card = createBTCard() else { return }

        updateCheckoutLabel(withText: "Checking out with card...")
        payPalClient?.checkoutWithCard(orderID: orderID, card: card) { (checkoutResult, error) in
            if ((error) != nil) {
                self.updateCheckoutLabel(withText: "\(error?.localizedDescription ?? "Card checkout error")")
                return
            }

            guard let orderID = checkoutResult?.orderID else { return }
            self.updateCheckoutLabel(withText: "Card checkout complete: \(orderID)")
            self.processOrderButton.isEnabled = true
        }
    }

    @IBAction func payPalCheckoutTapped(_ sender: UIButton) {
        guard let orderID = orderID else { return }

        updateCheckoutLabel(withText: "Checking out with PayPal...")

        payPalClient?.checkoutWithPayPal(orderID: orderID, completion: { (checkoutResult, error) in
            if ((error) != nil) {
                self.updateCheckoutLabel(withText: "\(error?.localizedDescription ?? "PayPal Checkout error")")
                return
            }

            guard let orderID = checkoutResult?.orderID else { return }
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
        payPalClient?.checkoutWithApplePay(orderID: orderID, paymentRequest: paymentRequest, completion: { (checkoutResult, error, applePayResultHandler) in
            guard let result = checkoutResult, let resultHandler = applePayResultHandler else {
                self.updateCheckoutLabel(withText: "ApplePay Error: \(error?.localizedDescription ?? "error")")
                return
            }

            self.updateCheckoutLabel(withText: "ApplePay checkout complete: \(result.orderID)")
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
        generateIDToken()
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

    func generateIDToken() {
        updateIDTokenLabel(withText: "Fetching ID Token...")
        DemoMerchantAPI.sharedService.generateIDToken(countryCode: DemoSettings.countryCode) { (idToken, error) in
            guard let idToken = idToken, error == nil else {
                self.updateIDTokenLabel(withText: "Failed to fetch ID Token: \(error!.localizedDescription). Tap refresh to try again.")
                return
            }

            self.updateIDTokenLabel(withText: "Fetched ID Token: \(idToken)")
            self.payPalClient = PYPLClient(idToken: idToken)

            if (self.payPalClient != nil) {
                self.payPalClient?.presentingDelegate = self
            } else {
                self.updateCheckoutLabel(withText: "Error initializing PayPal Client from ID Token.")
            }
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

    private func updateIDTokenLabel(withText text: String) {
        DispatchQueue.main.async {
            self.idTokenLabel.text = text
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
