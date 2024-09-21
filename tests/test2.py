def insertion_sort(data: list[int]) -> None:
    for i in range(len(data) - 1):
        key: int = data[i + 1]
        j: int = i
        while j >= 0 and key < data[j]:
            data[j + 1] = data[j]
            j -= 1
        data[j + 1] = key

def find_median(data: list[int]) -> int:
    insertion_sort(data)
    n: int = len(data)
    if n % 2 == 0:
        return (data[n // 2] + data[n // 2 - 1]) / 2
    else:
        return data[n // 2]
    

def find_min(data: list[int]) -> int:
    min_value:int = 999999
    for i in range(len(data)):
        if not min_value:
            min_value = data[i]
        elif data[i] < min_value:
            min_value = data[i]
    return min_value


def find_max(data: list[int]) -> int:
    
    max_value:int = -999999
    for i in range(len(data)):
        if not max_value:
            max_value = data[i]
        elif data[i] > max_value:
            max_value = data[i]
    return max_value


def main():
    data: list[int] = [-2, 45, 0, 12, -9, 23, 45, 67, 89]
    print("Median value: ")
    print(find_median(data))
    print("Minimum value: ")
    print(find_min(data))
    print("Maximum value: ")
    print(find_max(data))
    
    
if __name__ == "__main__":
    main()