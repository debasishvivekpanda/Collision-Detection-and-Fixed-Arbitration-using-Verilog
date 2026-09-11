module rs485_bus(
    input  wire [3:0] tx_en,
    input  wire [3:0] tx_data,

    output wire bus,
    output wire collision
);

    assign collision =
            (tx_en[0] + tx_en[1] +
             tx_en[2] + tx_en[3]) > 1;

    assign bus =
            tx_en[0] ? tx_data[0] :
            tx_en[1] ? tx_data[1] :
            tx_en[2] ? tx_data[2] :
            tx_en[3] ? tx_data[3] :
            1'b0;

endmodule