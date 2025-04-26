import Foundation
import StoreKit

@available(iOS 15.0, *)
@objcMembers public class SwiftClass : NSObject
{
    static let shared = SwiftClass()
    
    var callback: ((String, [String: Any]) -> Void)?

    private var updateTask:Task<Void, Never>? = nil
    
    override init() {
        super.init()
        updateTask = createUpdateTask()
    }
    
    deinit {
        updateTask?.cancel()
        updateTask = nil
    }
    
    private func createUpdateTask() -> Task<Void, Never> {
        Task(priority: .background) {
            print("createUpdateTask")
            for await verificationResult in Transaction.updates{
                // Approved pending transaction comes here
                print("updateTask: \(verificationResult)")
                await SwiftClass.proceedUnfinishedTransactions()
            }
        }
    }
    
    static func response(a1: String, a2: Dictionary<String, Any>) {
        shared.callback?(a1, a2)
    }
    
    static func request(a1: NSString, a2: NSDictionary)  -> Int {
        
        switch a1 {
        case "dummy":
            return requestDummy()
        case "products":
            return requestProducts(data:a2)
        case "purchase":
            return requestPurchase(data:a2)
        case "purchasedProducts":
            return requestPurchasedProducts()
        case "transactionCurrentEntitlements":
            return requestTransactionCurrentEntitlements()
        case "transactionAll":
            return requestTransactionAll()
        default:
            return 1
        }
    }
    
    static func requestDummy() -> Int {
        Task {
            do {
                print("requestDummy")
                
                try await Task.sleep(nanoseconds: 3 * 1000 * 1000 * 1000)
                let data = [
                    "dummyString": "dummy",
                    "dummyInt": 123,
                    "dummyFloat": 123.456,
                    "dummyArray1": ["a", "b", "c"],
                    "dummyArray2":[
                        ["a":"str"],
                        ["b":1],
                        ["c":0.5],
                    ]
                ]
                response(a1: "dummy", a2: data)
            } catch {
                print(error)
            }
        }
        return 0
    }
    
    static func convertProducts(_ products: [Product]) -> [[String: Any]] {
        return products.map { product in
            return [
                "product_id": product.id,
                "type": product.type.rawValue,
                "displayName": product.displayName,
                "description": product.description,
                "price": product.price,
                "displayPrice": product.displayPrice,
                "isFamilyShareable": product.isFamilyShareable
            ]

//            let json = try? JSONSerialization.jsonObject(
//                with: product.jsonRepresentation, options: [])
//            
//            var map : [String:Any] = json as? [String:Any] ?? [:]
//            return map
        }
    }
    
    static func requestProducts(data:NSDictionary) -> Int {
        print("requestProducts")
        if data.object(forKey:"product_ids") == nil {
            print("requestProducts: no 'product_ids'")
            return 1
        }
        let productIds = data["product_ids"] as? [String]
        if productIds == nil {
            print("requestProducts: failed to get productIds")
            return 1
        }
        print("requestProducts:productIds:\(String(describing: productIds))")
        Task {
            do {
                let products = try await Product.products(for:productIds!)
                print("requestProducts:products:\(products)")
                
                let converted = convertProducts(products)
                let resultData = ["products":converted]
                
                response(a1: "products", a2: resultData)
            } catch {
                // send error as signal
                let errorData = [
                    "request":"products",
                    "error":error.localizedDescription
                ]
                response(a1: "error", a2: errorData)
            }
        }
        return 0
    }
    
    static func convertPurchaseMap(transaction:Transaction) -> [String:Any] {
        return [
            "request":"purchase",
            "original_id": transaction.originalID,
            "web_order_line_item_id": transaction.webOrderLineItemID ?? "",
            "product_id": transaction.productID,
            "result":"success"
        ]
    }
    
    static func requestPurchase(data:NSDictionary) -> Int {
        print("requestPurchase")
        if data.object(forKey:"product_id") == nil {
            print("requestPurchase: no 'product_id'")
            return 1
        }
        let productId = data["product_id"] as? String
        if productId == nil {
            print("requestPurchase: product_id is not string")
            return 1
        }
        
        Task {
            do {
                let products = try await Product.products(for:[productId!])
                print("requestPurchase:products:\(products)")
                if products.count == 0 {
                    let errorData = [
                        "request":"purchase",
                        "error":"no product_id:\(productId!)"
                    ]
                    response(a1: "error", a2: errorData)
                }
                let product = products[0]
                let result:Product.PurchaseResult = try await product.purchase()
                print("requestPurchase:purchase:\(result)")
                switch result {
                case .success(.verified(let transaction)):
                    await transaction.finish()
                    let resultData = convertToPurchaseResponse(transaction)
                    response(a1: "purchase", a2: resultData)
                    break
                case .success(.unverified(_, let error)):
                    let resultData = [
                        "request":"purchase",
                        "product_id": productId!,
                        "result":"unverified",
                        "error":error.localizedDescription
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                case .pending:
                    let resultData = [
                        "request":"purchase",
                        "product_id": productId!,
                        "result":"pending"
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                case .userCancelled:
                    let resultData = [
                        "request":"purchase",
                        "product_id": productId!,
                        "result":"userCancelled"
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                @unknown default:
                    let resultData = [
                        "request":"purchase",
                        "product_id": productId!,
                        "result":"unknown"
                    ]
                    response(a1: "purchase", a2: resultData)
                    break
                }
            } catch {
                // send error as signal
                let errorData = [
                    "request":"purchase",
                    "error":error.localizedDescription
                ]
                response(a1: "error", a2: errorData)
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
                "request":"purchasedProducts",
                "product_ids": productIDs,
                "result":"success"
            ]
            response(a1: "purchasedProducts", a2: resultData)
        }
        return 0
    }
    
    static func dateToString(_ date:Date?)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return if date == nil { "" } else { dateFormatter.string(from: date!) }
    }
    
    static func convertTransaction(transaction:Transaction, error:Error?) ->[String:Any] {
        let json = try? JSONSerialization.jsonObject(
            with: transaction.jsonRepresentation, options: [])
        
        var result : [String:Any] = json as? [String:Any] ?? [:]

//        var entitlement = [
//            "id":transaction.id,
//            "originalID":transaction.originalID,
//            "webOrderLineItemID":transaction.webOrderLineItemID ?? "",
//            "productId":transaction.productID,
//            "subscriptionGroupID":transaction.subscriptionGroupID ?? "",
//            "purchaseDate":dateToString(transaction.purchaseDate),
//            "originalPurchaseDate":dateToString(transaction.purchaseDate),
//            "expirationDate":dateToString(transaction.expirationDate),
//            "purchasedQuantity":transaction.purchasedQuantity,
//            "isUpgraded":transaction.isUpgraded,
//            // offer 17.2
//            //   vs
//            // offerType,
//            // offerID,
//            // offerPaymentModeStringRepresentation
//            // offerPeriodStringRepresentation
//            "revocationDate":dateToString(transaction.revocationDate),
//            "revocationReason":transaction.revocationReason?.rawValue ?? "",
//            "productType":transaction.productType,
//            "appAccountToken":transaction.appAccountToken ?? "",
//            // environment 16.0
//            //   vs
//            // environmentStringRepresentation
//            // reason 17.0
//            //   vs
//            // reasonStringRepresentation
//            // storefront 17.0
//            //   vs
//            // storefrontCountryCode
//            // price 15.0
//            // currency 16.0
//            //   vs
//            // currencyCode
//            "appTransactionID":transaction.appTransactionID,
//            // deviceVerification
//            // deviceVerificationNonce
//            "ownershipType":transaction.ownershipType.rawValue,
//            "signedDate":dateToString(transaction.signedDate),
//            // advancedCommerceInfo 18.4
//        ] as [String : Any]
        
        if error != nil {
            result["error"] = error!.localizedDescription
        }
        
        return result
    }
    
    static func convertToPurchaseResponse(_ transaction:Transaction) -> [String:Any] {
        let resultData = [
            "request":"purchase",
            "product_id": transaction.productID,
            "quantity": transaction.purchasedQuantity,
            "product_type": transaction.productType.rawValue,
            "result":"success"
        ] as [String : Any]
        return resultData
    }
    
    static func convertTransactions(_ transactions:Transaction.Transactions) async -> [[String:Any]] {
        var results: [[String:Any]] = []
        for await verificationResult in transactions {
            switch verificationResult {
            case .verified(let transaction):
                let converted:[String:Any] = convertTransaction(transaction: transaction, error: nil)
                results.append(converted)
                
                break
            case .unverified(let transaction, let verificationError):
                let converted:[String:Any] = convertTransaction(transaction: transaction, error: verificationError)
                results.append(converted)
                break
            }
        }
        return results
    }
    
    static func requestTransactionCurrentEntitlements() -> Int {
        Task {
            var transactions: [[String:Any]] = await convertTransactions(
                Transaction.currentEntitlements
            )
            print("requestTransactionCurrentEntitlements: transactions: \(transactions)")
            let resultData = [
                "request":"transactionCurrentEntitlements",
                "transactions": transactions,
                "result":"success"
            ]
            response(a1: "transactionCurrentEntitlements", a2: resultData)
        }
        return 0
    }
    
    static func requestTransactionAll() -> Int {
        Task {
            var transactions: [[String:Any]] = await convertTransactions(
                Transaction.all
            )
            print("requestTransactionAll: transactions: \(transactions)")
            let resultData = [
                "request":"transactionAll",
                "transactions": transactions,
                "result":"success"
            ]
            response(a1: "transactionAll", a2: resultData)
        }
        return 0
    }
    
    static func proceedUnfinishedTransactions() async -> Void {
        for await verificationResult in Transaction.unfinished {
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
                let resultData = convertToPurchaseResponse(transaction)
                response(a1: "purchase", a2: resultData)
                break
            case .unverified(let transaction, let verificationError):
                print("proceedUnfinishedTransactions: unverified transaction \(transaction), error \(verificationError)")
                break
            }
        }
    }
}

