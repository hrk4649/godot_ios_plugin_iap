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
                    await transaction.finish()
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
                        "result":"unverified"
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
}

