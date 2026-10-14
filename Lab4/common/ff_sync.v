`timescale 1ns / 1ps

module ff_sync (
    input clk,
    input rst,
    input async_in,
    output reg sync_out
);

    reg ff1;

    always @(posedge clk) begin
        if (rst) begin
            sync_out <= 0;
            ff1 <= 0;
        end else begin
            sync_out <= ff1;
            ff1 <= async_in;
        end
    end

endmodule
