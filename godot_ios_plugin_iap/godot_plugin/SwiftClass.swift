import Foundation

@objcMembers public class SwiftClass : NSObject
{
    static let shared = SwiftClass()

    var callback: ((String, [String: Any]) -> Void)?

    static func response(a1: String, a2: Dictionary<String, Any>) {
        shared.callback?(a1, a2)
    }

    static func request(a1: NSString, a2: NSDictionary)  -> Int {

        switch a1 {
        case "products":
            response(a1: a1 as String, a2: a2 as! Dictionary<String, Any>)
            return 0
        default:
            return 1
        }
    }
}

