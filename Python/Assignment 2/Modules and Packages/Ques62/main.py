# main.py
import mathutils

print("--- mathutils.py Demonstration ---")
# Factorial
print(f"Factorial of 5: {mathutils.factorial(5)}")
print(f"Factorial of 0: {mathutils.factorial(0)}")

# Prime
print(f"Is 11 prime? {mathutils.is_prime(11)}")
print(f"Is 25 prime? {mathutils.is_prime(25)}")

# GCD
print(f"GCD of 48 and 18: {mathutils.gcd(48, 18)}")
print(f"GCD of 101 and 10: {mathutils.gcd(101, 10)}")

# LCM
print(f"LCM of 4 and 6: {mathutils.lcm(4, 6)}")
print(f"LCM of 21 and 6: {mathutils.lcm(21, 6)}")