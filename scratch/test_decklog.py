import requests
import json

print("=== Hitting system/en/api/view/4DWCZ with POST ===")
try:
    r = requests.post("https://decklog-en.bushiroad.com/system/en/api/view/4DWCZ")
    print(f"Status: {r.status_code}")
    print(r.text[:500])
except Exception as e:
    print(f"Error: {e}")

print("=== Hitting system/en/api/view/4DWCZ with GET ===")
try:
    r = requests.get("https://decklog-en.bushiroad.com/system/en/api/view/4DWCZ")
    print(f"Status: {r.status_code}")
    print(r.text[:500])
except Exception as e:
    print(f"Error: {e}")

print("=== Hitting system/en/api/view with POST payload ===")
try:
    r = requests.post("https://decklog-en.bushiroad.com/system/en/api/view", json={"code": "4DWCZ"})
    print(f"Status: {r.status_code}")
    print(r.text[:500])
except Exception as e:
    print(f"Error: {e}")

print("=== Hitting system/ja/api/view/4DWCZ with POST ===")
try:
    r = requests.post("https://decklog-en.bushiroad.com/system/ja/api/view/4DWCZ")
    print(f"Status: {r.status_code}")
    print(r.text[:500])
except Exception as e:
    print(f"Error: {e}")
