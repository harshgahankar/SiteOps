import requests
import json

# Replace with your actual access token
access_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0dXNlciIsImV4cCI6MTc3MTE2ODQ4Nn0.0mPDtztHcTCo-q-3dIo2oN7Oul1Hee_-iSyDCt0PBp4"
headers = {"Authorization": f"Bearer {access_token}"}

# Test check-in
check_in_data = {
    "site_id": 1,
    "check_in_time": "2024-01-01T08:00:00",
    "location_lat": 0.0,
    "location_lng": 0.0,
    "device_info": "test device",
    "biometric_verified": True,
}
response = requests.post("http://127.0.0.1:8000/api/worker/check-in", headers=headers, data=json.dumps(check_in_data))
print(response.json())
attendance_id = response.json().get("id")

# Test check-out
check_out_data = {"attendance_id": 1, "check_out_time": "2024-01-01T17:00:00"}
response = requests.post("http://127.0.0.1:8000/api/worker/check-out", headers=headers, data=json.dumps(check_out_data))
print(response.json())

# Test get attendance
response = requests.get("http://127.0.0.1:8000/api/worker/attendance", headers=headers)
print(response.json())

# Test get wage summary
response = requests.get("http://127.0.0.1:8000/api/worker/wage-summary", headers=headers)
print(response.json())
