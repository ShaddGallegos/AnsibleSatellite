import sys, re

existing = re.findall(r'node(\d{3})', sys.argv[1])
used = sorted(set(int(n) for n in existing))
for i in range(1, max(used + [0]) + 2):
    if i not in used:
        print(f"node{i:03}")
        break

