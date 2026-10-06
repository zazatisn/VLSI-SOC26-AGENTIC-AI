`timescale 1ns/1ps

module tb_fifo_flops();

  // Testbench signals
  reg clk;
  reg rst;
  reg push_valid;
  reg pop_ready;
  reg [7:0] push_data;
  
  wire push_ready;
  wire pop_valid;
  wire full;
  wire full_next;
  wire empty;
  wire empty_next;
  wire [7:0] pop_data;
  wire [3:0] slots;
  wire [3:0] slots_next;
  wire [3:0] items;
  wire [3:0] items_next;
  
  integer i;
  integer test_count;
  integer pass_count;

  // Instantiate the Unit Under Test (UUT)
  fifo_flops uut (
    .clk(clk),
    .rst(rst),
    .push_ready(push_ready),
    .push_valid(push_valid),
    .pop_ready(pop_ready),
    .pop_valid(pop_valid),
    .full(full),
    .full_next(full_next),
    .empty(empty),
    .empty_next(empty_next),
    .push_data(push_data),
    .pop_data(pop_data),
    .slots(slots),
    .slots_next(slots_next),
    .items(items),
    .items_next(items_next)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Main test procedure
  initial begin
    test_count = 0;
    pass_count = 0;

    // ===== TEST 1: Reset Behavior =====
    test_count = test_count + 1;
    rst = 1;
    push_valid = 0;
    pop_ready = 0;
    push_data = 8'h00;
    @(posedge clk);
    @(posedge clk);
    
    if (empty !== 1'b1) begin
      $display("TEST FAILED: After reset, empty should be 1, got %b", empty);
      $finish;
    end
    if (full !== 1'b0) begin
      $display("TEST FAILED: After reset, full should be 0, got %b", full);
      $finish;
    end
    if (items !== 4'h0) begin
      $display("TEST FAILED: After reset, items should be 0, got %h", items);
      $finish;
    end
    if (slots !== 4'hD) begin
      $display("TEST FAILED: After reset, slots should be 13 (0xD), got %h", slots);
      $finish;
    end
    if (pop_valid !== 1'b0) begin
      $display("TEST FAILED: After reset, pop_valid should be 0, got %b", pop_valid);
      $finish;
    end
    if (push_ready !== 1'b1) begin
      $display("TEST FAILED: After reset, push_ready should be 1, got %b", push_ready);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 1 - Reset behavior");

    // ===== TEST 2: Bypass Mode (Push + Pop simultaneously when empty) =====
    test_count = test_count + 1;
    rst = 0;
    push_valid = 1;
    pop_ready = 1;
    push_data = 8'hAA;
    @(posedge clk);
    #1;
    
    if (pop_valid !== 1'b1) begin
      $display("TEST FAILED: In bypass mode, pop_valid should be 1, got %b", pop_valid);
      $finish;
    end
    if (pop_data !== 8'hAA) begin
      $display("TEST FAILED: In bypass mode, pop_data should be 0xAA, got %h", pop_data);
      $finish;
    end
    if (items !== 4'h0) begin
      $display("TEST FAILED: In bypass mode with simultaneous push/pop, items should be 0, got %h", items);
      $finish;
    end
    if (empty !== 1'b1) begin
      $display("TEST FAILED: In bypass mode with simultaneous push/pop, empty should be 1, got %b", empty);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 2 - Bypass mode");

    // ===== TEST 3: Bypass mode with different data values =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 1;
    push_data = 8'h55;
    @(posedge clk);
    #1;
    
    if (pop_data !== 8'h55) begin
      $display("TEST FAILED: Bypass with 0x55, pop_data should be 0x55, got %h", pop_data);
      $finish;
    end
    if (pop_valid !== 1'b1) begin
      $display("TEST FAILED: Bypass with 0x55, pop_valid should be 1, got %b", pop_valid);
      $finish;
    end
    
    push_data = 8'hCC;
    @(posedge clk);
    #1;
    
    if (pop_data !== 8'hCC) begin
      $display("TEST FAILED: Bypass with 0xCC, pop_data should be 0xCC, got %h", pop_data);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 3 - Bypass mode with different data values");

    // ===== TEST 4: Push without pop (buffered mode) =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 0;
    push_data = 8'h11;
    @(posedge clk);
    #1;
    
    if (items !== 4'h1) begin
      $display("TEST FAILED: After 1 push, items should be 1, got %h", items);
      $finish;
    end
    if (empty !== 1'b0) begin
      $display("TEST FAILED: After 1 push, empty should be 0, got %b", empty);
      $finish;
    end
    if (pop_valid !== 1'b1) begin
      $display("TEST FAILED: After 1 push, pop_valid should be 1, got %b", pop_valid);
      $finish;
    end
    if (pop_data !== 8'h11) begin
      $display("TEST FAILED: After 1 push, pop_data should be 0x11, got %h", pop_data);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 4 - Push without pop (buffered mode)");

    // ===== TEST 5: Continue pushing to fill FIFO =====
    test_count = test_count + 1;
    push_valid = 1;
    pop_ready = 0;
    for (i = 0; i < 12; i = i + 1) begin
      push_data = 8'h20 + i;
      @(posedge clk);
    end
    #1;
    
    if (full !== 1'b1) begin
      $display("TEST FAILED: After filling FIFO, full should be 1, got %b", full);
      $finish;
    end
    if (items !== 4'hD) begin
      $display("TEST FAILED: After filling FIFO, items should be 13 (0xD), got %h", items);
      $finish;
    end
    if (push_ready !== 1'b0) begin
      $display("TEST FAILED: When full, push_ready should be 0, got %b", push_ready);
      $finish;
    end
    if (slots !== 4'h0) begin
      $display("TEST FAILED: When full, slots should be 0, got %h", slots);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 5 - Fill FIFO to capacity");

    // ===== TEST 6: Pop from full FIFO =====
    test_count = test_count + 1;
    push_valid = 0;
    pop_ready = 1;
    @(posedge clk);
    #1;
    
    if (items !== 4'hC) begin
      $display("TEST FAILED: After 1 pop from full, items should be 12 (0xC), got %h", items);
      $finish;
    end
    if (full !== 1'b0) begin
      $display("TEST FAILED: After 1 pop from full, full should be 0, got %b", full);
      $finish;
    end
    if (slots !== 4'h1) begin
      $display("TEST FAILED: After 1 pop from full, slots should be 1, got %h", slots);
      $finish;
    end
    if (pop_valid !== 1'b1) begin
      $display("TEST FAILED: After 1 pop from full, pop_valid should still be 1, got %b", pop_valid);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 6 - Pop from full FIFO");

    // ===== TEST 7: Drain FIFO completely =====
    test_count = test_count + 1;
    push_valid = 0;
    pop_ready = 1;
    for (i = 0; i < 12; i = i + 1) begin
      @(posedge clk);
    end
    #1;
    
    if (empty !== 1'b1) begin
      $display("TEST FAILED: After draining FIFO, empty should be 1, got %b", empty);
      $finish;
    end
    if (items !== 4'h0) begin
      $display("TEST FAILED: After draining FIFO, items should be 0, got %h", items);
      $finish;
    end
    if (pop_valid !== 1'b0) begin
      $display("TEST FAILED: When empty, pop_valid should be 0, got %b", pop_valid);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 7 - Drain FIFO completely");

    // ===== TEST 8: Simultaneous push and pop in buffered mode =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 0;
    push_data = 8'h55;
    @(posedge clk);
    #1;
    
    if (items !== 4'h1) begin
      $display("TEST FAILED: After 1 push, items should be 1, got %h", items);
      $finish;
    end
    
    push_valid = 1;
    pop_ready = 1;
    push_data = 8'h66;
    @(posedge clk);
    #1;
    
    if (items !== 4'h1) begin
      $display("TEST FAILED: With simultaneous push/pop, items should remain 1, got %h", items);
      $finish;
    end
    if (pop_data !== 8'h55) begin
      $display("TEST FAILED: With simultaneous push/pop, pop_data should be old data (0x55), got %h", pop_data);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 8 - Simultaneous push and pop in buffered mode");

    // ===== TEST 9: Push when FIFO full (should be rejected) =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 0;
    for (i = 0; i < 13; i = i + 1) begin
      push_data = 8'h30 + i;
      @(posedge clk);
    end
    #1;
    
    if (full !== 1'b1) begin
      $display("TEST FAILED: FIFO should be full, got full=%b", full);
      $finish;
    end
    
    push_valid = 1;
    pop_ready = 0;
    push_data = 8'hFF;
    @(posedge clk);
    #1;
    
    if (items !== 4'hD) begin
      $display("TEST FAILED: When full, push should be rejected, items should be 13, got %h", items);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 9 - Push when FIFO full");

    // ===== TEST 10: Pop when FIFO empty =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 0;
    pop_ready = 1;
    @(posedge clk);
    #1;
    
    if (pop_valid !== 1'b0) begin
      $display("TEST FAILED: When empty, pop_valid should be 0, got %b", pop_valid);
      $finish;
    end
    if (items !== 4'h0) begin
      $display("TEST FAILED: When empty, items should be 0, got %h", items);
      $finish;
    end
    pass_count = pass_count + 1;
    $display("PASS: Test 10 - Pop when FIFO empty");

    // ===== TEST 11: Multiple push/pop cycles =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    
    for (i = 0; i < 3; i = i + 1) begin
      push_valid = 1;
      pop_ready = 0;
      push_data = 8'h40 + i;
      @(posedge clk);
    end
    #1;
    
    if (items !== 4'h3) begin
      $display("TEST FAILED: After 3 pushes, items should be 3, got %h", items);
      $finish;
    end
    
    push_valid = 0;
    pop_ready = 1;
    @(posedge clk);
    @(posedge clk);
    #1;
    
    if (items !== 4'h1) begin
      $display("TEST FAILED: After 2 pops, items should be 1, got %h", items);
      $finish;
    end
    
    push_valid = 1;
    pop_ready = 0;
    push_data = 8'h50;
    @(posedge clk);
    push_data = 8'h51;
    @(posedge clk);
    #1;
    
    if (items != 4'h3) begin
      $display("TEST FAILED: After 2 more pushes, items should be 3, got %h", items);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 11 - Multiple push/pop cycles");

    // ===== TEST 12: Verify pop_valid de-assertion when draining =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 0;
    push_data = 8'hDD;
    @(posedge clk);
    #1;
    
    if (pop_valid !== 1'b1) begin
      $display("TEST FAILED: After 1 push, pop_valid should be 1, got %b", pop_valid);
      $finish;
    end
    
    push_valid = 0;
    pop_ready = 1;
    @(posedge clk);
    #1;
    
    if (pop_valid !== 1'b0) begin
      $display("TEST FAILED: After popping last item, pop_valid should be 0, got %b", pop_valid);
      $finish;
    end
    if (empty !== 1'b1) begin
      $display("TEST FAILED: After popping last item, empty should be 1, got %b", empty);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 12 - Verify pop_valid de-assertion when draining");

    // ===== TEST 13: Alternating push/pop pattern =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    
    for (i = 0; i < 5; i = i + 1) begin
      push_valid = 1;
      pop_ready = 0;
      push_data = 8'h70 + i;
      @(posedge clk);
      
      push_valid = 0;
      pop_ready = 1;
      @(posedge clk);
    end
    #1;
    
    if (empty !== 1'b1) begin
      $display("TEST FAILED: After alternating push/pop, FIFO should be empty, got empty=%b", empty);
      $finish;
    end
    if (items !== 4'h0) begin
      $display("TEST FAILED: After alternating push/pop, items should be 0, got %h", items);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 13 - Alternating push/pop pattern");

    // ===== TEST 14: Verify slots calculation =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 0;
    for (i = 0; i < 5; i = i + 1) begin
      push_data = 8'h80 + i;
      @(posedge clk);
    end
    #1;
    
    if (items != 4'h5) begin
      $display("TEST FAILED: After 5 pushes, items should be 5, got %h", items);
      $finish;
    end
    if (slots != 4'h8) begin
      $display("TEST FAILED: After 5 pushes, slots should be 8 (13-5), got %h", slots);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 14 - Verify slots calculation");

    // ===== TEST 15: Transition from bypass to buffered mode =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    
    // First: bypass mode (empty, push and pop both valid)
    push_valid = 1;
    pop_ready = 1;
    push_data = 8'hAA;
    @(posedge clk);
    #1;
    
    if (pop_data !== 8'hAA) begin
      $display("TEST FAILED: Bypass should pass 0xAA, got %h", pop_data);
      $finish;
    end
    if (items !== 4'h0) begin
      $display("TEST FAILED: Bypass with simultaneous push/pop should keep items=0, got %h", items);
      $finish;
    end
    
    // Now: push without pop (enter buffered mode)
    push_valid = 1;
    pop_ready = 0;
    push_data = 8'hBB;
    @(posedge clk);
    #1;
    
    if (items !== 4'h1) begin
      $display("TEST FAILED: After push without pop, items should be 1, got %h", items);
      $finish;
    end
    if (pop_data !== 8'hBB) begin
      $display("TEST FAILED: In buffered mode, pop_data should be 0xBB, got %h", pop_data);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 15 - Transition from bypass to buffered mode");

    // ===== TEST 16: Nearly full FIFO (12 items) =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 1;
    pop_ready = 0;
    for (i = 0; i < 12; i = i + 1) begin
      push_data = 8'h60 + i;
      @(posedge clk);
    end
    #1;
    
    if (items != 4'hC) begin
      $display("TEST FAILED: After 12 pushes, items should be 12, got %h", items);
      $finish;
    end
    if (full != 1'b0) begin
      $display("TEST FAILED: With 12 items, full should be 0, got %b", full);
      $finish;
    end
    if (push_ready != 1'b1) begin
      $display("TEST FAILED: With 12 items, push_ready should be 1, got %b", push_ready);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 16 - Nearly full FIFO (12 items)");

    // ===== TEST 17: Verify empty_next and full_next =====
    test_count = test_count + 1;
    rst = 1;
    @(posedge clk);
    rst = 0;
    push_valid = 0;
    pop_ready = 0;
    @(posedge clk);
    #1;
    
    if (empty_next != 1'b1) begin
      $display("TEST FAILED: When empty with no activity, empty_next should be 1, got %b", empty_next);
      $finish;
    end
    if (full_next != 1'b0) begin
      $display("TEST FAILED: When empty with no activity, full_next should be 0, got %b", full_next);
      $finish;
    end
    
    pass_count = pass_count + 1;
    $display("PASS: Test 17 - Verify empty_next and full_next");

    // All tests passed
    $display("TEST PASSED");
    $finish;
  end

endmodule