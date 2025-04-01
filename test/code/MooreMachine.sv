module MooreMachine (
  input  logic clk, rstN, in,
  output logic out
);

  typedef enum {
    S0,
    S1,
    S2
  } State;

  State state, stateNext;

  always_ff @(posedge clk or negedge rstN) begin
    if (!rstN) begin
      state <= S0;
    end
    else begin
      state <= stateNext;
    end
  end

  always_comb begin
    case (state)
      S0: begin
        out = 1'b0;
        stateNext = in === 1 ? S1 : S0;
      end
      S1: begin
        out = 1'b1;
        stateNext = in === 1 ? S2 : S0;
      end
      S2: begin
        out = 1'b0;
        stateNext = in === 1 ? S2 : S0;
      end
      default: begin
        out = 1'b0;
        stateNext = S0;
      end
    endcase
  end

endmodule
