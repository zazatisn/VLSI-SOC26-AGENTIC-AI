TEST PLAN NOTES FOR seq_detector_0011

1. RESET SEQUENCE
   - At time 0: clk=0, reset=1, data_in=1
   - Hold reset=1 for 2 rising edges of clk
   - Release reset to 0 on a falling edge (after 2nd rising edge)
   - Keep data_in=1 until the next falling edge after reset release

2. STORAGE DECLARATIONS
   - reg [0:15] in_bits = 16'b0001100110110010;
   - reg [0:15] exp_bits = 16'b0000010001000000;
   - Use !== for all comparisons

3. CHECK AND DRIVE SCHEDULE
   For i = 0 to 15, on each falling edge:
   - First: check detected !== exp_bits[i], print result
   - Then: drive data_in = in_bits[i]
   After i=15 completes, wait one more falling edge and $finish

4. PRINT FORMAT
   TEST: PASS | Inputs: data_in=<v> idx=<i> | Expected: <e> | Output: <o>
   or
   TEST: FAIL | Inputs: data_in=<v> idx=<i> | Expected: <e> | Output: <o>

5. INPUT AND EXPECTED OUTPUT TABLE
   idx | in_bits[i] | exp_bits[i]
   ----|------------|------------
    0  |     0      |      0
    1  |     0      |      0
    2  |     0      |      0
    3  |     1      |      0
    4  |     1      |      0
    5  |     0      |      1
    6  |     0      |      0
    7  |     1      |      0
    8  |     1      |      0
    9  |     0      |      1
   10  |     1      |      0
   11  |     1      |      0
   12  |     0      |      0
   13  |     0      |      0
   14  |     1      |      0
   15  |     0      |      0

6. EXPECTED DETECTIONS
   - Detection at idx=5: after sampling "0011" (indices 2,3,4,5 = 0,0,1,1)
   - Detection at idx=9: after sampling "0011" (indices 6,7,8,9 = 0,0,1,1)
   - No other detections in this sequence

7. TIMING NOTES
   - detected is a Moore output (depends only on FSM state)
   - detected is high for exactly ONE cycle after the rising edge that samples the last '1'
   - Overlapping sequences are detected
   - All checks occur on falling edges, never at or immediately after rising edges
   - No timescale directive needed
   - No SystemVerilog constructs