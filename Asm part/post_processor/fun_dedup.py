import sys
import re
from collections import defaultdict

filename = sys.argv[1]

funz = []
with open(filename, 'r') as f:
    # match all functions, starting with fun_[0-9]+: and ending with ;end fun_[0-9]+
    prog = f.read()

i = 0
while True:
    i += 1
    if f'fun_{i}' not in prog:
        break
    print(f'fun_{i}')
    

    x = re.findall(f"fun_{i}:(.*);end_fun_{i}", prog, re.DOTALL)
    if len(x) == 0:
        continue
    funz.append((i, x[0]))
    
def fa_la_cosa_giusta(p):
    idx, txt = p
    d = {}
    x = re.findall(r'(branch_\d+).*:', txt)
    for i in x:
        if i not in d:
            d[i] = f'unique_{len(d)}:'
        
        txt = txt.replace(i, d[i])
    return (idx, txt)

grouped_funz = defaultdict(list)
for idx, txt in list(map(fa_la_cosa_giusta, funz)):
    grouped_funz[txt].append(idx)

grouped_funz = dict(grouped_funz)

# print(grouped_funz)
# print('Number of functions:', len(funz))
# print('Number of unique functions:', len(grouped_funz))

print(len(funz)) 

for k, v in grouped_funz.items():
    for f_v in v[1:]:
        funz_f_v = next(f for f in funz if f[0] == f_v)
        if funz_f_v[1] not in prog:
            continue
        prog = prog.replace(f'fun_{f_v}:{funz_f_v[1]}', '')
        prog = prog.replace(f';end_fun_{f_v}\n\n', '')
        prog = prog.replace(f'fun_{v[0]}:', f'fun_{v[0]}:\nfun_{f_v}:')
        
with open(filename, 'w') as f:
    f.write(prog)