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
	# get the singleton
	singleton = Engine.get_singleton("IOSInAppPurchase")
	# connect response signal with the callback method.
	# It should be done before calling startUpdateTask to receive
	# purchase responses occured outside of the app.
	singleton.response.connect(_receive_response)
	# start update task to receive update outside of the app
	print("startUpdateTask:%s" % singleton.request("startUpdateTask", {}))

	call_products()

	print("transactionCurrentEntitlements:%s" % 
		singleton.request("transactionCurrentEntitlements", {}))

func call_products() -> void:
	# get product list
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
	# receive response signals from the plugin.
	print("response:%s data:%s" % [response_name, data])
	match response_name:
		"products":
			if data["result"] == "success":
				call_deferred("update_product_list", data)
			else:
				# retry request
				await get_tree().create_timer(5.0).timeout
				call_deferred("call_products")
		"purchase":
			if data["result"] == "success":
				call_deferred("item_purchased", data)
		"purchasedProducts":
			call_deferred("handle_purchased_products", data)
		"transactionCurrentEntitlements":
			call_deferred("handle_transaction_current_entitlements", data)

func item_purchased(data) -> void:
	# When purchasing a consumable item, 
	# increasing number of item in your app may be needed

	# response of purchase is like:
	# {
	#     "request": "purchase",
	#     "result": "success",
	#     "productID": "xxxxxxxx",
	#     "purchasedQuantity": "1"
	#     "productType": "Consumable",
	#     "json": "{ ... }",
	#     "revocationDate": "",  // revoked purchase has "revocationDate"
	# }

	print("item_purchased:%s" % data)
	print("transactionCurrentEntitlements:%s" % 
		singleton.request("transactionCurrentEntitlements", {}))

func update_product_list(data) -> void:
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
	# specify "productID" to purchase
	singleton.request("purchase", {"productID":product_id})

func handle_purchased_products(data) -> void:
	for child in container_purchased_items.get_children():
		container_purchased_items.remove_child(child)
	# response of purchasedProducts includes only product id
	var product_ids = data["productIDs"]
	for product_id in product_ids:
		var label = ItemLabel.instantiate()
		container_purchased_items.add_child(label)
		label.text = product_id

func handle_transaction_current_entitlements(data) -> void:
	# response of transactionCurrentEntitlements is like:
	# {
	#     "transactions": [
	#         {
	#             "productID": "xxxxxxxx",
	#             "signedDate": "2025-05-23 15:14:13",
	#             "productType": "Non-Renewing Subscription",
	#             "appTransactionID": "704407022484307126",
	#             "id": "2000000902286324",
	#             "purchasedQuantity": "1",
	#             "originalPurchaseDate": "2025-04-21 06:58:55",
	#             "json": "{...}",
	#             "isUpgraded": "false",
	#             "purchaseDate": "2025-04-21 06:58:55",
	#             "originalID": "2000000902286324",
	#             "ownershipType": "PURCHASED"
	#         }
	#     ],
	#     "result": "success",
	#     "request": "transactionCurrentEntitlements"
	# }

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
		# transactionAll gets all transaction
		print(singleton.request("transactionAll", {}))

func _on_button_proceed_unfinished_pressed() -> void:
	if singleton:
		# proceedUnfinishedTransactions finishes unfinished transactions
		print(singleton.request("proceedUnfinishedTransactions", {}))

func _on_button_app_store_sync_pressed() -> void:
	if singleton:
		# appStoreSync restores purchase
		print(singleton.request("appStoreSync", {}))
