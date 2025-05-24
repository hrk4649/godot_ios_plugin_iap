import Foundation
import StoreKit

@available(iOS 15.0, *)
@objcMembers public class SwiftClass: NSObject {
    static let shared = SwiftClass()

    var callback: ((String, [String: Any]) -> Void)?

    private var updateTask: Task<Void, Never>? = nil

    override init() {
        super.init()
    }

    deinit {
        updateTask?.cancel()
        updateTask = nil
    }

    private func startUpdateTask() {
        updateTask = Task(priority: .background) {
            print("startUpdateTask")
            for await verificationResult in Transaction.updates {
                print("updateTask: \(verificationResult)")
                // The following transactions come here
                // - Approved pending transaction
                // - Revoked transaction
                await SwiftClass.proceedVerificationResult(verificationResult)
            }
        }
    }

    static func response(a1: String, a2: [String: Any]) {
        shared.callback?(a1, a2)
    }

    static func request(a1: NSString, a2: NSDictionary) -> Int {

        switch a1 {
        case "startUpdateTask":
            return requestStartUpdateTask()
        case "products":
            return requestProducts(data: a2)
        case "purchase":
            return requestPurchase(data: a2)
        case "purchasedProducts":
            return requestPurchasedProducts()
        case "transactionCurrentEntitlements":
            return requestTransactionCurrentEntitlements()
        case "transactionAll":
            return requestTransactionAll()
        case "proceedUnfinishedTransactions":
            return requestProceedUnfinishedTransactions()
        case "appStoreSync":
            return requestAppStoreSync()
        default:
            return 1
        }
    }

    static func requestStartUpdateTask() -> Int {
        print("requestStartUpdateTask")
        if shared.updateTask != nil {
            // updateTask has already started
            return 1
        }
        shared.startUpdateTask()
        return 0
    }

    static func convertProducts(_ products: [Product]) -> [[String: Any]] {
        return products.map { product in
            return [
                "id": product.id,
                "type": product.type.rawValue,
                "displayName": product.displayName,
                "description": product.description,
                "price": String(describing: product.price),
                "displayPrice": product.displayPrice,
                "isFamilyShareable": String(
                    describing: product.isFamilyShareable
                ),
                "json": String(
                    data: product.jsonRepresentation,
                    encoding: .utf8
                ) ?? "",
            ]
        }
    }

    static func requestProducts(data: NSDictionary) -> Int {
        print("requestProducts")
        if data.object(forKey: "productIDs") == nil {
            print("requestProducts: no 'productIDs'")
            return 1
        }
        let productIDs = data["productIDs"] as? [String]
        if productIDs == nil {
            print("requestProducts: failed to get productIDs")
            return 1
        }
        print("requestProducts:productIDs:\(String(describing: productIDs))")
        Task {
            do {
                let products = try await Product.products(for: productIDs!)
                print("requestProducts:products:\(products)")

                let converted = convertProducts(products)
                let resultData = [
                    "request": "products",
                    "result": "success",
                    "products": converted,
                ]

                response(a1: "products", a2: resultData)
            } catch {
                // send error as signal
                let errorData = [
                    "request": "products",
                    "result": "error",
                    "error": error.localizedDescription,
                ]
                response(a1: "products", a2: errorData)
            }
        }
        return 0
    }

    static func convertPurchaseMap(transaction: Transaction) -> [String: Any] {
        return [
            "request": "purchase",
            "originalID": String(describing: transaction.originalID),
            "webOrderLineItemID": transaction.webOrderLineItemID ?? "",
            "productID": transaction.productID,
            "result": "success",
        ]
    }

    static func requestPurchase(data: NSDictionary) -> Int {
        print("requestPurchase")
        if data.object(forKey: "productID") == nil {
            print("requestPurchase: no 'productID'")
            return 1
        }
        let productID = data["productID"] as? String
        if productID == nil {
            print("requestPurchase: productID is not string")
            return 1
        }

        Task {
            do {
                let products = try await Product.products(for: [productID!])
                print("requestPurchase:products:\(products)")
                if products.count == 0 {
                    let errorData = [
                        "request": "purchase",
                        "result": "error",
                        "error": "no productID:\(productID!)",
                    ]
                    response(a1: "purchase", a2: errorData)
                }
                let product = products[0]
                let result: Product.PurchaseResult =
                    try await product.purchase()
                print("requestPurchase:purchase:\(result)")
                switch result {
                case .success(.verified(let transaction)):
                    await transaction.finish()
                    let resultData = convertToPurchaseResponse(transaction)
                    response(a1: "purchase", a2: resultData)
                    break
                case .success(.unverified(let transaction, let error)):
                    let resultData = [
                        "request": "purchase",
                        "productID": productID!,
                        "result": "unverified",
                        "error": error.localizedDescription,
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                case .pending:
                    let resultData = [
                        "request": "purchase",
                        "productID": productID!,
                        "result": "pending",
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                case .userCancelled:
                    let resultData = [
                        "request": "purchase",
                        "productID": productID!,
                        "result": "userCancelled",
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                @unknown default:
                    let resultData = [
                        "request": "purchase",
                        "productID": productID!,
                        "result": "unknown",
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                }
            } catch {
                // send error as signal
                let errorData = [
                    "request": "purchase",
                    "result": "error",
                    "error": error.localizedDescription,
                ]
                response(a1: "purchase", a2: errorData)
            }
        }
        return 0
    }

    static func requestPurchasedProducts() -> Int {
        Task {
            var purchasedProductIDs: Set<String> = []
            for await result in Transaction.currentEntitlements {
                guard case .verified(let entitlement) = result else { continue }
                print("requestPurchasedProducts: entitlement: \(entitlement)")
                if entitlement.revocationDate == nil {
                    purchasedProductIDs.insert(entitlement.productID)
                }
            }
            let productIDs: [String] = Array(purchasedProductIDs)
            print("requestPurchasedProducts: productIDs: \(productIDs)")
            let resultData = [
                "request": "purchasedProducts",
                "productIDs": productIDs,
                "result": "success",
            ]
            response(a1: "purchasedProducts", a2: resultData)
        }
        return 0
    }

    static func dateToString(_ date: Date?) -> String {
        return if let d = date {
            d.formatted(
                .iso8601
                    .year()
                    .month()
                    .day()
                    .timeZone(separator: .omitted)
                    .time(includingFractionalSeconds: true)
                    .timeSeparator(.colon)
            )
        } else {
            ""
        }
    }

    static func convertToPurchaseResponse(_ transaction: Transaction)
        -> [String: Any]
    {
        let result =
            if transaction.revocationDate != nil {
                "revoked"
            } else {
                "success"
            }

        var resultData: [String: Any] = [:]
        resultData["request"] = "purchase"
        resultData["result"] = result
        resultData["productID"] = transaction.productID
        resultData["purchasedQuantity"] = String(
            describing: transaction.purchasedQuantity
        )
        resultData["productType"] = transaction.productType.rawValue

        if let s = String(
            data: transaction.jsonRepresentation,
            encoding: .utf8
        ) {
            resultData["json"] = s
        }

        if let d = transaction.revocationDate {
            resultData["revocationDate"] = dateToString(d)
        }

        return resultData
    }

    static func convertTransaction(transaction: Transaction, error: Error?)
        -> [String: Any]
    {
        var result: [String: Any] = [:]
        result["id"] = String(describing: transaction.id)
        result["originalID"] = String(describing: transaction.originalID)
        if let s = transaction.webOrderLineItemID {
            result["webOrderLineItemID"] = s
        }
        result["productID"] = transaction.productID
        if let s = transaction.subscriptionGroupID {
            result["subscriptionGroupID"] = s
        }
        result["purchaseDate"] = dateToString(transaction.purchaseDate)
        result["originalPurchaseDate"] = dateToString(
            transaction.originalPurchaseDate
        )
        if let d = transaction.expirationDate {
            result["expirationDate"] = dateToString(d)
        }
        result["purchasedQuantity"] = String(
            describing: transaction.purchasedQuantity
        )
        result["isUpgraded"] = String(describing: transaction.isUpgraded)
        // offer 17.2
        //   vs
        // offerType,
        // offerID,
        // offerPaymentModeStringRepresentation
        // offerPeriodStringRepresentation
        if let d = transaction.revocationDate {
            result["revocationDate"] = dateToString(d)
        }
        if let s = transaction.revocationReason?.rawValue {
            result["revocationReason"] = s
        }
        result["productType"] = transaction.productType.rawValue
        if let s = transaction.appAccountToken {
            result["appAccountToken"] = s
        }
        // environment 16.0
        //   vs
        // environmentStringRepresentation
        // reason 17.0
        //   vs
        // reasonStringRepresentation
        // storefront 17.0
        //   vs
        // storefrontCountryCode
        // price 15.0
        // currency 16.0
        //   vs
        // currencyCode
        result["appTransactionID"] = transaction.appTransactionID
        // deviceVerification
        // deviceVerificationNonce
        result["ownershipType"] = transaction.ownershipType.rawValue
        result["signedDate"] = dateToString(transaction.signedDate)
        // advancedCommerceInfo 18.4
        if let s = String(
            data: transaction.jsonRepresentation,
            encoding: .utf8
        ) {
            result["json"] = s
        }

        if error != nil {
            result["error"] = error!.localizedDescription
        }

        return result
    }

    static func convertTransactions(_ transactions: Transaction.Transactions)
        async -> [[String: Any]]
    {
        var results: [[String: Any]] = []
        for await verificationResult in transactions {
            switch verificationResult {
            case .verified(let transaction):
                let converted: [String: Any] = convertTransaction(
                    transaction: transaction,
                    error: nil
                )
                results.append(converted)

                break
            case .unverified(let transaction, let verificationError):
                let converted: [String: Any] = convertTransaction(
                    transaction: transaction,
                    error: verificationError
                )
                results.append(converted)
                break
            }
        }
        return results
    }

    static func requestTransactionCurrentEntitlements() -> Int {
        Task {
            let transactions: [[String: Any]] = await convertTransactions(
                Transaction.currentEntitlements
            )
            print(
                "requestTransactionCurrentEntitlements: transactions: \(transactions)"
            )
            let resultData = [
                "request": "transactionCurrentEntitlements",
                "transactions": transactions,
                "result": "success",
            ]
            response(a1: "transactionCurrentEntitlements", a2: resultData)
        }
        return 0
    }

    static func requestTransactionAll() -> Int {
        Task {
            let transactions: [[String: Any]] = await convertTransactions(
                Transaction.all
            )
            print("requestTransactionAll: transactions: \(transactions)")
            let resultData = [
                "request": "transactionAll",
                "transactions": transactions,
                "result": "success",
            ]
            response(a1: "transactionAll", a2: resultData)
        }
        return 0
    }

    static func proceedVerificationResult(
        _ verificationResult: VerificationResult<Transaction>
    ) async {
        switch verificationResult {
        case .verified(let transaction):
            await transaction.finish()
            let resultData = convertToPurchaseResponse(transaction)
            response(a1: "purchase", a2: resultData)
            break
        case .unverified(let transaction, let verificationError):
            print(
                "proceedVerificationResult: unverified transaction \(transaction), error \(verificationError)"
            )
            break
        }
    }

    static func proceedUnfinishedTransactions() async {
        for await verificationResult in Transaction.unfinished {
            await proceedVerificationResult(verificationResult)
        }
    }

    static func requestProceedUnfinishedTransactions() -> Int {
        Task {
            await proceedUnfinishedTransactions()
            let resultData = [
                "request": "proceedUnfinishedTransactions",
                "result": "success",
            ]
            response(a1: "proceedUnfinishedTransactions", a2: resultData)
        }
        return 0
    }

    static func requestAppStoreSync() -> Int {
        print("requestAppStoreSync")
        Task {
            do {
                try await AppStore.sync()
                let resultData = [
                    "request": "appStoreSync",
                    "result": "success",
                ]
                response(a1: "appStoreSync", a2: resultData)
            } catch {
                let resultData = [
                    "request": "appStoreSync",
                    "result": "error",
                    "error": error.localizedDescription,
                ]
                response(a1: "appStoreSync", a2: resultData)
            }
        }
        return 0
    }
}
