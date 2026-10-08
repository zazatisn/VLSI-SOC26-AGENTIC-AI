ALU_8BIT TEST PLAN

TIMING RULES:
- Clock period: 2.5 ns
- Outputs are registered with latency 1 cycle
- Drive inputs (a, b, op) on falling edge
- Outputs update on rising edge
- Check outputs on next falling edge (race-free)
- Never check immediately after rising edge

RESET PHASE:
Vector 0: Reset assertion
  Time: t=0, assert reset=1, hold for 3 clock cycles
  Inputs: a=0, b=0, op=000 (ADD)
  Expected after each cycle: result=0, zero=0, carry=0
  Note: All outputs must remain 0 during reset

SAMPLE VECTORS (from specification):
Vector 1: ADD 200 + 100
  op=000, a=200, b=100
  Computation: (200 + 100) mod 256 = 300 mod 256 = 44; carry = (300 > 255) = 1; zero = (44 == 0) = 0
  Expected: result=44, zero=0, carry=1

Vector 2: SUB 5 - 7
  op=001, a=5, b=7
  Computation: (5 - 7) mod 256 = -2 mod 256 = 254; carry = (5 < 7) = 1; zero = (254 == 0) = 0
  Expected: result=254, zero=0, carry=1

Vector 3: SLT 3 < 9
  op=111, a=3, b=9
  Computation: (3 < 9) = 1; carry = 0; zero = (1 == 0) = 0
  Expected: result=1, zero=0, carry=0

Vector 4: SUB 9 - 9
  op=001, a=9, b=9
  Computation: (9 - 9) mod 256 = 0; carry = (9 < 9) = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

MID-RUN RESET:
Vector 5: Assert reset mid-run with nonzero state
  Inputs before reset: a=255, b=255, op=000 (ADD)
  Assert reset=1 for 2 cycles
  Expected after reset: result=0, zero=0, carry=0

ADD OPERATION (op=000):
Vector 6: ADD 0 + 0
  op=000, a=0, b=0
  Computation: (0 + 0) mod 256 = 0; carry = (0 > 255) = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 7: ADD 255 + 255
  op=000, a=255, b=255
  Computation: (255 + 255) mod 256 = 510 mod 256 = 254; carry = (510 > 255) = 1; zero = (254 == 0) = 0
  Expected: result=254, zero=0, carry=1

Vector 8: ADD 255 + 1
  op=000, a=255, b=1
  Computation: (255 + 1) mod 256 = 256 mod 256 = 0; carry = (256 > 255) = 1; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=1

SUB OPERATION (op=001):
Vector 9: SUB 0 - 0
  op=001, a=0, b=0
  Computation: (0 - 0) mod 256 = 0; carry = (0 < 0) = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 10: SUB 255 - 255
  op=001, a=255, b=255
  Computation: (255 - 255) mod 256 = 0; carry = (255 < 255) = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 11: SUB 0 - 1
  op=001, a=0, b=1
  Computation: (0 - 1) mod 256 = -1 mod 256 = 255; carry = (0 < 1) = 1; zero = (255 == 0) = 0
  Expected: result=255, zero=0, carry=1

AND OPERATION (op=010):
Vector 12: AND 255 & 255
  op=010, a=255, b=255
  Computation: 255 & 255 = 255; carry = 0; zero = (255 == 0) = 0
  Expected: result=255, zero=0, carry=0

Vector 13: AND 0 & 0
  op=010, a=0, b=0
  Computation: 0 & 0 = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 14: AND 255 & 0
  op=010, a=255, b=0
  Computation: 255 & 0 = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

OR OPERATION (op=011):
Vector 15: OR 0 | 0
  op=011, a=0, b=0
  Computation: 0 | 0 = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 16: OR 255 | 0
  op=011, a=255, b=0
  Computation: 255 | 0 = 255; carry = 0; zero = (255 == 0) = 0
  Expected: result=255, zero=0, carry=0

Vector 17: OR 128 | 64
  op=011, a=128, b=64
  Computation: 128 | 64 = 192; carry = 0; zero = (192 == 0) = 0
  Expected: result=192, zero=0, carry=0

XOR OPERATION (op=100):
Vector 18: XOR 255 ^ 255
  op=100, a=255, b=255
  Computation: 255 ^ 255 = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 19: XOR 0 ^ 0
  op=100, a=0, b=0
  Computation: 0 ^ 0 = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 20: XOR 255 ^ 0
  op=100, a=255, b=0
  Computation: 255 ^ 0 = 255; carry = 0; zero = (255 == 0) = 0
  Expected: result=255, zero=0, carry=0

SHL OPERATION (op=101):
Vector 21: SHL 128 << 1
  op=101, a=128, b=0 (b ignored)
  Computation: (128 << 1) mod 256 = 256 mod 256 = 0; carry = a[7] = 1; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=1

Vector 22: SHL 64 << 1
  op=101, a=64, b=0 (b ignored)
  Computation: (64 << 1) mod 256 = 128; carry = a[7] = 0; zero = (128 == 0) = 0
  Expected: result=128, zero=0, carry=0

Vector 23: SHL 255 << 1
  op=101, a=255, b=0 (b ignored)
  Computation: (255 << 1) mod 256 = 510 mod 256 = 254; carry = a[7] = 1; zero = (254 == 0) = 0
  Expected: result=254, zero=0, carry=1

SHR OPERATION (op=110):
Vector 24: SHR 1 >> 1
  op=110, a=1, b=0 (b ignored)
  Computation: 1 >> 1 = 0; carry = a[0] = 1; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=1

Vector 25: SHR 128 >> 1
  op=110, a=128, b=0 (b ignored)
  Computation: 128 >> 1 = 64; carry = a[0] = 0; zero = (64 == 0) = 0
  Expected: result=64, zero=0, carry=0

Vector 26: SHR 255 >> 1
  op=110, a=255, b=0 (b ignored)
  Computation: 255 >> 1 = 127; carry = a[0] = 1; zero = (127 == 0) = 0
  Expected: result=127, zero=0, carry=1

SLT OPERATION (op=111):
Vector 27: SLT 0 < 0
  op=111, a=0, b=0
  Computation: (0 < 0) = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 28: SLT 255 < 255
  op=111, a=255, b=255
  Computation: (255 < 255) = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 29: SLT 255 < 1
  op=111, a=255, b=1
  Computation: (255 < 1) = 0; carry = 0; zero = (0 == 0) = 1
  Expected: result=0, zero=1, carry=0

Vector 30: SLT 1 < 255
  op=111, a=1, b=255
  Computation: (1 < 255) = 1; carry = 0; zero = (1 == 0) = 0
  Expected: result=1, zero=0, carry=0