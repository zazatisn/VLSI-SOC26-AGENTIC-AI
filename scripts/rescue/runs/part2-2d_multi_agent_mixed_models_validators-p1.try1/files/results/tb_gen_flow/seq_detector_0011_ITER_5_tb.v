`timescale 1ns/1ps

module tb;
    reg clk;
    reg reset;
    reg data_in;
    wire detected;

    integer i;
    reg inputs[0:15];
    reg outputs[0:15];

    seq_detector_0011 dut(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .detected(detected)
    );

    initial begin
        clk = 0;
        // Sample input: 0001100110110010
        inputs[0]=0; inputs[1]=0; inputs[2]=0; inputs[3]=1; 
        inputs[4]=1; inputs[5]=0; inputs[6]=0; inputs[7]=1; 
        inputs[8]=1; inputs[9]=0; inputs[10]=1; inputs[11]=1; 
        inputs[12]=0; inputs[13]=0; inputs[14]=1; inputs[15]=0;
        
        // Sample output: 0000010001000000
        outputs[0]=0; outputs[1]=0; outputs[2]=0; outputs[3]=0; 
        outputs[4]=0; outputs[5]=1; outputs[6]=0; outputs[7]=0; 
        outputs[8]=1; outputs[9]=0; outputs[10]=0; outputs[11]=0; 
        outputs[12]=0; outputs[13]=0; outputs[14]=0; outputs[15]=0;
    end

    always #0.55 clk = ~clk;

    initial begin
        reset = 1;
        data_in = 0;
        
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 16; i = i + 1) begin
            // Check detected at falling edge before driving data_in
            if (detected === outputs[i]) begin
                $display("TEST: PASS | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
            end else begin
                $display("TEST: FAIL | Inputs: [data_in=%b] | Expected: [%b] | Output: [%b]", data_in, outputs[i], detected);
            end
            data_in = inputs[i];
            @(negedge clk);
        end

        // Final check after last sequence processing
        if (detected === 1'b0) begin
            $display("TEST: PASS | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [FINAL] | Expected: [0] | Output: [%b]", detected);
        end

        // Corner Case: Mid-sequence reset
        data_in = 0; @(negedge clk); // sequence 0
        data_in = 0; @(negedge clk); // 00
        data_in = 1; @(negedge clk); // 001
        reset = 1; @(negedge clk);
        if (detected === 1'b0) begin
            $display("TEST: PASS | Inputs: [RESET_MID] | Expected: [0] | Output: [%b]", detected);
        end else begin
            $display("TEST: FAIL | Inputs: [RESET_MID] | Expected: [0] | Output: [%b]", detected);
        end
        
        $finish;
    end
endmodule