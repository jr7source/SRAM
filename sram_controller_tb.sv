`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

module sram_controller_tb;

  // Clock and reset signals
  logic clk;
  logic reset;

  // DUT signals
  logic [15:0] address;
  logic [7:0] data;
  logic we, oe, cs;
  logic [7:0] sram_data_out;
  logic sram_we, sram_oe, sram_cs;

  // Instantiate the DUT
  sram_controller #(
    .ADDR_WIDTH(16),
    .DATA_WIDTH(8)
  ) dut (
    .clk(clk),
    .reset(reset),
    .address(address),
    .data(data),
    .we(we),
    .oe(oe),
    .cs(cs),
    .sram_data_out(sram_data_out),
    .sram_we(sram_we),
    .sram_oe(sram_oe),
    .sram_cs(sram_cs)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    reset = 1;
    #10 reset = 0;
  end

  // UVM Environment
  class sram_env extends uvm_env;
    // Components like driver, monitor, scoreboard, etc.
    // ...
  endclass

  // UVM Test
  class sram_test extends uvm_test;
    `uvm_component_utils(sram_test)
    sram_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = sram_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      // Test sequences
      // ...
      phase.drop_objection(this);
    endtask
  endclass

  // Testbench top-level
  initial begin
    run_test("sram_test");
  end

endmodule 