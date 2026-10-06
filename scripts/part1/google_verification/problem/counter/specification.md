This module implements a synchronous, up/down counter that operates on the rising edge of the `clk` input.

### Initialization

Upon a synchronous, active-high `rst`, the counter's output `value` is loaded with the value provided on the `initial_value` input.

A separate active-high `reinit` signal also synchronously loads the counter with `initial_value`. When `reinit` is asserted, any concurrent increment or decrement requests are ignored, and the counter's next state will be `initial_value`.

### Operation

The counter's state can be modified on each clock cycle based on the `incr_valid` and `decr_valid` signals.
- If `incr_valid` is high, the counter value is incremented by the amount specified by the `incr` input.
- If `decr_valid` is high, the counter value is decremented by the amount specified by the `decr` input.
- If both `incr_valid` and `decr_valid` are asserted in the same cycle, the net change (`incr` - `decr`) is applied to the current counter value.
- If neither `incr_valid` nor `decr_valid` is asserted, the counter holds its current value.

The maximum value for both `incr` and `decr` is 3.

### Counting Range and Wrap-Around

The counter operates within an inclusive range of 0 to 10. It is configured to wrap around on overflow and underflow.
- **Overflow:** If an increment operation results in a value greater than 10, the value wraps around. For example, if the current `value` is 9 and it is incremented by 3, the `value_next` will be 1.
- **Underflow:** If a decrement operation results in a value less than 0, the value wraps around from the maximum. For example, if the current `value` is 1 and it is decremented by 3, the `value_next` will be 9.

### Outputs

The module provides two outputs representing the counter's state:
- `value`: The registered state of the counter. This output has a one-cycle latency and reflects the result of the operations from the previous clock cycle.
- `value_next`: A combinational signal that indicates the value that the counter will hold on the next rising edge of `clk`. It is calculated based on the current `value` and the `reinit`, `incr`, and `decr` control inputs. This output is useful for logic that requires the next-cycle state without a clock delay.