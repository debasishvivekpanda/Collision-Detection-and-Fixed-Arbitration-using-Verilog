`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;
    reg [3:0] start;

    wire bus;
    wire collision;

    top DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .bus(bus),
        .collision(collision)
    );

    //---------------------------------------------------
    // Clock
    //---------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //---------------------------------------------------
    // Wave dump
    //---------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

    //---------------------------------------------------
    // Test Sequence
    //---------------------------------------------------
    initial begin

        rst   = 1;
        start = 4'b0000;

        #20;
        rst = 0;

        //---------------------------------------------------
        // Test 1 : Node0 only
        //---------------------------------------------------
        $display("TEST1 : Node0");

        start = 4'b0001;

        #100;

        start = 4'b0000;

        #50;

        //---------------------------------------------------
        // Test 2 : Node0 and Node1
        //---------------------------------------------------
        $display("TEST2 : Node0 and Node1");

        start = 4'b0011;

        #150;

        start = 4'b0000;

        #50;

        //---------------------------------------------------
        // Test 3 : All Nodes
        //---------------------------------------------------
        $display("TEST3 : All Nodes");

        start = 4'b1111;

        #300;

        start = 4'b0000;

        #50;

        //---------------------------------------------------
        // Test 4 : Random Requests
        //---------------------------------------------------
        $display("TEST4 : Random Traffic");

        repeat (20) begin
            start = $random % 16;
            #20;
        end

        #100;

        $finish;
    end

endmodule