module TestMooreMachine();

  logic   clk, rstN, in, out;

  MooreMachine dut(clk, rstN, in, out);

  always begin
    clk = 1; #5; clk = 0; #5;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, TestMooreMachine);
    rstN = 0; #7;
    rstN = 1; #5;
    in   = 0; #30;
    in   = 1; #60;
    $finish;
  end

endmodule
