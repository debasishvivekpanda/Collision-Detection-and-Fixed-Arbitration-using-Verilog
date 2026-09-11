module Node(
    input wire clk,
    input wire rst,
    input wire grant,
    input wire start,
    output reg request,
    output reg tx_en,
    output reg tx_data,
    output wire [2:0] current_state
);
    parameter IDLE      = 3'b000;
    parameter REQUEST   = 3'b001;
    parameter TRANSMIT  = 3'b010;
    parameter DONE      = 3'b101;

    reg [2:0] state;
    reg [2:0] next_state;
    reg sent;
    
    assign current_state = state;

    always @(posedge clk or posedge rst)
        begin
            if (rst)
                begin
                    state <= IDLE;
                    sent  <= 1'b0;
                end
            else
                begin
                    state <= next_state;

                    if (state == DONE)
                        sent <= 1'b1;

                    if (!start)
                        sent <= 1'b0;
                end
        end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start && !sent)
                    next_state = REQUEST;
             end
            REQUEST: begin 
                if (grant)
                    next_state = TRANSMIT;
            end
            TRANSMIT: begin 
                    next_state = DONE;
            end
            DONE: begin 
                next_state = IDLE;
            end

            default: begin 
                next_state = IDLE;
            end
        endcase
     end

    always @(*) begin 
        request = 1'b0;
        tx_en   = 1'b0;
        tx_data = 1'b0;

        case (state)
            IDLE: begin 
                request = 1'b0;
                tx_en   = 1'b0;
            end

            REQUEST: begin 
                request = 1'b1;
                tx_en   = 1'b0;
            end

            TRANSMIT: begin 
                request = 1'b0;
                tx_en   = 1'b1;
                tx_data = 1'b1;
            end

            DONE: begin 
                request = 1'b0;
                tx_en   =1'b0;
            end

            default: begin 
                request = 1'b0;
                tx_en   = 1'b0;
                tx_data = 1'b0;
            end
        endcase

    end
endmodule