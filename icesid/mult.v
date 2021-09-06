// .___               _________.___________
// |   | ____  ____  /   _____/|   \______ \
// |   |/ ___\/ __ \ \_____  \ |   ||    |  \
// |   \  \__\  ___/ /        \|   ||    `   \
// |___|\___  >___  >_______  /|___/_______  /
//          \/    \/        \/             \/
`default_nettype none

`define MANUAL_SB_MAC16

// 16x16 multiplier for the filters
module mult16x16 (
    input                clk,
    input  signed [16:0] iSignal,
    input         [15:0] iCoef,
    output signed [15:0] oOut
);
`ifdef MANUAL_SB_MAC16
  wire signed [31:0] product;  // 16x16 product
  assign oOut = product[31:16];

  wire signed [15:0] clipped;
  clipper clip (
      iSignal,
      clipped
  );

  SB_MAC16 mac (
      .A  (clipped),
      .B  (iCoef),
      .O  (product),
      .CLK(clk)
  );

  defparam mac.A_SIGNED = 1'b1;  // input is signed
  defparam mac.B_SIGNED = 1'b0;  // coefficient is unsigned
  defparam mac.TOPOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
  defparam mac.BOTOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
`else
  wire signed [15:0] rhs = { 1'b0, iCoef[14:0] };
  reg signed [31:0] product;
  assign oOut = product[31:16];
  always @(posedge clk) begin
    product <= iSignal * rhs;
  end
`endif
endmodule

// 16x4 multiplier used for master volume
module mdac16x4 (
    input                clk,
    input  signed [15:0] iVoice,
    input         [ 3:0] iVol,
    output signed [15:0] oOut
);
`ifdef MANUAL_SB_MAC16
  wire signed [31:0] product;  // 16x16 product
  SB_MAC16 mac (
      .A  (iVoice),
      .B  ({12'b0, iVol}),
      .O  (product),
      .CLK(clk),
  );

  defparam mac.A_SIGNED = 1'b1;  // voice is signed
  defparam mac.B_SIGNED = 1'b0;  // env is unsigned
  defparam mac.TOPOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
  defparam mac.BOTOUTPUT_SELECT = 2'b11;  // Mult16x16 data output

  reg [15:0] out;
  assign oOut = out;
  always @(posedge clk) begin
    out <= product[19:4];
  end
`else
  wire signed [15:0] lhs = iVoice;
  wire signed [15:0] rhs = { 12'h0, iVol };
  reg signed [31:0] product;
  assign oOut = product[19:4];
  always @(posedge clk) begin
    product <= lhs * rhs;
  end
`endif
endmodule

// 12x8 multiplier used for voice envelopes
module mdac12x8 (
    input                clk,
    input  signed [11:0] iVoice,
    input         [ 7:0] iEnv,
    output signed [31:0] oOut
);
`ifdef MANUAL_SB_MAC16
  wire signed [31:0] product;  // 16x16 product
  SB_MAC16 mac (
      .A  ({{4{iVoice[11]}}, iVoice}),
      .B  ({8'b0, iEnv}),
      .O  (product),
      .CLK(clk),
  );

  defparam mac.A_SIGNED = 1'b1;  // voice is signed
  defparam mac.B_SIGNED = 1'b0;  // env is unsigned
  defparam mac.TOPOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
  defparam mac.BOTOUTPUT_SELECT = 2'b11;  // Mult16x16 data output
  assign oOut = product;
`else
  wire signed [15:0] lhs = { iVoice, 4'h0 };
  wire signed [15:0] rhs = { 8'h0, iEnv };
  reg signed [31:0] product;
  assign oOut = product[23:8];
  always @(posedge clk) begin
    product <= lhs * rhs;
  end
`endif
endmodule

module mult32x16(
    input                clk,
    input  signed [31:0] iLHS,
    input  signed [15:0] iRHS,
    output signed [31:0] oOut
);
`ifdef BAD
  wire oOut_SB_MAC16_O_ACCUMCO;
  wire oOut_SB_MAC16_O_CO;
  wire oOut_SB_MAC16_O_SIGNEXTOUT;
  wire [48:0] product;
  wire product_SB_MAC16_O_ACCUMCO;
  wire product_SB_MAC16_O_CO;
  wire [31:0] product_SB_MAC16_O_O;
  wire product_SB_MAC16_O_SIGNEXTOUT;
  SB_MAC16 #(
    .A_REG(1'h0),
    .A_SIGNED(32'd1),
    .BOTADDSUB_CARRYSELECT(2'h0),
    .BOTADDSUB_LOWERINPUT(2'h2),
    .BOTADDSUB_UPPERINPUT(1'h1),
    .BOTOUTPUT_SELECT(2'h1),
    .BOT_8x8_MULT_REG(1'h0),
    .B_REG(1'h0),
    .B_SIGNED(32'd1),
    .C_REG(1'h0),
    .D_REG(1'h0),
    .MODE_8x8(1'h0),
    .NEG_TRIGGER(1'h0),
    .PIPELINE_16x16_MULT_REG1(1'h0),
    .PIPELINE_16x16_MULT_REG2(1'h0),
    .TOPADDSUB_CARRYSELECT(2'h3),
    .TOPADDSUB_LOWERINPUT(2'h2),
    .TOPADDSUB_UPPERINPUT(1'h1),
    .TOPOUTPUT_SELECT(2'h1),
    .TOP_8x8_MULT_REG(1'h0)
  ) oOut_SB_MAC16_O (
    .A(iLHS[31:16]),
    .ACCUMCI(1'hx),
    .ACCUMCO(oOut_SB_MAC16_O_ACCUMCO),
    .ADDSUBBOT(1'h0),
    .ADDSUBTOP(1'h0),
    .AHOLD(1'h0),
    .B(iRHS),
    .BHOLD(1'h0),
    .C({ product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31], product_SB_MAC16_O_O[31] }),
    .CE(1'h1),
    .CHOLD(1'h0),
    .CI(1'hx),
    .CLK(clk),
    .CO(oOut_SB_MAC16_O_CO),
    .D(product_SB_MAC16_O_O[31:16]),
    .DHOLD(1'h0),
    .IRSTBOT(1'h0),
    .IRSTTOP(1'h0),
    .O(oOut),
    .OHOLDBOT(1'h0),
    .OHOLDTOP(1'h0),
    .OLOADBOT(1'h0),
    .OLOADTOP(1'h0),
    .ORSTBOT(1'h0),
    .ORSTTOP(1'h0),
    .SIGNEXTIN(1'hx),
    .SIGNEXTOUT(oOut_SB_MAC16_O_SIGNEXTOUT)
  );
  SB_MAC16 #(
    .A_REG(1'h0),
    .A_SIGNED(32'd0),
    .BOTADDSUB_CARRYSELECT(2'h0),
    .BOTADDSUB_LOWERINPUT(2'h2),
    .BOTADDSUB_UPPERINPUT(1'h1),
    .BOTOUTPUT_SELECT(2'h1),
    .BOT_8x8_MULT_REG(1'h0),
    .B_REG(1'h0),
    .B_SIGNED(32'd1),
    .C_REG(1'h0),
    .D_REG(1'h0),
    .MODE_8x8(1'h0),
    .NEG_TRIGGER(1'h0),
    .PIPELINE_16x16_MULT_REG1(1'h0),
    .PIPELINE_16x16_MULT_REG2(1'h0),
    .TOPADDSUB_CARRYSELECT(2'h3),
    .TOPADDSUB_LOWERINPUT(2'h2),
    .TOPADDSUB_UPPERINPUT(1'h1),
    .TOPOUTPUT_SELECT(2'h3),
    .TOP_8x8_MULT_REG(1'h0)
  ) product_SB_MAC16_O (
    .A(iLHS[15:0]),
    .ACCUMCI(1'hx),
    .ACCUMCO(product_SB_MAC16_O_ACCUMCO),
    .ADDSUBBOT(1'h0),
    .ADDSUBTOP(1'h0),
    .AHOLD(1'h0),
    .B(iRHS),
    .BHOLD(1'h0),
    .C(16'h0000),
    .CE(1'h1),
    .CHOLD(1'h0),
    .CI(1'hx),
    .CLK(clk),
    .CO(product_SB_MAC16_O_CO),
    .D(16'h0000),
    .DHOLD(1'h0),
    .IRSTBOT(1'h0),
    .IRSTTOP(1'h0),
    .O({ product_SB_MAC16_O_O[31:16], product[15:0] }),
    .OHOLDBOT(1'h0),
    .OHOLDTOP(1'h0),
    .OLOADBOT(1'h0),
    .OLOADTOP(1'h0),
    .ORSTBOT(1'h0),
    .ORSTTOP(1'h0),
    .SIGNEXTIN(1'hx),
    .SIGNEXTOUT(product_SB_MAC16_O_SIGNEXTOUT)
  );
  assign product[48:16] = { oOut[31], oOut };
`else
  reg signed [47:0] product;
  assign oOut = product[47:16];
  always @(posedge clk) begin
    product <= iLHS * iRHS;
  end
`endif
endmodule
