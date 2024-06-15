library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCIITo7SegLUT is
   port(
		asciiData : in std_logic_vector(7 downto 0);
		oSevenSegmentData : out std_logic_vector(15 downto 0)
   );
end ASCIITo7SegLUT;

architecture Behavioral of ASCIITo7SegLUT is
begin
oSevenSegmentData <= "0000000000000000" when asciiData = "00110000" else
"0000000000000001" when asciiData = "00110001" else
"0000000000000010" when asciiData = "00110010" else
"0000000000000011" when asciiData = "00110011" else
"0000000000000100" when asciiData = "00110100" else
"0000000000000101" when asciiData = "00110101" else
"0000000000000110" when asciiData = "00110110" else
"0000000000000000";
end Behavioral;