import requests
import json

# Delete the existing user
delete_url = "http://127.0.0.1:8000/api/auth/users/testcontractor"
response = requests.delete(delete_url)
print(f"Delete response: {response.status_code}")

# Register a new user
register_url = "http://127.0.0.1:8000/api/auth/register"
payload = {"username": "testcontractor", "password": "password", "email": "testcontractor@example.com", "full_name": "Test Contractor", "role": "contractor"}
headers = {"Content-Type": "application/json"}

response = requests.post(register_url, data=json.dumps(payload), headers=headers)

print(response.json())
