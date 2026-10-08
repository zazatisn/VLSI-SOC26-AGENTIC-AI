`timescale 1ns/1ps

module tb_seq_detector;

reg clk;
reg reset;
reg data_in;
wire detected;

reg [15:0] inputs = 16'b0001100110110010;
reg [15:0] expected = 16'b0000010001000000;
integer i;

seq_detector_0011 uut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .detected(detected)
);

initial begin
    clk = 0;
    forever #0.55 clk = ~clk;
end

initial begin
    reset = 1;
    data_in = 0;

    // Reset sequence: 2 rising edges, release on falling
    repeat(2) @(posedge clk);
    @(negedge clk);
    reset = 0;

    // Sample Case
    for (i = 0; i < 16; i = i + 1) begin
        @(negedge clk);
        if (detected === expected[i]) begin
            $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected[i], detected);
        end else begin
            $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, expected[i], detected);
        end
        data_in = inputs[i];
    end

    // Overlap Test: 00110011 -> Detected at index 3 and 7 (1-based index 4 and 8)
    // Sequence: 0 0 1 1 0 0 1 1
    // Expected: 0 0 0 1 0 0 0 1
    reset = 1;
    @(negedge clk);
    reset = 0;
    data_in = 0;
    
    // Manual sequence 00110011
    repeat(8) begin
        @(negedge clk);
        // Logic for expected here matches sequence
        // Index 3 and 7 (0-indexed) are where output should be high
        if (detected === ((i == 3) || (i == 7))) begin
             $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, (i==3 || i==7), detected);
        end else begin
             $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, (i==3 || i==7), detected);
        end
        // Drive data for next cycle
        case (i)
            0: data_in = 0;
            1: data_in = 0;
            2: data_in = 1;
            3: data_in = 1;
            4: data_in = 0;
            5: data_in = 0;
            6: data_in = 1;
            7: data_in = 1;
        endcase
        i = i + 1;
    end

    $finish;
end

endmodule