import Foundation

@objcMembers public class SwiftClass : NSObject
{
    static let shared = SwiftClass()

    var callback: ((String, [String: Any]) -> Void)?

    func response(a1: String, a2: Dictionary<String, Any>) {
        callback?(a1, a2)
    }

    static func request(a1: NSString, a2: NSDictionary)  -> Int {
        shared.response(a1: a1 as String, a2: a2 as! Dictionary<String, Any>)
        return 0
    }
}

