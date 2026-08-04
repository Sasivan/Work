import math
def factorial(n):
    if n <= 1: return n
    return n * factorial(n-1)
def is_prime(n):
    if n < 2:
        return False
    for i in range(2,int(math.sqrt(n))):
        if n%i == 0: return False
    return True
def gcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)
def lcm(a, b):
    return abs(a * b) // math.gcd(a, b)
