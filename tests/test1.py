class ArrayFamilia:
    def __init__(self, arr: list[int]) -> None:
        self.arr: list[int] = arr

    def ReverseArray(self) -> list[int]:
        n: int = len(self.arr)
        for i in range(n // 2):
            temp: int = self.arr[i]
            self.arr[i] = self.arr[n - i - 1]
            self.arr[n - i - 1] = temp
            
    # do not use two arguments in range func
    def insertion_sort(self) -> None:
        for i in range(len(self.arr) - 1):
            key: int = self.arr[i + 1]
            j: int = i
            while j >= 0 and key < self.arr[j]:
                self.arr[j + 1] = self.arr[j]
                j -= 1
            self.arr[j + 1] = key


    def PrintArray(self) -> None:
        for i in range(len(self.arr)):
            print(self.arr[i])

def main() -> None:
    # using class
    listt: list[int] = [-2, 45, 0, 12, -9]
    data:ArrayFamilia = ArrayFamilia(listt)
    data.ReverseArray()
    
    print("Reversed Array:")
    data.PrintArray()
    
    data.insertion_sort()
    print("Sorted Array:")
    data.PrintArray()
    
    
    
if __name__ == "__main__":
    main()
    