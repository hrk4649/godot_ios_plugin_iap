import Foundation
import StoreKit

@available(iOS 15.0, *)
@objcMembers public class SwiftClass : NSObject
{
    static let shared = SwiftClass()
    
    var callback: ((String, [String: Any]) -> Void)?
    
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
        case "entitlements":
            return requestEntitlements()
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
                    // await transaction.finish()
                    let resultData = [
                        "request":"purchase",
                        "product_id": productId!,
                        "result":"success"
                    ]
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
    
    static func convertEntitlement(transaction:Transaction, error:Error?) ->[String:Any] {
        var entitlement = [
            "id":transaction.id,
            "originalID":transaction.originalID,
            "webOrderLineItemID":transaction.webOrderLineItemID ?? "",
            "productId":transaction.productID,
            "subscriptionGroupID":transaction.subscriptionGroupID ?? "",
            "purchaseDate":dateToString(transaction.purchaseDate),
            "originalPurchaseDate":dateToString(transaction.purchaseDate),
            "expirationDate":dateToString(transaction.expirationDate),
            "purchasedQuantity":transaction.purchasedQuantity,
            "isUpgraded":transaction.isUpgraded,
            // offer 17.2
            //   vs
            // offerType,
            // offerID,
            // offerPaymentModeStringRepresentation
            // offerPeriodStringRepresentation
            "revocationDate":dateToString(transaction.revocationDate),
            "revocationReason":transaction.revocationReason?.rawValue ?? "",
            "productType":transaction.productType,
            "appAccountToken":transaction.appAccountToken ?? "",
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
            "appTransactionID":transaction.appTransactionID,
            // deviceVerification
            // deviceVerificationNonce
            "ownershipType":transaction.ownershipType.rawValue,
            "signedDate":dateToString(transaction.signedDate),
            // advancedCommerceInfo 18.4
        ] as [String : Any]
        if error != nil {
            entitlement["error"] = error!.localizedDescription
        }
        return entitlement
    }
    
    static func requestEntitlements() -> Int {
        Task {
            var entitlements: [[String:Any]] = []
            for await verificationResult in Transaction.currentEntitlements {
                switch verificationResult {
                case .verified(let transaction):
                    let entitlement:[String:Any] = convertEntitlement(transaction: transaction, error: nil)
                    entitlements.append(entitlement)
                    
                    break
                case .unverified(let transaction, let verificationError):
                    let entitlement:[String:Any] = convertEntitlement(transaction: transaction, error: verificationError)
                    entitlements.append(entitlement)
                    break
                }
            }
            print("requestEntitlements: entitlements: \(entitlements)")
            let resultData = [
                "request":"entitlements",
                "entitlements": entitlements,
                "result":"success"
            ]
            response(a1: "entitlements", a2: resultData)
        }
        return 0
    }
}

