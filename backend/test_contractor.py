import requests
import json

# Replace with your actual access token
access_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0Y29udHJhY3RvciIsImV4cCI6MTc3MTE2ODU2MX0.iSkS3ch2ri2rixVngUQRoQq311-enWrTIep4zD6Gorg"
headers = {"Authorization": f"Bearer {access_token}"}

# Test get dashboard
response = requests.get("http://127.0.0.1:8000/api/contractor/dashboard", headers=headers)
print(response.json())

# Test get workers
response = requests.get("http://127.0.0.1:8000/api/contractor/workers", headers=headers)
print(response.json())

# Test get sites
response = requests.get("http://127.0.0.1:8000/api/contractor/sites", headers=headers)
print(response.json())

# Test get alerts
response = requests.get("http://127.0.0.1:8000/api/contractor/alerts", headers=headers)
print(response.json())

# Test get activity feed
response = requests.get("http://127.0.0.1:8000/api/contractor/activity-feed", headers=headers)
print(response.json())
