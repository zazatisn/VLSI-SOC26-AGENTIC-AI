`timescale 1ns/1ps

module tb_cdc_fifo;

    reg push_clk, push_rst;
    reg pop_clk, pop_rst;
    reg push_sender_in_reset;
    reg push_credit_stall;
    reg push_valid;
    reg pop_ready;
    reg [7:0] push_data;
    reg [4:0] credit_initial_push;
    reg [4:0] credit_withhold_push;

    wire push_receiver_in_reset;
    wire push_credit;
    wire pop_valid;
    wire push_full;
    wire pop_empty;
    wire [7:0] pop_data;
    wire [4:0] push_slots;
    wire [4:0] credit_count_push;
    wire [4:0] credit_available_push;
    wire [4:0] pop_items;

    integer i;

    cdc_fifo_flops_push_credit uut (
        .push_clk(push_clk),
        .push_rst(push_rst),
        .pop_clk(pop_clk),
        .pop_rst(pop_rst),
        .push_sender_in_reset(push_sender_in_reset),
        .push_receiver_in_reset(push_receiver_in_reset),
        .push_credit_stall(push_credit_stall),
        .push_credit(push_credit),
        .push_valid(push_valid),
        .pop_ready(pop_ready),
        .pop_valid(pop_valid),
        .push_full(push_full),
        .pop_empty(pop_empty),
        .push_data(push_data),
        .pop_data(pop_data),
        .push_slots(push_slots),
        .credit_initial_push(credit_initial_push),
        .credit_withhold_push(credit_withhold_push),
        .credit_count_push(credit_count_push),
        .credit_available_push(credit_available_push),
        .pop_items(pop_items)
    );

    always #5 push_clk = ~push_clk;
    always #7 pop_clk = ~pop_clk;

    initial begin
        push_clk = 0; pop_clk = 0;
        push_rst = 1; pop_rst = 1;
        push_sender_in_reset = 0; push_credit_stall = 0;
        push_valid = 0; pop_ready = 0;
        push_data = 0; 
        credit_initial_push = 17; 
        credit_withhold_push = 2;

        #100 push_rst = 0; pop_rst = 0;
        repeat(20) @(posedge push_clk);
        
        // Push 15 items (Capacity 17, withheld 2 => 15 available)
        for (i = 0; i < 15; i = i + 1) begin
            @(posedge push_clk);
            if (credit_available_push > 0) begin
                push_valid <= 1;
                push_data <= i[7:0];
                @(posedge push_clk);
                push_valid <= 0;
            end
        end
        
        repeat(50) @(posedge push_clk);
        
        // Verify FIFO shows status of full
        if (push_full !== 1) begin 
            $display("TEST FAILED: FIFO should be full. Available: %d", credit_available_push); 
            $finish; 
        end

        // Perform read
        @(posedge pop_clk);
        if (pop_empty) begin
            $display("TEST FAILED: FIFO should not be empty.");
            $finish;
        end
        pop_ready <= 1;
        @(posedge pop_clk);
        pop_ready <= 0;
        
        // Wait for credit return
        repeat(100) @(posedge push_clk);
        
        if (push_full !== 0) begin 
            $display("TEST FAILED: FIFO full flag failed to clear after pop."); 
            $finish; 
        end

        // Test Reset Handshake
        push_sender_in_reset <= 1;
        repeat(10) @(posedge push_clk);
        if (push_receiver_in_reset !== 1) begin 
            $display("TEST FAILED: Reset handshake not asserted."); 
            $finish; 
        end
        
        push_sender_in_reset <= 0;
        repeat(10) @(posedge push_clk);
        
        $display("TEST PASSED");
        $finish;
    end
endmodule