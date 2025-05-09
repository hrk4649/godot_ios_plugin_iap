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
	print("startUpdateTask:%s" % singleton.request("startUpdateTask", {}))

	# var data = {
	#     "message":"hello"
	# }
	# print(singleton.request("test", data))

	# print(singleton.request("dummy", {}))

	call_products()

	# print(singleton.request("purchasedProducts", {}))
	print("transactionCurrentEntitlements:%s" % 
		singleton.request("transactionCurrentEntitlements", {}))

func call_products() -> void:
	var product_data = {
		"productIDs":[
			"dummy_consumable001", 
			"dummy_non_consumable001",
			"okinawa.flat_e.iap_demo_project.sg1.premium",
			"okinawa.flat_e.iap_demo_project.sg1.standard",
			"okinawa.flat_e.iap_demo_project.non_auto_renewal_subscription001"
			]
		}
	print(singleton.request("products", product_data))

func _receive_response(response_name:String, data:Dictionary) -> void:
	print("response:%s data:%s" % [response_name, data])
	match response_name:
		"products":
			if data["result"] == "success":
				call_deferred("update_purchase_items", data)
			else:
				# retry request
				await get_tree().create_timer(5.0).timeout
				call_deferred("call_products")
		"purchase":
			# print(singleton.request("purchasedProducts", {}))
			print("transactionCurrentEntitlements:%s" % 
				singleton.request("transactionCurrentEntitlements", {}))
		"purchasedProducts":
			call_deferred("update_purchased_items", data)
		"transactionCurrentEntitlements":
			call_deferred("update_purchased_items2", data)

func update_purchase_items(data) -> void:
	for child in container_purchase_items.get_children():
		container_purchase_items.remove_child(child)

	var products = data["products"]
	for product in products:
		var button = ItemButton.instantiate()
		container_purchase_items.add_child(button)
		button.text = "ID:%s ITEM:%s PRICE:%s TYPE:%s" % [
			product["id"], 
			product["displayName"], 
			product["displayPrice"],
			product["type"]
		]
		button.pressed.connect(purchase_item.bind(product["id"]))

func purchase_item(product_id) -> void:
	print("purchase_item:%s" % product_id)
	singleton.request("purchase", {"productID":product_id})

func update_purchased_items(data) -> void:
	for child in container_purchased_items.get_children():
		container_purchased_items.remove_child(child)
	var product_ids = data["productIDs"]
	for product_id in product_ids:
		var label = ItemLabel.instantiate()
		container_purchased_items.add_child(label)
		label.text = product_id

func update_purchased_items2(data) -> void:
	for child in container_purchased_items.get_children():
		container_purchased_items.remove_child(child)
	var transactions = data["transactions"]
	for transaction in transactions:
		var label = ItemLabel.instantiate()
		container_purchased_items.add_child(label)
		label.text = "PRODUCT_ID:%s EXPIRATION_DATE:%s" % [
			transaction["productID"], 
			transaction["expirationDate"]
		]

func _on_button_purchased_item_pressed() -> void:
	if singleton:
		print(singleton.request("transactionCurrentEntitlements", {}))


func _on_button_transaction_history_pressed() -> void:
	if singleton:
		print(singleton.request("transactionAll", {}))

func _on_button_proceed_unfinished_pressed() -> void:
	if singleton:
		print(singleton.request("proceedUnfinishedTransactions", {}))
