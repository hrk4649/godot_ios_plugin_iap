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
        print("requestProducts:productIds:\(productIds)")
        Task {
            do {
                let products = try await Product.products(
                    for:productIds!)
                print("requestProducts:products:\(products)")

                // response(a1: "products", a2: data)
            } catch {
                print(error)
            }
        }
        return 0
    }
}

