import Foundation
// import StoreKit

@available(iOS 13.0, *)
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
            return requestProducts()
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
    
    
    static func requestProducts() -> Int {
        Task {
            do {
                print("requestProducts")

                try await Task.sleep(nanoseconds: 1 * 1000 * 1000 * 1000)
                let data = [
                    "dummy": "dummy"
                ]
                response(a1: "products", a2: data)
            } catch {
                print(error)
            }
        }
        return 0
    }
}

