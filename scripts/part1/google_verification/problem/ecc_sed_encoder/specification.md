This module is a combinational single-error-detecting (SED) even parity encoder. It takes a 12-bit data message and produces a 13-bit codeword.

### Interface Description

*   **`clk`**: A positive edge-triggered clock input.
*   **`rst`**: A synchronous, active-high reset input.
*   **`data_valid`**: A 1-bit input that indicates the `data` input is valid for the current cycle.
*   **`data`**: A 12-bit input data message to be encoded.
*   **`enc_valid`**: A 1-bit output that indicates the `enc_codeword` output is valid.
*   **`enc_codeword`**: A 13-bit output containing the encoded codeword.

### Functional Description

The module operates combinationally, with no latency from input to output. The `clk` and `rst` inputs do not affect the core encoding logic.

When the `data_valid` input is asserted high, the module performs the following actions:
1.  It calculates a single even parity bit by performing an XOR reduction on all 12 bits of the input `data`.
2.  It forms a 13-bit `enc_codeword` by prepending the calculated parity bit to the original 12-bit `data`. The most significant bit (MSB) of `enc_codeword` (`enc_codeword[12]`) is the parity bit, and the lower 12 bits (`enc_codeword[11:0]`) are a direct copy of the input `data`.
3.  The resulting `enc_codeword` is guaranteed to have an even number of bits set to '1'.
4.  The `enc_valid` output is asserted high, directly following the state of `data_valid`.

When `data_valid` is low, `enc_valid` is also low, and the value of `enc_codeword` is not guaranteed.