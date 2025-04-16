`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// SRAM Driver
class sram_driver extends uvm_driver;
  `uvm_component_utils(sram_driver)

  virtual interface sram_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      // Wait for a transaction
      sram_transaction tr;
      seq_item_port.get_next_item(tr);

      // Drive the signals based on the transaction
      vif.address <= tr.address;
      vif.data <= tr.data;
      vif.we <= tr.we;
      vif.oe <= tr.oe;
      vif.cs <= tr.cs;

      // Wait for a clock cycle
      @(posedge vif.clk);

      // Indicate the transaction is done
      seq_item_port.item_done();
    end
  endtask
endclass

// SRAM Monitor
class sram_monitor extends uvm_monitor;
  `uvm_component_utils(sram_monitor)

  virtual interface sram_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      // Capture the signals
      sram_transaction tr;
      tr.address = vif.address;
      tr.data = vif.data;
      tr.we = vif.we;
      tr.oe = vif.oe;
      tr.cs = vif.cs;

      // Send the transaction to the analysis port
      analysis_port.write(tr);

      // Wait for a clock cycle
      @(posedge vif.clk);
    end
  endtask
endclass

// SRAM Scoreboard
class sram_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sram_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      // Wait for a transaction from the monitor
      sram_transaction tr;
      analysis_port.get(tr);

      // Compare expected and actual results
      if (tr.expected_data !== tr.actual_data) begin
        `uvm_error("Scoreboard", $sformatf("Data mismatch: expected %0h, got %0h", tr.expected_data, tr.actual_data));
      end
    end
  endtask
endclass

// SRAM Coverage Collector
class sram_coverage extends uvm_subscriber;
  `uvm_component_utils(sram_coverage)

  covergroup cg;
    coverpoint vif.address;
    coverpoint vif.data;
    coverpoint vif.we;
    coverpoint vif.oe;
    coverpoint vif.cs;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      // Sample coverage points
      cg.sample();
      @(posedge vif.clk);
    end
  endtask
endclass

// SRAM Sequence
class sram_sequence extends uvm_sequence;
  `uvm_object_utils(sram_sequence)

  function new(string name = "sram_sequence");
    super.new(name);
  endfunction

  task body();
    sram_transaction tr;

    // Example test scenario: Write and then read
    tr.address = 16'h0000;
    tr.data = 8'hAA;
    tr.we = 1;
    tr.oe = 0;
    tr.cs = 1;
    start_item(tr);
    finish_item(tr);

    tr.we = 0;
    tr.oe = 1;
    start_item(tr);
    finish_item(tr);
  endtask
endclass 