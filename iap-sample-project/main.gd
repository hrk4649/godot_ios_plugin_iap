extends Node2D

func _ready() -> void:
    print("_ready")
    if !Engine.has_singleton("IOSInAppPurchase"):
        print("IOSInAppPurchase is not found")
        return

    print("IOSInAppPurchase is found")
    var singleton = Engine.get_singleton("IOSInAppPurchase")
    singleton.response.connect(_receive_response)
    var data = {
        "message":"hello"
    }
    print(singleton.request("products", data))

func _receive_response(response_name:String, data:Dictionary) -> void:
    print("response:%s data:%s" % [response_name, data])
