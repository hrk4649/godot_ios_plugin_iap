extends Node2D

func _ready() -> void:
    print("_ready")
    if !Engine.has_singleton("IOSInAppPurchase"):
        print("IOSInAppPurchase is not found")
        return

    print("IOSInAppPurchase is found")
    var singleton = Engine.get_singleton("IOSInAppPurchase")
    var data = {
        "message":"hello"
    }
    print(singleton.request("products", data))
