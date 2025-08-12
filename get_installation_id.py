import os
import time
import jwt
import requests


app_id = os.environ.get("GITHUB_APP_ID")
pem_str = os.environ.get("GITHUB_APP_PRIVATE_KEY")
pem_bytes = pem_str.encode('utf-8')
org = os.environ.get("GITHUB_ORG_NAME")

now = int(time.time())
payload = {
    "iat": now - 60,
    "exp": now + 600,
    "iss": app_id
}

jwt_token = jwt.encode(payload, pem_bytes, algorithm="RS256")


headers = {
    "Authorization": f"Bearer {jwt_token}",
    "Accept": "application/vnd.github+json"
}

url = f"https://api.github.com/orgs/{org}/installation"

response = requests.get(url, headers=headers)

if response.status_code == 200:
    installation_id = response.json()["id"]
    print(installation_id)
else:
    print("Error:", response.status_code, response.text)