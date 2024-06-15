library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity LCD_Controller is							-- Modified from SPI usr logic from last year
    Port ( iclk : in STD_LOGIC;
			  Rx_data_valid : std_logic; 
           dataIn : in STD_LOGIC_VECTOR (7 downto 0);
			  FirstLineInput: out std_LOGIC_VECTOR(127 downto 0);
			  SecondLineInput: out std_LOGIC_VECTOR(127 downto 0)
			  );
end LCD_Controller;

architecture Behavioral of LCD_Controller is

-----------------------------------------------------------------------

signal char    : std_logic_vector(7 downto 0); 
signal input   :  std_logic_vector(127 downto 0) := X"00000000000000000000000000000000"; 
signal input0  : std_logic_vector(7 downto 0); 
signal input1  : std_logic_vector(7 downto 0); 
signal input2  : std_logic_vector(7 downto 0); 
signal input3  : std_logic_vector(7 downto 0); 
signal input4  : std_logic_vector(7 downto 0); 
signal input5  : std_logic_vector(7 downto 0); 
signal input6  : std_logic_vector(7 downto 0); 
signal input7  : std_logic_vector(7 downto 0); 
signal input8  : std_logic_vector(7 downto 0); 
signal input9  : std_logic_vector(7 downto 0); 
signal input10 : std_logic_vector(7 downto 0); 
signal input11 : std_logic_vector(7 downto 0); 
signal input12 : std_logic_vector(7 downto 0); 
signal input13 : std_logic_vector(7 downto 0); 
signal input14 : std_logic_vector(7 downto 0); 
--signal input15 : std_logic_vector(7 downto 0);
--signal input16 : std_logic_vector(7 downto 0); 
--signal input17 : std_logic_vector(7 downto 0); 
--signal input18 : std_logic_vector(7 downto 0); 
--signal input19 : std_logic_vector(7 downto 0); 
--signal input20 : std_logic_vector(7 downto 0); 
--signal input21 : std_logic_vector(7 downto 0); 
--signal input22 : std_logic_vector(7 downto 0); 
--signal input23 : std_logic_vector(7 downto 0); 
--signal input24 : std_logic_vector(7 downto 0); 
--signal input25 : std_logic_vector(7 downto 0); 
--signal input26 : std_logic_vector(7 downto 0); 
--signal input27 : std_logic_vector(7 downto 0); 
--signal input28 : std_logic_vector(7 downto 0); 
--signal input29 : std_logic_vector(7 downto 0); 
--signal input30 : std_logic_vector(7 downto 0); 

-----------------------------------------------------------------------
-- maybe need to change to opposite direction( shift register)
begin 

-- when rx-data-valid is high the state changes 
-- moves so fast that it will send at once 
-- message on top and _ _ _ on bottom
process(Rx_data_valid)
begin  
if Rx_data_valid = '1' then
	char    <= dataIn; 
	input0  <= char;
	input1  <= input0; 
	input2  <= input1; 
	input3  <= input2; 
	input4  <= input3;
	input5  <= input4; 
	input6  <= input5; 
	input7  <= input6; 
	input8  <= input7;
	input9  <= input8; 
	input10 <= input9; 
	input11 <= input10; 
	input12 <= input11;
	input13 <= input12; 
	input14 <= input13; 
--	input15 <= input14; 
--	input16 <= input15;
--	input17 <= input16; 
--	input18 <= input17;
--	input19 <= input18; 
--	input20 <= input19; 
--	input21 <= input20; 
--	input22 <= input21;
--	input23 <= input22; 
--	input24 <= input23;
--	input25 <= input24; 
--	input26 <= input25; 
--	input27 <= input26; 
--	input28 <= input27;
--	input29 <= input28; 
--	input30 <= input29;


	
   input <=  input14 & input13 & input12 & input11 & input10 & input9 & input8 & input7 & input6 & input5 & input4 & input3 & input2 & input1 & input0 & char;   -- & input15 & input16 & input17 & input18 & input19 & input20 & input21 & input22 & input23 & input24 & input25 & input26 & input27 & input28 & input29 & input30;
end if; 
end process;  

process(char) 
begin 
if char = X"5F" then 
secondLineInput <= input;
else 
firstLineInput <= input;
end if; 
end process;
	
end Behavioral; 

