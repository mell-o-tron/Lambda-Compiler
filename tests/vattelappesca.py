# From https://mail.python.org/pipermail/edu-sig/2006-July/006810.html
# John Zelle 4-5-06
# (edited for Python 3)
def leibniz_pi():
    """generator for digits of pi"""
    q,r,t,k,n,l = 1,0,1,1,3,3
    while True:
        if 4*q+r-t < n*t:
            print(n)
            q,r,t,k,n,l = (10*q,10*(r-n*t),t,k,(10*(3*q+r))//t-10*n,l)
        else:
            q,r,t,k,n,l = (q*k,(2*q+r)*l,t*l,k+1,(q*(7*k+2)+r*l)//(t*l),l+2)


# to labmdize:
def leibniz_pi_rec(iters, q, r, t, k, n, l):
    if iters == 0 and 4*q+r-t < n*t:
        return n

    if 4*q+r-t < n*t:
        return leibniz_pi_rec(iters - 1, 10*q,10*(r-n*t),t,k,(10*(3*q+r))//t-10*n,l)
    else:
        return leibniz_pi_rec(iters, q*k,(2*q+r)*l,t*l,k+1,(q*(7*k+2)+r*l)//(t*l),l+2)


# '''
# m@ ($ (Y) (\lambdas. () 

# if (L1 > L0) then 0 else
# INT (16, L2, 14, 0,0,0,0,0,0, m@(L3)[L2 + 1, L1]))) [65, 90]
# '''
# λs. 
print(leibniz_pi_rec(0, 1,0,1,1,3,3))
print()
