import re

file_path = r"C:\Users\User\.gemini\antigravity-ide\brain\4766f782-919c-4433-a9c7-3bfa6c2b08cf\.system_generated\steps\162\content.md"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Search for /system/ or post/get/api or view patterns
patterns = [
    r'\/system\/[^\s\'"]+',
    r'\/api\/[^\s\'"]+',
    r'\.post\([^\)]+\)',
    r'\.get\([^\)]+\)',
    r'view\/[^\s\'"]+',
]

for pat in patterns:
    print(f"--- Matches for pattern: {pat} ---")
    matches = re.finditer(pat, content)
    for i, m in enumerate(matches):
        start = max(0, m.start() - 50)
        end = min(len(content), m.end() + 50)
        print(f"{i+1}: ... {content[start:end]} ...")
        if i >= 20:
            print("Truncated...")
            break
