module top(

    input wire clk,
    input wire rst,
    input wire [3:0] start,
    output wire bus,
    output wire collision
);


    wire [3:0] request;
    wire [3:0] tx_en;
    wire [3:0] tx_data;


    wire [3:0] grant;

    arbiter arb (
        .request(request),
        .grant(grant)
    );


    Node node0 (
        .clk(clk),
        .rst(rst),
        .grant(grant[0]),
        .start(start[0]),
        .request(request[0]),
        .tx_en(tx_en[0]),
        .tx_data(tx_data[0])
    );

    Node node1 (
        .clk(clk),
        .rst(rst),
        .grant(grant[1]),
        .start(start[1]),
        .request(request[1]),
        .tx_en(tx_en[1]),
        .tx_data(tx_data[1])
    );

    Node node2 (
        .clk(clk),
        .rst(rst),
        .grant(grant[2]),
        .start(start[2]),
        .request(request[2]),
        .tx_en(tx_en[2]),
        .tx_data(tx_data[2])
    );

    Node node3 (
        .clk(clk),
        .rst(rst),
        .grant(grant[3]),
        .start(start[3]),
        .request(request[3]),
        .tx_en(tx_en[3]),
        .tx_data(tx_data[3])
    );

    rs485_bus bus_inst (
        .tx_en(tx_en),
        .tx_data(tx_data),
        .bus(bus),
        .collision(collision)
    );

endmodule