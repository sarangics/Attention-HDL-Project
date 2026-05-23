module tb_attention;

reg clk;
reg rst;

attention_top dut(
    .clk(clk),
    .rst(rst)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;

    #20;
    rst = 0;

    #1000;

    $finish;
end

initial begin

    $dumpfile("output/attention.vcd");
    $dumpvars(0,tb_attention);

end

endmodule