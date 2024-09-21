def bitwise_operations(a: int, b: int) -> list[int]:
  # Bitwise AND
  result_and: int = a & b
  # Bitwise OR
  result_or: int = a | b

  # # Bitwise XOR
  result_xor: int = a ^ b
  # k:list[int] = [result_and]

  # Bitwise NOT (complement)
  result_not_a: int = ~a
  result_not_b: int = ~b

  # Bitwise Left Shift
  result_left_shift_a: int = a << 1
  result_left_shift_b: int = b << 1

  # Bitwise Right Shift
  result_right_shift_a: int = a >> 1
  result_right_shift_b: int = b >> 1

  k: list[int] = [
    result_and, result_or, result_xor, result_not_a, result_not_b, result_left_shift_a,
    result_left_shift_b, result_right_shift_a, result_right_shift_b
  ]
  return k


def main():
  num1: int = 851785
  num2: int = 5

  results: list[int] = bitwise_operations(num1, num2)
  a: list[int] = [1, 7, 3]
  i: int = 0
  k: int = len(results)

  for i in range(len(results)):
    print(results[i])


if __name__ == "__main__":
  main()
