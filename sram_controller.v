module sram_controller (
    input wire clk,
    input wire reset,
    input wire [ADDR_WIDTH-1:0] address,
    inout wire [DATA_WIDTH-1:0] data,
    input wire we,  // Write Enable
    input wire oe,  // Output Enable
    input wire cs,  // Chip Select
    output reg [DATA_WIDTH-1:0] sram_data_out,
    output reg sram_we,
    output reg sram_oe,
    output reg sram_cs
);

    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 8;

    // State machine states
    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE,
        WAIT
    } state_t;

    state_t current_state, next_state;

    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (cs) begin
                    if (we) begin
                        next_state = WRITE;
                    end else if (oe) begin
                        next_state = READ;
                    end else begin
                        next_state = IDLE;
                    end
                end else begin
                    next_state = IDLE;
                end
            end
            READ: begin
                next_state = WAIT;
            end
            WRITE: begin
                next_state = WAIT;
            end
            WAIT: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output logic
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                sram_we <= 1'b1;
                sram_oe <= 1'b1;
                sram_cs <= 1'b1;
            end
            READ: begin
                sram_we <= 1'b1;
                sram_oe <= 1'b0;
                sram_cs <= 1'b0;
                sram_data_out <= data;
            end
            WRITE: begin
                sram_we <= 1'b0;
                sram_oe <= 1'b1;
                sram_cs <= 1'b0;
            end
            WAIT: begin
                sram_we <= 1'b1;
                sram_oe <= 1'b1;
                sram_cs <= 1'b1;
            end
        endcase
    end

endmodule 