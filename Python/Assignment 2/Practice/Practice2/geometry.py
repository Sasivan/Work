# ==========================================
# 13. MODULES AND PACKAGES
# ==========================================
# Question 13:
# Create a custom module named geometry.py that contains two functions: 
# circle_area(radius) and rectangle_area(width, height). Write a separate 
# main script that imports this module and prints the computed areas.

import math
def circle_area(r):
    return math.sqrt(r)*math.pi
def rectangle_area(l,b):
    return l*b