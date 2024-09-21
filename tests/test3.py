
def binary_search(data: list[int], key: int) -> int:
    low: int = 0
    high: int = len(data) - 1
    while low <= high:
        mid: int = low + (high - low) // 2
        if data[mid] == key:
            return mid
        elif data[mid] < key:
            low = mid + 1
        else:
            high = mid - 1
    return -1


def main():
    data: list[int] = [2, 3, 4, 10, 40]
    key: int = 10
    result: int = binary_search(data, key)
    if result != -1:
        print("Element is present at index:")
        print(result)
    else:
        print("Element is not present in array")
        
        
if __name__ == "__main__":
    main()