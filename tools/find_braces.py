from pathlib import Path
p=Path('lib/screens/scan_screen.dart')
s=p.read_text().splitlines()
stack=[]
for i,line in enumerate(s, start=1):
    for ch in line:
        if ch=='{': stack.append(i)
        elif ch=='}':
            if stack: stack.pop()
            else:
                print('Unmatched closing brace at',i)
                raise SystemExit
if stack:
    print('Unmatched opening brace(s) at lines:', stack[:10])
    for ln in stack[-5:]:
        print('Context near line', ln)
        start = max(0, ln-3)
        for k in range(start, start+8):
            print(f"{k+1:4}: {s[k]}")
else:
    print('All braces matched')
