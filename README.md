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
### Module Name 
- shift_reg
### Inputs
- clk  &emsp; : System clock (Max Operating Frequency: 400 Mhz)
- nrst &ensp; : This is an asynchronous, active-low system reset. When this line is  asserted(logic ‘0’), all <br> &emsp; &emsp; &nbsp; &nbsp; registers/flip-flops in the device must reset to their initial value.
- D &emsp; &nbsp; : Serial Input to the shift register.
- mode_i [1:0] :  
  - hold &nbsp;: when mode_i = 2’b00, value in shift register doesn’t change.
  - load &nbsp;: when mode_i = 2’b01, store value of par_i in the register.
  - left &nbsp;: when mode_i = 2’b10, shift register contents to the left.
  - right : when mode_i  = 2’b11, shift register contents to the right.

 

