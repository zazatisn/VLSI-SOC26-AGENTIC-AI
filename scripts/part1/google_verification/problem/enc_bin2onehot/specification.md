This module is a purely combinational binary-to-one-hot encoder. It converts a 4-bit binary input `in` into a 15-bit one-hot output `out`. The `clk` and `rst` inputs are used for internal simulation assertions and do not affect the core combinational logic.

The operation is qualified by the `in_valid` input signal.

### Functional Description

-   **When `in_valid` is asserted high:** The module decodes the 4-bit value on the `in` bus. The bit in the 15-bit `out` vector corresponding to the decimal value of `in` is set to '1', while all other bits are set to '0'. For example, if `in` is `4'b0101` (decimal 5), the output `out` will be `15'b000000000100000` (bit 5 is high). The valid range for the input `in` is from 0 to 14, inclusive. The behavior is undefined if `in` has a value of 15 while `in_valid` is high.

-   **When `in_valid` is de-asserted low:** The entire `out` bus is driven to all zeros (`15'b0`).