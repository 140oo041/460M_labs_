module top(
input clk,rst,
 input DATA,req,
 output ack, output [7:0] last,
 output VALID, ERROR,
 output [6:0] seg, output [3:0] an);

    wire [23:0] out;
    assign last = out [15:8];

    twenty_four_bit_receiver (
        .clk(clk),
        .rst(rst),
        .req(req),
        .data_stream(DATA),
        .data_out(out),
        .ack(ack),
        .valid(VALID),
        .error(ERROR)
    );

    wire slow_clk;

    tick_gen tick_gen_inst (
        .clk(clk),
        .rst(rst),
        .tick(slow_clk)
    );

    hex_display hex_display_inst (
        .clk(clk),
        .rst(rst),
        .value(last),
        .an(an),
        .seg(seg)
    );


    
 
endmodule

module tick_gen (
    input clk,
    input rst,
    output tick
);

    localparam SYS_CLK_HZ = 100_000_000;
    localparam TARGET_HZ = 1000;
    localparam MAX_CNT = SYS_CLK_HZ / TARGET_HZ;
    localparam CNT_W = $clog2(MAX_CNT);

    reg [CNT_W-1:0] cnt;
    
    always @(posedge clk) begin
        if (rst) cnt <= 0;
        else begin
            if (cnt == MAX_CNT - 1) cnt <= 0;
            else cnt <= cnt + 1;
        end
    end

    assign tick = (cnt == MAX_CNT - 1);
    
endmodule


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

module eight_bit_receiver (input clk, input rst, input req, input data_stream,
 output reg [7:0] data_out, output ack, output reg valid, output reg error);

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
    wire [7:0] count;
    wire done;

    N_bit_counter #(8) counter (
        .clk(clk),
        .rst(rst),
        .enable(RX_EVENT),
        .count(count),
        .done(done)
    );
    
    always @(posedge clk) begin
        if(rst) begin valid <= 0; error <= 0; end
        else if(done) begin 
            valid <= 1'b1;
            error <= ~valid;
        end
        else begin valid <= valid; error <= error; end
    end


    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         valid <= 0;
    //         error <= 0;
    //     end else if (done) begin
    //         valid <= ((data_out[15:8] ^ data_out[23:16]) == data_out[7:0]) && (data_out[23:16] == 8'hA5); // Check parity
    //         error <= ~valid;
    //     end else begin
    //         valid <= valid;
    //         error <= error;
    //     end
    // end
    
    reg[7:0] data_out_;
    always @(posedge clk or posedge rst) begin
        if(rst) data_out = 0;
        else if(valid) data_out = data_out_;
        else data_out = data_out;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out_ <= 0;
        end else if (RX_EVENT) begin
            data_out_ <= {data_out[6:0], received_data}; // Shift in the received bit
        end else begin
            data_out_ <= data_out_;
        end
    end
endmodule

module twenty_four_bit_receiver (input clk, input rst, input req, input data_stream,
 output reg [24-1:0] data_out, output ack, output reg valid, output reg error);

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
    wire [24-1:0] count;
    wire done;

    N_bit_counter #(24) counter (
        .clk(clk),
        .rst(rst),
        .enable(RX_EVENT),
        .count(count),
        .done(done)
    );

    reg[23:0] data_out_acc;
    reg valid_sig;
    reg error_sig;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 0;
            error <= 0;
        end else if (done) begin
            valid_sig <= ((data_out_acc[15:8] ^ data_out_acc[23:16]) == data_out_acc[7:0]) && (data_out_acc[23:16] == 8'hA5); // Check parity
            error <= ~valid;
            valid <= ((data_out_acc[15:8] ^ data_out_acc[23:16]) == data_out_acc[7:0]) && (data_out_acc[23:16] == 8'hA5);
        end else begin
            valid <= valid;
            error <= error;
            valid_sig <= 0;
        end
    end
    
    always @(posedge clk) begin
        
    end
    
    reg Valid_prev;
    always @(posedge clk) begin
        Valid_prev <= valid_sig;
    end    
    wire Valid_rising_edge = ~Valid_prev & valid_sig;
    
//    reg done_prev;
//    always @(posedge clk) begin
//        done_prev <= done;
//    end
//    wire done_rising_edge = ~done_prev & done;

    always @(posedge clk or posedge rst) begin
        if(rst) data_out = 0;
        else if(Valid_rising_edge) data_out = data_out_acc;
        else data_out = data_out;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out_acc <= 0;
        end else if (RX_EVENT) begin
            data_out_acc <= {data_out_acc[24-2:0], received_data}; // Shift in the received bit
        end else begin
            data_out_acc <= data_out_acc;
        end
    end
endmodule

//module N_bit_receiver #(parameter N = 8)(input clk, input rst, input req, input data_stream,
// output reg [N-1:0] data_out, output ack, output reg valid, output reg error);

//    wire received_data;
//    wire RX_EVENT;

// one_bit_receiver bit_receiver (
//    .clk(clk),
//    .rst(rst),
//    .req(req),
//    .data_in(data_stream),
//    .data_out(received_data),
//    .ack(ack),
//    .RX_EVENT(RX_EVENT)
//);
//    wire [N-1:0] count;
//    wire done;

//    N_bit_counter #(N) counter (
//        .clk(clk),
//        .rst(rst),
//        .enable(RX_EVENT),
//        .count(count),
//        .done(done)
//    );


//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            valid <= 0;
//            error <= 0;
//        end else if (done) begin
//            valid <= ((data_out[15:8] ^ data_out[23:16]) == data_out[7:0]) && (data_out[23:16] == 8'hA5); // Check parity
//            error <= ~valid;
//        end else begin
//            valid <= valid;
//            error <= error;
//        end
//    end
    
//    reg[N-1:0] data_out_;
//    always @(posedge clk or posedge rst) begin
//        if(rst) data_out = 0;
//        else if(valid) data_out = data_out_;
//        else data_out = data_out;
//    end

//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            data_out <= 0;
//        end else if (RX_EVENT) begin
//            data_out <= {data_out[N-2:0], received_data}; // Shift in the received bit
//        end else begin
//            data_out <= data_out;
//        end
//    end
//endmodule

module N_bit_counter #(parameter N = 8) (
    input clk, rst, input enable, output reg [$clog2(N):0] count, output reg done
);
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