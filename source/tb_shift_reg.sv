`timescale 1ns/10ps

module tb_shift_reg ();

  localparam CLK_PERIOD        = 2.5;
  localparam PROPAGATION_DELAY = 0.5; // Allow for 500ps for FF propogation delay

  localparam  SR_SIZE_BITS       = 8;
  localparam  SR_MAX_BIT         = SR_SIZE_BITS - 1;
  localparam  RESET_OUTPUT_VALUE = 8'b0;

  // Declare Test Case Signals
  integer tb_test_num;
  string  tb_test_case;
  string  tb_stream_check_tag;
  int     tb_bit_num;
  logic   tb_mismatch;
  logic   tb_check;

  // Declare DUT Connection Signals
  logic                tb_clk;
  logic                tb_nrst;
  logic                tb_D;
  logic [1:0]          tb_mode_i;
  logic [SR_MAX_BIT:0] tb_par_i;
  logic [SR_MAX_BIT:0] tb_P;

  // Declare the Test Bench Signals for Expected Results
  logic [SR_MAX_BIT:0] tb_expected_ouput;
  logic [SR_MAX_BIT:0] tb_p_test_data;
  logic tb_test_data [];
  logic [1:0] tb_mode;

  // Task for standard DUT reset procedure
  task reset_dut;
  begin
    // Activate the reset
    tb_nrst = 1'b0;

    // Maintain the reset for more than one cycle
    @(posedge tb_clk);
    @(posedge tb_clk);

    // Wait until safely away from rising edge of the clock before releasing
    @(negedge tb_clk);
    tb_nrst = 1'b1;

    // Leave out of reset for a couple cycles before allowing other stimulus
    // Wait for negative clock edges, 
    // since inputs to DUT should normally be applied away from rising clock edges
    @(negedge tb_clk);
    @(negedge tb_clk);
  end
  endtask

  // Task to cleanly and consistently check DUT output values
  task check_output;
    input string check_tag;
  begin
    tb_mismatch = 1'b0;
    tb_check    = 1'b1;
    if(tb_expected_ouput == tb_P) begin // Check passed
      $display("Correct parallel output %s during %s test case", check_tag, tb_test_case);
    end
    else begin // Check failed
      tb_mismatch = 1'b1;
      $error("Incorrect parallel output %s during %s test case", check_tag, tb_test_case);
    end

    // Wait some small amount of time so check pulse timing is visible on waves
    #(0.1);
    tb_check =1'b0;
  end
  endtask

  // Task to manage the timing of sending one bit through the shift register
  task send_bit;
    input logic bit_to_send;
  begin
    // Synchronize to the negative edge of clock to prevent timing errors
    @(negedge tb_clk);
    
    // Set the value of the bit
    tb_D = bit_to_send;
    // Activate the shift enable
    tb_mode_i = tb_mode;

    // Wait for the value to have been shifted in on the rising clock edge
    @(posedge tb_clk);
    #(PROPAGATION_DELAY);

    // Turn off the Shift enable
    tb_mode_i = 2'b0;
  end
  endtask

  // Task to contiguosly send a stream of bits through the shift register
  task send_stream;
    input logic bit_stream [];
  begin
    // Coniguously stream out all of the bits in the provided input vector
    for(tb_bit_num = 0; tb_bit_num < bit_stream.size(); tb_bit_num++) begin
      // Send the current bit
      send_bit(bit_stream[tb_bit_num]);
    end
  end
  endtask

  // Set input signals to zero before starting with new testcases
  task inactivate_signals;
  begin
    tb_D      = '0;
    tb_mode_i = '0;
    tb_par_i  = '0;
  end
  endtask

  // Clock generation block
  always begin
    // Start with clock low to avoid false rising edge events at t=0
    tb_clk = 1'b0;
    // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
    tb_clk = 1'b1;
    // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
  end

  // DUT Portmap
  shift_reg DUT 
  (
    .clk(tb_clk), 
    .nrst(tb_nrst), 
    .D(tb_D), 
    .mode_i(tb_mode_i), 
    .par_i(tb_par_i),
    .P(tb_P)
  );

  // Signal Dump
  initial begin
    $dumpfile ("dump.vcd");
    $dumpvars;
  end
  
  // Test Cases
  initial begin
    // Initialize all of the test inputs
    tb_nrst             = 1'b1; // Initialize to be inactive
    tb_D                = 1'b1; // Initialize to inactive value
    tb_mode_i           = '0;   // Initialize to be inactive
    tb_par_i            = '0;
    tb_test_num         = 0;    // Initialize test case counter
    tb_test_case        = "Test bench initializaton";
    tb_stream_check_tag = "N/A";
    tb_bit_num          = -1;   // Initialize to invalid number
    tb_mismatch         = 1'b0;
    tb_check            = 1'b0;
    // Wait some time before starting first test case
    #(0.1);

    // ************************************************************************
    // Test Case 1: Power-on Reset of the DUT
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Power on Reset";
    // Note: Do not use reset task during reset test case since we need to specifically check behavior during reset
    // Wait some time before applying test case stimulus
    #(0.1);
    // Apply test case initial stimulus
    tb_D    = 1'b0;
    tb_nrst = 1'b0;

    // Wait for a bit before checking for correct functionality
    #(CLK_PERIOD * 0.5);

    // Check that internal state was correctly reset
    tb_expected_ouput = RESET_OUTPUT_VALUE;
    check_output("after reset applied");

    // Check that the reset value is maintained during a clock cycle
    #(CLK_PERIOD);
    check_output("after clock cycle while in reset");
    
    // Release the reset away from a clock edge
    @(negedge tb_clk);
    tb_nrst  = 1'b1;   // Deactivate the chip reset
    // Check that internal state was correctly keep after reset release
    #(PROPAGATION_DELAY);
    check_output("after reset was released");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 2: Check Mode 0
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Mode 0";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode   = 2'd0;

    // Define the test data stream for this test case
    tb_p_test_data = 8'h55;

    // Define the expected result
    tb_expected_ouput = '0;

    tb_par_i = tb_p_test_data;
    tb_mode_i = tb_mode;

    // Wait for some time before checking the outputs
    @(posedge tb_clk);
    #(PROPAGATION_DELAY);
    // Check the result of the full stream
    check_output("after trying to stream in some data under mode 0");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 3: Check Mode 1
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Mode 1";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode   = 2'd1;

    // Define the test data stream for this test case
    tb_p_test_data = 8'h55;

    // Define the expected result
    tb_expected_ouput = tb_p_test_data;

    tb_par_i  = tb_p_test_data;
    tb_mode_i = tb_mode;

    // Wait for some time before checking the outputs
    @(posedge tb_clk);
    #(PROPAGATION_DELAY);
    // Check the result of the full stream
    check_output("after parallel loading");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 4: Check Mode 2 with 8'hAA bit stream
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Mode 2 with 8'hAA bit stream";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode = 2'd2;

    // Define the test data stream for this test case
    tb_test_data = {1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0};

    // Define the expected result
    tb_expected_ouput = 8'hAA;

    // Send bit stream
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after left shifting");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 5: Check Mode 2 with 8'h55 bit stream
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Mode 2 with 8'h55 bit stream";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode = 2'd2;

    // Define the test data stream for this test case
    tb_test_data = {1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1};

    // Define the expected result
    tb_expected_ouput = 8'h55;

    // Send bit stream
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after left shifting");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 6: Check Mode 3 with 8'hAA bit stream
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Mode 3 with 8'hAA bit stream";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode = 2'd3;

    // Define the test data stream for this test case
    tb_test_data = {1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0};

    // Define the expected result
    tb_expected_ouput = 8'h55;

    // Send bit stream
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after right shifting");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 7: Check Mode 3 with 8'h55 bit stream
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Mode 3 with 8'h55 bit stream";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode = 2'd3;

    // Define the test data stream for this test case
    tb_test_data = {1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1};

    // Define the expected result
    tb_expected_ouput = 8'hAA;

    // Send bit stream
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after left shifting");
    #(CLK_PERIOD * 3);

    
    // ************************************************************************
    // Test Case 8: Overflow Mode 2
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Overflow Mode 2";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode = 2'd2;

    // Define the test data stream for this test case
    tb_test_data = {1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1};

    // Define the expected result
    tb_expected_ouput = 8'h57;

    // Send bit stream
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after left shifting");
    #(CLK_PERIOD * 3);

    // ************************************************************************
    // Test Case 8: Overflow Mode 2
    // ************************************************************************
    tb_test_num  = tb_test_num + 1;
    tb_test_case = "Check Overflow Mode 3";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    inactivate_signals();
    reset_dut();

    // Set mode
    tb_mode = 2'd3;

    // Define the test data stream for this test case
    tb_test_data = {1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1};

    // Define the expected result
    tb_expected_ouput = 8'hEA;

    // Send bit stream
    send_stream(tb_test_data);

    // Check the result of the full stream
    check_output("after right shifting");
    #(CLK_PERIOD * 3);

    // STUDENT TODO: Add more test cases here

    // Add test cases before this line. DO NOT MODIFY CODE AFTER THIS LINE !!!!!
    if (tb_test_num == 9) begin
      $error("You did not add more test cases !!!!!");
    end

    $display("Simulation complete");
    $stop;
  end

endmodule
