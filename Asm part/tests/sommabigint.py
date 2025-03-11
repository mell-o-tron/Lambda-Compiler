a_true = 100 * 65536 + 50
b_true = 6969 * 65536 + 30

a = [100, 50]
b = [6969, 30]

def summa(a, b):
    res = [0, 0]
    carry = 0
        
    res[1] = (a[1] + b[1]) % 65536
    # and eax, 0x0000FFFF
    carry = (a[1] + b[1]) // 65536
    
    res[0] = a[0] + b[0] + carry
    
    print(res)
    res_t = a_true + b_true
    print([res_t // 65536, res_t % 65536])
    
summa(a, b)