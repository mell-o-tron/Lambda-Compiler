Y = lambda f: (lambda x: x(x))(lambda y: f(lambda z: y(y)(z)))

def print_and_continue(text, f):
    # print(text)
    f()

Y(lambda f: (lambda x: 
    print_and_continue(x, lambda: f(x + 1)) if x < 20 else None)
)(10)


# $($(Y)(
#     λs.(2)$(L0)(0)
# ))(\lambda. 5)

# print(Y(lambda f : lambda x : x(0)) (lambda x : 5))

# def pi(i):
#     if i == 0:
#         return 1
#     else:
#         if i % 2 == 0:
#             return 1/(1+(i*2)) + pi(i-1)
#         else:
#             return -1/(1+(i*2)) + pi(i-1)


pi = lambda L1 : lambda L0 : 1 if L0 == 0 else ((1/(1+(L0*2)) + L1(L0-1)) if L0 % 2 == 0 else -1/(1+(L0*2)) + L1(L0-1))

print(Y(pi)(13) * 4)