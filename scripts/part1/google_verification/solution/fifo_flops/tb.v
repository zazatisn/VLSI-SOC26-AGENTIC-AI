`timescale 1ns/1ps

module tb_fifo_flops();
  reg clk, rst, push_valid, pop_ready;
  reg [7:0] push_data;
  wire push_ready, pop_valid, full, full_next, empty, empty_next;
  wire [7:0] pop_data;
  wire [3:0] slots, slots_next, items, items_next;
  integer i;

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

  always #5 clk = ~clk;

  initial begin
    clk = 0; rst = 1; push_valid = 0; pop_ready = 0; push_data = 0;
    #15 rst = 0;
    #2;

    // 1. Reset state check
    if (empty !== 1 || full !== 0 || items !== 0 || slots !== 13) begin
      $display("TEST FAILED: Reset state"); $finish;
    end

    // 2. Bypass check
    @(negedge clk);
    push_valid = 1; pop_ready = 1; push_data = 8'hA5;
    #2;
    if (pop_data !== 8'hA5 || pop_valid !== 1) begin
      $display("TEST FAILED: Bypass mode"); $finish;
    end
    @(negedge clk);
    push_valid = 0; pop_ready = 0;

    // 3. Fill FIFO
    for (i = 0; i < 13; i = i + 1) begin
      @(negedge clk);
      push_valid = 1; push_data = i[7:0];
      #2;
      @(posedge clk); #2;
    end
    
    if (full !== 1 || items !== 13) begin
      $display("TEST FAILED: Full state after 13 pushes"); $finish;
    end

    // 4. Drain FIFO
    pop_ready = 1;
    for (i = 0; i < 13; i = i + 1) begin
      #2;
      if (pop_data !== i[7:0]) begin
        $display("TEST FAILED: Data mismatch at item %d", i); $finish;
      end
      @(posedge clk);
    end

    // 5. Final Empty check
    #2;
    if (empty !== 1 || items !== 0) begin
      $display("TEST FAILED: Final empty state"); $finish;
    end

    $display("TEST PASSED");
    $finish;
  end
endmodule