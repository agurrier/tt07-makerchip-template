\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   
   // ########################################################
   // #                                                      #
   // #  Empty template for Tiny Tapeout Makerchip Projects  #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, tt_um_example)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   var(in_fpga, 1)   /// 1 to include the demo board. (Note: Logic will be under /fpga_pins/fpga.)
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])


\TLV my_design()
   
   |mastermind
      @0
         $in[7:0] = *ui_in[7:0];
         $in_b2[7:0] = >>2$in;
         
         $in_hit = $in[7:0] != 8'b0;
         $in_hit_b2 = >>2$in_hit;
         $din_hit_b2 = >>1$in_hit_b2;
         $ndin_hit_b2 = !$din_hit_b2;
         $in_hit_edge = $ndin_hit_b2 && $in_hit_b2;
         
         //MODULE 1: GET ANSWER
         $reset = *reset;
         
         $counter[11:0] = >>1$counter + 1;
         
         $valid1 = $in_hit_edge;
         
      @1
         
         $ans[11:0] = $reset
                                                            ? 12'b0 :
                      $in_pushed && (>>1$got_ans == 1'b0) && >>1$no_repeat 
                                                            ? $counter[11:0] :
                      //default
                                                              >>1$ans[11:0] ;
         $got_ans = $ans[11:0] != 12'b0;
         
         $no_repeat = !($counter[11:9] == $counter[8:6] || 
                                 $counter[11:9] == $counter[5:3] || 
                                 $counter[11:9] == $counter[2:0] || 
                                 $counter[8:6] == $counter[5:3] || 
                                 $counter[8:6] == $counter[2:0] || 
                                 $counter[5:3] == $counter[2:0]) ;
         $in_pushed = $reset 
                           ? 1'b0 :
                      $valid1
                           ? 1'b1 :
                     //default
                           >>1$in_pushed;
         
                           /*
         $in_release = $reset 
                           ? 1'b0 :
                      !$valid1 && $in_pushed
                           ? 1'b1 :
                     //default
                           >>1$in_release;
                           */
                           
         //MODULE 2: GET GUESS
         
         $valid = ($in_hit_edge) && $got_ans;
         $dvalid = >>1$valid;
         $ndvalid = !$dvalid;
         $in_push = $ndvalid && $valid;
         
         $red[2:0] = 3'b000;
         $yellow[2:0] = 3'b001;
         $green[2:0] = 3'b010;
         $blue[2:0] = 3'b011;
         $orange[2:0] = 3'b100;
         $black[2:0] = 3'b101;
         $white[2:0] = 3'b110;
         $purple[2:0] = 3'b111;
         
         $guess[2:0] = $in_b2 == 8'b00000001 ? $red : //$in_b2[0] ? $red :
                       $in_b2 == 8'b00000010 ? $yellow :
                       $in_b2 == 8'b00000100 ? $green :
                       $in_b2 == 8'b00001000 ? $blue :
                       $in_b2 == 8'b00010000 ? $orange :
                       $in_b2 == 8'b00100000 ? $black :
                       $in_b2 == 8'b01000000 ? $white :
                       //8'b10000000 ? 
                                     $purple;
         $color_guess[11:0] = {$temp4, $temp3, $temp2, $temp1};
         
         $color_cnt[2:0] = $reset
                                    ? 3'b0 :
                           >>1$newround
                                   ? 3'b0 :
                       $in_push && >>1$color_cnt == 3'b000 
                                    ? >>1$color_cnt + 1 :
                       $in_push && >>1$color_cnt == 3'b001 && ($guess[2:0] != >>1$color_guess[2:0])
                                    ? >>1$color_cnt + 1 :
                       $in_push && >>1$color_cnt == 3'b010 && ($guess[2:0] != >>1$color_guess[2:0]) && ($guess[2:0] != >>1$color_guess[5:3])
                                    ? >>1$color_cnt + 1 :
                       $in_push && >>1$color_cnt == 3'b011 && ($guess[2:0] != >>1$color_guess[2:0]) && ($guess[2:0] != >>1$color_guess[5:3]) && ($guess[2:0] != >>1$color_guess[8:6])
                                    ? >>1$color_cnt + 1 :
                             //default
                                    >>1$color_cnt ;
         $got_guess = $color_cnt[2:0] == 3'b100;
         
         $dgot_guess = >>1$got_guess;
         $ndgot_guess = !$dgot_guess;
         $got_guess_edge = $ndgot_guess && $got_guess;
         
         
         $temp1[2:0] = $reset
                                    ? 3'b0 :
                       $in_push && >>1$color_cnt == 3'b000 
                                    ? $guess[2:0] :
                             //default
                                    >>1$color_guess[2:0] ;
         $temp2[2:0] = $reset
                                    ? 3'b0 :
                       $in_push && >>1$color_cnt == 3'b001 
                                    ? $guess[2:0] :
                             //default
                                    >>1$color_guess[5:3] ;
         $temp3[2:0] = $reset
                                    ? 3'b0 :
                       $in_push && >>1$color_cnt == 3'b010 
                                    ? $guess[2:0] :
                             //default
                                    >>1$color_guess[8:6] ;
         $temp4[2:0] = $reset
                                    ? 3'b0 :
                       $in_push && >>1$color_cnt == 3'b011 
                                    ? $guess[2:0] :
                             //default
                                    >>1$color_guess[11:9] ;
         // MODULE 3: GET RESULT
         
         $get_results_valid = $got_ans && $dgot_guess;
         
         $light_code[7:0] = $reset
                                       ? 8'b0 :
                              $lose
                                       ? >>1$lose_light :
                              $win
                                       ? >>1$win_light :
                              //default
                                       {$light_color[3:0], $light_pos[3:0]};
         
         
         $light_pos[3:0] = $reset  ? 4'b0000 :
                           $light_pos_cnt == 3'b001 ? 4'b0001 :
                           $light_pos_cnt == 3'b010 ? 4'b0011 :
                           $light_pos_cnt == 3'b011 ? 4'b0111 :
                           $light_pos_cnt == 3'b100 ? 4'b1111 :
                           //default
                                                      4'b0000 ;
         $light_color[3:0] = $reset  ? 4'b0000 :
                           $light_color_cnt == 3'b001 ? 4'b0001 :
                           $light_color_cnt == 3'b010 ? 4'b0011 :
                           $light_color_cnt == 3'b011 ? 4'b0111 :
                           $light_color_cnt == 3'b100 ? 4'b1111 :
                           //default
                                                      4'b0000 ;
         
         $light_pos_cnt[2:0] = $reset
                                       ? 3'b0 :
                               $got_guess_edge
                                       ? 3'b0 :
                          $color_guess[2:0] == $ans[2:0] && >>1$cnt1 == 3'b000 && $get_results_valid
                                                ? >>1$light_pos_cnt +1 :
                          $color_guess[5:3] == $ans[5:3] && >>1$cnt1 == 3'b001 && $get_results_valid
                                                ? >>1$light_pos_cnt +1 :
                          $color_guess[8:6] == $ans[8:6] && >>1$cnt1 == 3'b010 && $get_results_valid
                                                ? >>1$light_pos_cnt +1 :
                          $color_guess[11:9] == $ans[11:9] && >>1$cnt1 == 3'b011 && $get_results_valid
                                                ? >>1$light_pos_cnt +1 :
                          //default 
                                                >>1$light_pos_cnt ;
         $cnt1[2:0] = $reset
                                   ? 3'b0 :
                      >>1$newround
                                   ? 3'b0 :
                 >>1$cnt1[2:0] != 3'b100 && $get_results_valid
                                   ? >>1$cnt1[2:0] +1:
                 //default
                                    >>1$cnt1[2:0];
         
         $light_color_cnt[2:0] = $reset
                                       ? 3'b0 :
                                 $got_guess_edge
                                       ? 3'b0 :
                          ($color_guess[2:0] == $ans[2:0] || 
                           $color_guess[2:0] == $ans[5:3] || 
                           $color_guess[2:0] == $ans[8:6] || 
                           $color_guess[2:0] == $ans[11:9]) && 
                                               >>1$cnt1 == 3'b000 && $get_results_valid
                                                ? >>1$light_color_cnt +1 :
                          ($color_guess[5:3] == $ans[2:0] || 
                           $color_guess[5:3] == $ans[5:3] || 
                           $color_guess[5:3] == $ans[8:6] || 
                           $color_guess[5:3] == $ans[11:9]) && 
                                               >>1$cnt1 == 3'b001 && $get_results_valid
                                                ? >>1$light_color_cnt +1 :
                          ($color_guess[8:6] == $ans[2:0] || 
                           $color_guess[8:6] == $ans[5:3] || 
                           $color_guess[8:6] == $ans[8:6] || 
                           $color_guess[8:6] == $ans[11:9]) && 
                                               >>1$cnt1 == 3'b010 && $get_results_valid
                                                ? >>1$light_color_cnt +1 :
                          ($color_guess[11:9] == $ans[2:0] || 
                           $color_guess[11:9] == $ans[5:3] || 
                           $color_guess[11:9] == $ans[8:6] || 
                           $color_guess[11:9] == $ans[11:9]) && 
                                               >>1$cnt1 == 3'b011 && $get_results_valid
                                                ? >>1$light_color_cnt +1 :
                          //default 
                                                >>1$light_color_cnt ;
         
         $round[3:0] = $reset ? 4'b0 :
                  $cnt1 == 3'b100 ? >>1$round + 1:
                  //default
                                    >>1$round;
         $cnt1_done = $cnt1 == 3'b100;
         $dcnt1_done = >>1$cnt1_done;
         $ndcnt1_done = !$dcnt1_done;
         $newround = $ndcnt1_done && $cnt1_done && $round != 4'b1011 && !$win;
         
         $lose = ($round == 4'b1010) && ({>>1$light_color[3:0], >>1$light_pos[3:0]} != 8'b11111111);
         $win = ({$light_color[3:0], $light_pos[3:0]} == 8'b11111111);
         
         $lose_cnt[21:0] = >>1$lose_cnt + 1;
         $win_cnt[18:0] = >>1$win_cnt + 1;
         
         $lose_light[7:0] = $lose && !>>1$lose
                                                          ? 8'b00000000 :
                             >>1$lose_cnt == 22'b1111111111111111111111
                                                          ? {!>>1$lose_light[7],
                                                             !>>1$lose_light[6],
                                                             !>>1$lose_light[5],
                                                             !>>1$lose_light[4],
                                                             !>>1$lose_light[3],
                                                             !>>1$lose_light[2],
                                                             !>>1$lose_light[1],
                                                             !>>1$lose_light[0]}: //~ for not
                             // default
                                                            >>1$lose_light ;
         
         $win_light[7:0] = $win && !>>1$win
                                                          ? 8'b00000001 :
                             >>1$win_light == 8'b10000000 && >>1$win_cnt == 19'b1111111111111111111
                                                          ? 8'b00000001 :
                             >>1$win_cnt == 19'b1111111111111111111
                                                          ? >>1$win_light << 1 :
                             // default
                                                          >>1$win_light ;
         
         *uo_out = $light_code;
   
   // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   
   
   
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   //*uo_out = 8'b0;
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

// Set up the Tiny Tapeout lab environment.
\TLV tt_lab()
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in, uio_out, uio_oe;'])
   logic [31:0] r;  // a random value
   always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   //assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
  /* 
   initial begin
      
      
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'h0;
      #200
      #2
      	ui_in = 8'b10000000;
      #6
      	ui_in = 8'h0;
      #200
      #2
      	ui_in = 8'b00010000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b00000100;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000010;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000001;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00000001;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00010000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000010;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00001000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #20
      #2
      	ui_in = 8'b10000000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00000001;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00010000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000010;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00001000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #20
      #2
      	ui_in = 8'b10000000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00000001;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00010000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000010;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00001000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #20
      #2
      	ui_in = 8'b10000000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00000001;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00010000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000010;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00001000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #20
      #2
      	ui_in = 8'b10000000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b01000000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00000001;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00010000;
      #6
      	ui_in = 8'h0;
      #32
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00000010;
      #2
      	ui_in = 8'h0;
      #12
      #2
      	ui_in = 8'b00010000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00001000;
      #2
      	ui_in = 8'h0;
      #40
      #2
      	ui_in = 8'b00100000;
      #2
      	ui_in = 8'h0;
         
      
   end
   */
   

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 1500 || !clk;
   assign failed = 1'b0 || !clk;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;

\TLV
   /* verilator lint_off UNOPTFLAT */
   m5_if(m5_in_fpga, ['m5+tt_lab()'], ['m5+my_design()'])

\SV_plus
   
   // ==========================================
   // If you are using Verilog for your design,
   // your Verilog logic goes here.
   // Note, output assignments are in my_design.
   // ==========================================

\SV
endmodule
