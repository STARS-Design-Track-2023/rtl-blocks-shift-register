# Shift Register

## Installation
To clone the repository go to a safe directory and in the terminal type the following <br> 
```
git clone git@github.com:STARS-Design-Track-2023/rtl-blocks-shift_register.git
```

## Source Files
- shift_reg.sv : This is where the design code should be located.
- tb_shift_reg.sv : This is the test bench used to test your design. Credit: Xinyu Yang

## Specifations
### <u>Module Name</u> 
- shift_reg
### <u>Inputs</u>
- clk  &emsp; : System clock (Max Operating Frequency: 400 Mhz)
- nrst &ensp; : This is an asynchronous, active-low system reset. When this line is  asserted(logic ‘0’), all <br> &emsp; &emsp; &nbsp; &nbsp; registers/flip-flops in the device must reset to their initial value.
- D &emsp; &nbsp; : Serial Input to the shift register.
- mode_i [1:0] :  
  - hold &nbsp;: when mode_i = 2’b00, value in shift register doesn’t change.
  - load &nbsp;: when mode_i = 2’b01, store value of par_i in the register.
  - left &nbsp;: when mode_i = 2’b10, shift register contents to the left.
  - right : when mode_i  = 2’b11, shift register contents to the right.
- par_i [7:0] &nbsp; : Parallel input to the shift register.
### <u>Outputs</u>
- P [7:0] : Parallel output of the shift register.
## Behaviour
This design implements a parallel to parallel or serial to parallel (MSB or LSB) shift register. The behavior of the shift register is determined by the mode_i input of the module.
## Instructions
1. Clone the code from github.
2. Run `make dir` to cofigure directory for the project.
3. Make an rtl-diagram for the shift register and have the design approved by a TA. **Make sure your design is located in the docs directory.**
4. Code your design in system verilog.
5. Run `make help`/`make` to see the make file targets.
6. Have both source and mapped versions of your code working.
## Expected Results
Use the following signal dump to debug your HDL.
<p align="center">
    ![GTKwave Simulation!](/img/sig_dump.png "GTKwave simulation")
</p>

 

