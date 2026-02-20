import requests
import json

# Replace with your actual access token for a contractor
access_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0Y29udHJhY3RvciIsImV4cCI6MTc3MTE2ODU2MX0.iSkS3ch2ri2rixVngUQRoQq311-enWrTIep4zD6Gorg"
headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}

# 1. Create a new inventory item
print("--- Creating Inventory Item ---")
item_data = {
    "name": "Hammer",
    "quantity": 10,
    "status": "available",
    "category": "tools",
    "site_id": 1
}
response = requests.post("http://127.0.0.1:8000/api/inventory/", headers=headers, data=json.dumps(item_data))
if response.status_code == 200:
    created_item = response.json()
    item_id = created_item.get("id")
    print(f"Success: {created_item}")
else:
    print(f"Error: {response.status_code} {response.text}")
    exit()

# 2. Get all inventory items
print("\n--- Getting All Inventory Items ---")
response = requests.get("http://127.0.0.1:8000/api/inventory/", headers=headers)
if response.status_code == 200:
    print(f"Success: {response.json()}")
else:
    print(f"Error: {response.status_code} {response.text}")

# 3. Get a specific inventory item
print(f"\n--- Getting Inventory Item {item_id} ---")
response = requests.get(f"http://127.0.0.1:8000/api/inventory/{item_id}", headers=headers)
if response.status_code == 200:
    print(f"Success: {response.json()}")
else:
    print(f"Error: {response.status_code} {response.text}")

# 4. Update an inventory item
print(f"\n--- Updating Inventory Item {item_id} ---")
update_data = {
    "quantity": 5,
    "status": "in_use"
}
response = requests.put(f"http://127.0.0.1:8000/api/inventory/{item_id}", headers=headers, data=json.dumps(update_data))
if response.status_code == 200:
    print(f"Success: {response.json()}")
else:
    print(f"Error: {response.status_code} {response.text}")

# 5. Delete an inventory item
print(f"\n--- Deleting Inventory Item {item_id} ---")
response = requests.delete(f"http://127.0.0.1:8000/api/inventory/{item_id}", headers=headers)
if response.status_code == 200:
    print(f"Success: {response.json()}")
else:
    print(f"Error: {response.status_code} {response.text}")

# 6. Verify deletion
print(f"\n--- Verifying Deletion of Item {item_id} ---")
response = requests.get(f"http://127.0.0.1:8000/api/inventory/{item_id}", headers=headers)
if response.status_code == 404:
    print(f"Success: Item {item_id} not found, as expected.")
else:
    print(f"Error: {response.status_code} {response.text}")
