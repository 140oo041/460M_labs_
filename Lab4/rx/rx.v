module one_bit_receiver(input clk, input rst, input req, input data_in,
 output reg data_out, output reg ack, output reg RX_EVENT);

    wire sync_req_rising_edge;
    wire sync_req_falling_edge;
    wire sync_req;
    
    edge_detector ed(.clk(clk), .rst(rst), .in_sig(req), .out_sig_rising_edge(sync_req_rising_edge), .out_sig_falling_edge(sync_req_falling_edge), .sync_out(sync_req));

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 1'b0;
            ack <= 1'b0;
            RX_EVENT <= 1'b0;
        end 
//        else if (sync_req_rising_edge || sync_req_falling_edge) begin
//            if(sync_req != ack) begin
//                data_out <= data_in;
//                ack <= sync_req;
//                RX_EVENT <= 1;
//            end
//            else begin
//                ack <= ack;
//                data_out <= data_out;
//                RX_EVENT <= 0;
//            end 
//        end
        else if(sync_req != ack) begin
                data_out <= data_in;
                ack <= sync_req;
                RX_EVENT <= 1;
            end
        else begin
            ack <= ack;
            data_out <= data_out;
            RX_EVENT <= 0;
        end
    end

endmodule

module N_bit_receiver #(parameter N = 8)(input clk, input rst, input req, input data_stream,
 output reg [N-1:0] data_out, output ack, output reg valid, output reg error);

    wire received_data;
    wire RX_EVENT;

 one_bit_receiver bit_receiver (
    .clk(clk),
    .rst(rst),
    .req(req),
    .data_in(data_stream),
    .data_out(received_data),
    .ack(ack),
    .RX_EVENT(RX_EVENT)
);
    wire [N-1:0] count;
    wire done;

    N_bit_counter #(N) counter (
        .clk(clk),
        .rst(rst),
        .enable(RX_EVENT),
        .count(count),
        .done(done)
    );


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 0;
            error <= 0;
        end else if (done) begin
            valid <= ((data_out[15:8] ^ data_out[23:16]) == data_out[7:0]) && (data_out[23:16] == 8'hA5); // Check parity
            error <= ~valid;
        end else begin
            valid <= valid;
            error <= error;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
        end else if (RX_EVENT) begin
            data_out <= {data_out[N-2:0], received_data}; // Shift in the received bit
        end else begin
            data_out <= data_out;
        end
    end
endmodule

module N_bit_counter #(parameter N = 8) (
    input clk, rst, input enable, output reg [N-1:0] count, output reg done
)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            done <= 0;
        end else if (enable) begin
            if (count == N-1) begin
                count <= 0;
                done <= 1;
            end else begin
                count <= count + 1;
                done <= 0;
            end
        end else begin
            count <= count;
            done <= done;
        end
    end

endmodule