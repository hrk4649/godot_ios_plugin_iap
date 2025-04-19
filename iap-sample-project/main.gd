extends Control

var ItemButton = preload("res://item_button.tscn")
var ItemLabel = preload("res://item_label.tscn")

@onready var container_purchase_items = $VBoxContainer/PurchaseItems
@onready var container_purchased_items = $VBoxContainer/PurchasedItems

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
	print(singleton.request("purchasedProducts", {}))

func _receive_response(response_name:String, data:Dictionary) -> void:
	print("response:%s data:%s" % [response_name, data])
	match response_name:
		"products":
			call_deferred("update_purchase_items", data)
		"purchase":
			print(singleton.request("purchasedProducts", {}))
		"purchasedProducts":
			call_deferred("update_purchased_items", data)

func update_purchase_items(data) -> void:
	for child in container_purchase_items.get_children():
		container_purchase_items.remove_child(child)

	var products = data["products"]
	for product in products:
		var button = ItemButton.instantiate()
		container_purchase_items.add_child(button)
		button.text = "ITEM:%s PRICE:%s TYPE:%s" % [
			product["displayName"], 
			product["displayPrice"],
			product["type"]
		]
		button.pressed.connect(purchase_item.bind(product["product_id"]))

func purchase_item(product_id) -> void:
	print("purchase_item:%s" % product_id)
	singleton.request("purchase", {"product_id":product_id})

func update_purchased_items(data) -> void:
	for child in container_purchased_items.get_children():
		container_purchased_items.remove_child(child)
	var product_ids = data["product_ids"]
	for product_id in product_ids:
		var label = ItemLabel.instantiate()
		container_purchased_items.add_child(label)
		label.text = product_id

func _on_button_purchased_item_pressed() -> void:
	if singleton:
		#print(singleton.request("purchasedProducts", {}))
		print(singleton.request("entitlements", {}))
