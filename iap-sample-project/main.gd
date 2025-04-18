extends Control

var ItemButton = preload("res://item_button.tscn")

@onready var container = $VBoxContainer

var singleton

func _ready() -> void:
    print("_ready")
    if !Engine.has_singleton("IOSInAppPurchase"):
        print("IOSInAppPurchase is not found")
        return

    print("IOSInAppPurchase is found")
    singleton = Engine.get_singleton("IOSInAppPurchase")
    singleton.response.connect(_receive_response)

    # var data = {
    #     "message":"hello"
    # }
    # print(singleton.request("test", data))

    # print(singleton.request("dummy", {}))

    var product_data = {
        "product_ids":[
            "dummy_consumable001", 
            "dummy_non_consumable001"
            ]
        }
    print(singleton.request("products", product_data))

func _receive_response(response_name:String, data:Dictionary) -> void:
    print("response:%s data:%s" % [response_name, data])
    match response_name:
        "products":
            call_deferred("list_products", data)
        "purchase":
            pass

func list_products(data) -> void:
    for child in container.get_children():
        container.remove_child(child)

    var products = data["products"]
    for product in products:
        var button = ItemButton.instantiate()
        container.add_child(button)
        button.text = "ITEM:%s PRICE:%s TYPE:%s" % [
            product["displayName"], 
            product["displayPrice"],
            product["type"]
        ]
        button.pressed.connect(purchase_item.bind(product["product_id"]))

func purchase_item(product_id) -> void:
    print("purchase_item:%s" % product_id)