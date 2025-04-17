module lvds_adc (
    input wire clk,
    input wire reset,
    input wire [LVDS_WIDTH-1:0] lvds_data, // Raw LVDS data input
    input wire lvds_clk, // Clock associated with LVDS data (may not be used directly if data is source-synchronous and captured differently)
    input wire lvds_control, // Asynchronous control signal
    input wire feedback,     // Asynchronous feedback signal
    output wire [DATA_WIDTH-1:0] adc_data_out, // Registered output data
    output wire adc_we,        // Registered output write enable
    output wire adc_oe,        // Registered output output enable
    output wire adc_cs         // Registered output chip select
);

    parameter LVDS_WIDTH = 8;
    parameter DATA_WIDTH = 8;
    parameter integer SAMPLING_RATE = 1000; // Clock cycles per sample

    // --- Input Synchronization and Buffering ---
    reg [LVDS_WIDTH-1:0] lvds_data_reg;
    reg lvds_control_sync1, lvds_control_sync2, lvds_control_reg;
    reg feedback_sync1, feedback_sync2, feedback_reg;

    // Synchronize control signals (double-flopped)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lvds_control_sync1 <= 1'b0;
            lvds_control_sync2 <= 1'b0;
            lvds_control_reg   <= 1'b0;
            feedback_sync1     <= 1'b0;
            feedback_sync2     <= 1'b0;
            feedback_reg       <= 1'b0;
        end else begin
            // Double flop synchronizers
            lvds_control_sync1 <= lvds_control;
            lvds_control_sync2 <= lvds_control_sync1;
            lvds_control_reg   <= lvds_control_sync2; // Registered control signal

            feedback_sync1     <= feedback;
            feedback_sync2     <= feedback_sync1;
            feedback_reg       <= feedback_sync2;     // Registered feedback signal
        end
    end

    // Register input data (assuming it's stable around clk edge or handled by lvds_clk elsewhere)
    // NOTE: Proper LVDS capture often requires dedicated hardware (ISERDES) and clocking strategies
    // This is a simplified buffering example.
    always @(posedge clk) begin
         lvds_data_reg <= lvds_data; // Simplified data registration
    end

    // --- Sampling Logic ---
    reg [31:0] sample_counter;
    reg sample_enable;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_counter <= 32'b0;
            sample_enable <= 1'b0;
        end else begin
            if (sample_counter >= SAMPLING_RATE - 1) begin
                sample_counter <= 32'b0;
                sample_enable <= 1'b1; // Enable sampling for one cycle
            end else begin
                sample_counter <= sample_counter + 1;
                sample_enable <= 1'b0;
            end
        end
    end

    // --- Pipelined State Machine ---
    typedef enum logic [1:0] {
        IDLE,
        CAPTURE, // Renamed READ to CAPTURE for clarity
        PROCESS, // Added stage for potential processing/decision making
        WAIT     // Wait state before returning to IDLE
    } state_t;

    state_t current_state, next_state;

    // Pipeline registers
    reg [DATA_WIDTH-1:0] captured_data_pipe;
    reg capture_valid_pipe;

    // Registered state machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational next state logic
    always_comb begin
        next_state = current_state; // Default to stay in current state
        capture_valid_pipe = 1'b0;  // Default
        captured_data_pipe = '0;    // Default

        case (current_state)
            IDLE: begin
                // Trigger capture based on synchronized control, feedback, and sample enable
                if (sample_enable && lvds_control_reg && feedback_reg) begin
                    next_state = CAPTURE;
                end
            end
            CAPTURE: begin
                // In this stage, we latch the registered data
                captured_data_pipe = lvds_data_reg[DATA_WIDTH-1:0]; // Use registered data
                capture_valid_pipe = 1'b1;
                next_state = PROCESS; // Move to next pipeline stage
            end
            PROCESS: begin
                 // Data is available in captured_data_pipe
                 // Decide whether to assert SRAM control signals (read/write)
                 // For now, assume we always want to 'read/present' captured data
                 next_state = WAIT; // Move to wait state after processing
            end
            WAIT: begin
                // Wait one cycle before potentially starting a new operation
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // --- Output Logic & Buffering ---
    reg [DATA_WIDTH-1:0] adc_data_out_reg;
    reg adc_we_reg;
    reg adc_oe_reg;
    reg adc_cs_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            adc_we_reg <= 1'b1;
            adc_oe_reg <= 1'b1;
            adc_cs_reg <= 1'b1;
            adc_data_out_reg <= '0;
        end else begin
            // Default values (inactive)
            adc_we_reg <= 1'b1;
            adc_oe_reg <= 1'b1;
            adc_cs_reg <= 1'b1;
            adc_data_out_reg <= adc_data_out_reg; // Keep previous value unless updated

            if (current_state == PROCESS && capture_valid_pipe) begin
                // Assert control signals based on the pipelined data validity
                // Assuming we want to output the captured data (like a read operation)
                adc_we_reg <= 1'b1; // Not writing to SRAM in this example
                adc_oe_reg <= 1'b0; // Enable output (present data)
                adc_cs_reg <= 1'b0; // Select SRAM
                adc_data_out_reg <= captured_data_pipe; // Output the pipelined data
            end
            // In WAIT and IDLE, signals return to inactive states
        end
    end

    // Assign registered outputs to output ports
    assign adc_data_out = adc_data_out_reg;
    assign adc_we = adc_we_reg;
    assign adc_oe = adc_oe_reg;
    assign adc_cs = adc_cs_reg;

endmodule 