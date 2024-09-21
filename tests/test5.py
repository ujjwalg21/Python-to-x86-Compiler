def is_prime(n:int)->bool:
    if n < 2:
        return False
    for i in range(n-3):
        if n % (i+2) == 0:
            return False
    return True


def is_odd(n:int)->bool:
    return n % 2 != 0


def is_even(n:int)->bool:
    return n % 2 == 0


def calculate_factorial(n:int)->int:
    if n == 0:
        return 1
    else:
        return n * calculate_factorial(n - 1)
    
    
def main():
    if(is_prime(7)):
        print("Prime")
        
    if(is_odd(7)):
        print("Odd")
    
    if(is_even(7)):
        print("Even")
    
    print(calculate_factorial(7))

    
    
if(__name__ == "__main__"):
    main()