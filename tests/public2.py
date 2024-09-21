def fact(a:int)->int:
    if a==0:
        return 1
    else:
        return a*fact(a-1)
      
      
      
def main():
    a:int = 5
    result:int = fact(a)
    print(result)