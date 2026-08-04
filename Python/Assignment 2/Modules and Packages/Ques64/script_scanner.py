import os
import json
from datetime import datetime

report = []

for root, dirs, files in os.walk("Python\Assignment 2\Modules and Packages\Ques63"):
    for file in files:
        if file.endswith(".py"):

            path = os.path.join(root, file)

            with open(path, "r") as f:
                lines = f.readlines()

            line_count = len(lines)
            func_count = 0
            class_count = 0

            for line in lines:
                if line.strip().startswith("def "):
                    func_count += 1
                elif line.strip().startswith("class "):
                    class_count += 1

            report.append({
                "file": file,
                "lines": line_count,
                "functions": func_count,
                "classes": class_count,
                "last_modified": datetime.fromtimestamp(
                    os.path.getmtime(path)
                ).strftime("%Y-%m-%d %H:%M:%S")
            })

with open("Python\Assignment 2\Modules and Packages\Ques64\code_report.json", "w") as f:
    json.dump(report, f, indent=4)

print("Report Created")