`timescale 1ns/1ps

module tb_cdc_fifo_flops_push_credit();

  // Clock and reset signals
  reg push_clk;
  reg pop_clk;
  reg push_rst;
  reg pop_rst;
  
  // Push-side interface
  reg push_sender_in_reset;
  reg push_valid;
  reg [7:0] push_data;
  reg push_credit_stall;
  
  // Pop-side interface
  reg pop_ready;
  
  // Credit and status inputs
  reg [4:0] credit_initial_push;
  reg [4:0] credit_withhold_push;
  
  // Output signals
  wire push_receiver_in_reset;
  wire push_credit;
  wire pop_valid;
  wire [7:0] pop_data;
  wire push_full;
  wire pop_empty;
  wire [4:0] push_slots;
  wire [4:0] credit_count_push;
  wire [4:0] credit_available_push;
  wire [4:0] pop_items;
  
  // Test variables
  integer i;
  integer j;
  integer credit_count;
  integer items_written;
  integer items_read;
  
  // Instantiate the Unit Under Test
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
  
  // Clock generation
  initial begin
    push_clk = 0;
    forever #5 push_clk = ~push_clk;
  end
  
  initial begin
    pop_clk = 0;
    forever #7 pop_clk = ~pop_clk;
  end
  
  // Main test procedure
  initial begin
    // Initialize all signals
    push_rst = 1;
    pop_rst = 1;
    push_sender_in_reset = 0;
    push_valid = 0;
    push_data = 8'h00;
    push_credit_stall = 0;
    pop_ready = 0;
    credit_initial_push = 5'd17;
    credit_withhold_push = 5'd0;
    
    // Wait for initial reset to settle
    #100;
    
    // Release resets
    push_rst = 0;
    pop_rst = 0;
    #100;
    
    // Test 1: Verify initial state after reset
    // After reset, FIFO should be empty
    if (pop_empty !== 1'b1) begin
      $display("TEST FAILED: pop_empty should be high after reset");
      $finish;
    end
    if (push_full !== 1'b0) begin
      $display("TEST FAILED: push_full should be low after reset");
      $finish;
    end
    #50;
    
    // Test 2: Write one item and verify it appears on pop side
    push_valid = 1;
    push_data = 8'hAA;
    #10;
    push_valid = 0;
    #100; // Allow time for data to propagate through CDC
    
    // After write, pop_empty should eventually be low (data available)
    if (pop_empty !== 1'b0) begin
      $display("TEST FAILED: pop_empty should be low after write");
      $finish;
    end
    
    // Verify pop_valid is high and pop_data is correct
    if (pop_valid !== 1'b1) begin
      $display("TEST FAILED: pop_valid should be high when data is available");
      $finish;
    end
    if (pop_data !== 8'hAA) begin
      $display("TEST FAILED: pop_data mismatch, expected 8'hAA, got 8'h%02X", pop_data);
      $finish;
    end
    #50;
    
    // Test 3: Read the item and verify FIFO becomes empty
    pop_ready = 1;
    #20; // Wait for read to complete
    pop_ready = 0;
    #150; // Allow time for status to propagate back through CDC
    
    // After read, pop_empty should be high again
    if (pop_empty !== 1'b1) begin
      $display("TEST FAILED: pop_empty should be high after reading last item");
      $finish;
    end
    #50;
    
    // Test 4: Multiple writes and reads
    items_written = 0;
    items_read = 0;
    
    // Write 5 items
    for (i = 0; i < 5; i = i + 1) begin
      push_valid = 1;
      push_data = 8'h10 + i;
      #10;
      push_valid = 0;
      #10;
      items_written = items_written + 1;
    end
    
    #100; // Allow time for data to propagate
    
    // Read 5 items
    for (i = 0; i < 5; i = i + 1) begin
      if (pop_valid !== 1'b1) begin
        $display("TEST FAILED: pop_valid should be high for item %d", i);
        $finish;
      end
      
      if (pop_data !== (8'h10 + i)) begin
        $display("TEST FAILED: pop_data mismatch at item %d, expected 8'h%02X, got 8'h%02X", 
                 i, (8'h10 + i), pop_data);
        $finish;
      end
      
      pop_ready = 1;
      #20;
      pop_ready = 0;
      #50;
      items_read = items_read + 1;
    end
    
    #150; // Allow time for status to propagate
    
    // Verify FIFO is empty after reading all items
    if (pop_empty !== 1'b1) begin
      $display("TEST FAILED: pop_empty should be high after reading all items");
      $finish;
    end
    #50;
    
    // Test 5: Test push_sender_in_reset
    push_sender_in_reset = 1;
    #50;
    
    // push_receiver_in_reset should reflect sender reset (with some delay)
    if (push_receiver_in_reset !== 1'b1) begin
      $display("TEST FAILED: push_receiver_in_reset should be high when push_sender_in_reset is high");
      $finish;
    end
    #50;
    
    push_sender_in_reset = 0;
    #100;
    
    // Test 6: Test push_rst assertion
    push_valid = 1;
    push_data = 8'hCC;
    #10;
    push_valid = 0;
    #50;
    
    // Assert push_rst
    push_rst = 1;
    #50;
    
    // After reset, push_receiver_in_reset should be high
    if (push_receiver_in_reset !== 1'b1) begin
      $display("TEST FAILED: push_receiver_in_reset should be high after push_rst");
      $finish;
    end
    #50;
    
    push_rst = 0;
    #100;
    
    // Test 7: Test credit stalling mechanism
    // Write an item
    push_valid = 1;
    push_data = 8'hDD;
    #10;
    push_valid = 0;
    #100; // Allow data to propagate
    
    // Assert credit stall and read
    push_credit_stall = 1;
    pop_ready = 1;
    #20;
    pop_ready = 0;
    #200; // Wait longer to see if credit is stalled
    
    // With stall, credit should not be returned (or should be low)
    // Note: We check the state after stall is released
    push_credit_stall = 0;
    #200; // Allow time for credit to propagate if stall was blocking it
    
    // After releasing stall, FIFO should eventually return to empty state
    if (pop_empty !== 1'b1) begin
      $display("TEST FAILED: pop_empty should be high after credit stall test");
      $finish;
    end
    #50;
    
    // Test 8: Verify credit_available_push calculation
    // With credit_initial_push = 17 and credit_withhold_push = 0
    // credit_available_push should equal credit_count_push
    if (credit_available_push !== credit_count_push) begin
      $display("TEST FAILED: credit_available_push should equal credit_count_push when withhold is 0");
      $finish;
    end
    #50;
    
    // Test 9: Test with credit withholding
    pop_rst = 1;
    push_rst = 1;
    #50;
    pop_rst = 0;
    push_rst = 0;
    credit_withhold_push = 5'd5;
    #100;
    
    // credit_available_push should be credit_count_push - credit_withhold_push
    if (credit_available_push !== (credit_count_push - credit_withhold_push)) begin
      $display("TEST FAILED: credit_available_push calculation incorrect with withhold");
      $finish;
    end
    #50;
    
    // All tests passed
    $display("TEST PASSED");
    $finish;
  end

endmodule