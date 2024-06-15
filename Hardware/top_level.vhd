LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY top_level IS
  GENERIC(
      clk_freq                  : INTEGER := 50_000_000; --system clock frequency in Hz
      ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
      clk        : IN  STD_LOGIC;                     --system clock input
      ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); --ASCII value
		i_RX_Serial : IN  STD_LOGIC; 
		ascii       : buffer STD_LOGIC_VECTOR(7 downto 0);
		o_TX_Active : out std_logic;
      o_TX_Serial : out std_logic;
      o_TX_Done   : out std_logic; 
		oSDA        : INOUT STD_LOGIC;
		oSCL        : INOUT STD_LOGIC;
		oLCDSDA     : INOUT STD_LOGIC;  
      oLCDSCL     : INOUT STD_LOGIC   
    );
END top_level;

ARCHITECTURE behavior OF top_level IS
  TYPE machine IS(ready, new_code, translate, output);              --needed states
  SIGNAL state             : machine;                               --state machine
  SIGNAL ascii_new                : STD_LOGIC;                     --output flag indicating new ASCII value
  SIGNAL ps2_code_new      : STD_LOGIC;                             --new PS2 code flag from ps2_keyboard component
  SIGNAL ps2_code          : STD_LOGIC_VECTOR(7 DOWNTO 0);          --PS2 code input form ps2_keyboard component
  SIGNAL prev_ps2_code_new : STD_LOGIC := '1';                      --value of ps2_code_new flag on previous clock
  SIGNAL break             : STD_LOGIC := '0';                      --'1' for break code, '0' for make code
  SIGNAL e0_code           : STD_LOGIC := '0';                      --'1' for multi-code commands, '0' for single code commands
--  SIGNAL ascii             : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"FF"; --internal value of ASCII translation
  SIGNAL keyboard_sig      : STD_LOGIC := '0'; -- Pulse signal from keyboard to UART_TX 
 
  --SIGNAL dataIn            : STD_LOGIC_VECTOR(15 DOWNTO 0); --DATA IN to 7-seg 
  SIGNAL dataInLUT         : STD_LOGIC_VECTOR(7 DOWNTO 0);  --Data sent from Rx 
  SIGNAL dataOutLUT        : STD_LOGIC_VECTOR(15 DOWNTO 0);  
  SIGNAL firstline         : STD_LOGIC_VECTOR(127 downto 0);
  SIGNAL secondline        : STD_LOGIC_VECTOR(127 downto 0);
  SIGNAL o_RX_DV           : std_logic; 
  SIGNAL DatainLCD         : std_LOGIC_VECTOR(15 downto 0); 

  --declare PS2 keyboard interface component
  COMPONENT ps2_keyboard IS
    GENERIC(
      clk_freq              : INTEGER;  --system clock frequency in Hz
      debounce_counter_size : INTEGER); --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
    PORT(
      clk          : IN  STD_LOGIC;                     --system clock
      ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      ps2_data     : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
      ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
  END COMPONENT;

  Component UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 5208     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_TX_DV     : in  std_logic;
    i_TX_Byte   : in  std_logic_vector(7 downto 0);
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic
    );
end COMPONENT;


Component UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 5208     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end Component;

Component ASCIITo7SegLUT is
   port(
		asciiData : in std_logic_vector(7 downto 0);
		oSevenSegmentData : out std_logic_vector(15 downto 0)
   );
end Component;

Component I2C_user_logic_7seg is							-- Modified from SPI usr logic from last year
    Port ( iclk : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (15 downto 0);
           oSDA : inout STD_LOGIC;
           oSCL : inout STD_LOGIC);
end Component;


Component LCD_Controller is							-- Modified from SPI usr logic from last year
    Port ( iclk : in STD_LOGIC;
			  Rx_data_valid : std_logic; 
           dataIn : in STD_LOGIC_VECTOR (7 downto 0);
			  FirstLineInput: out std_LOGIC_VECTOR(127 downto 0);
			  SecondLineInput: out std_LOGIC_VECTOR(127 downto 0)
			  );
end Component;


Component LCDI2C_user_logic is							-- Modified from SPI usr logic from last year
    Port ( iclk : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (15 downto 0);
			  FirstLineInput: in std_LOGIC_VECTOR(127 downto 0);
			  SecondLineInput: in std_LOGIC_VECTOR(127 downto 0);
           oLCDSDA : inout STD_LOGIC;
           oLCDSCL : inout STD_LOGIC
			  );
end Component;
 
BEGIN

  datainLCD <= "00000000" & dataInLUT; 

  --instantiate PS2 keyboard interface logic
  ps2_keyboard_0:  ps2_keyboard
    GENERIC MAP(clk_freq => clk_freq, debounce_counter_size => ps2_debounce_counter_size)
    PORT MAP(clk => clk, 
				ps2_clk => ps2_clk, 
				ps2_data => ps2_data, 
				ps2_code_new => ps2_code_new, 
				ps2_code => ps2_code); 
	 
inst_UART_TX : UART_TX 
  generic map(
    g_CLKS_PER_BIT => 5208     -- Needs to be set correctly
    )
  port map (
    i_Clk => clk,      
    i_TX_DV => keyboard_sig,   
    i_TX_Byte => ascii,  
    o_TX_Active => o_TX_Active,
    o_TX_Serial => o_TX_Serial,
    o_TX_Done   => o_TX_Done
    );

	 
inst_UART_RX : UART_RX
  generic map(
    g_CLKS_PER_BIT => 5208      -- Needs to be set correctly
    )
  port map(
    i_Clk       => clk, 
    i_RX_Serial => i_RX_Serial,  
    o_RX_DV     => o_RX_DV,  
    o_RX_Byte   => dataInLUT  
    );

inst_ASCIITo7SegLUT : ASCIITo7SegLUT
   port map(
		asciiData => dataInLUT, 
		oSevenSegmentData => DataOutLUT
   );

	
inst_I2C_USER : I2C_user_logic_7seg 							-- Modified from SPI usr logic from last year
    Port map( iclk   => clk,
           dataIn => DataOutLUT, -- Probably fix later 
           oSDA   => oSDA,
           oSCL   => oSCL
			  );

isnt_LCD_Controller: LCD_Controller 							-- Modified from SPI usr logic from last year
    Port map ( iclk => clk,
			  Rx_data_valid => o_RX_DV,
           dataIn => dataInLUT,
			  FirstLineInput => firstline,
			  SecondLineInput => secondline
			  );		  
			  
			  
			 
inst_LCD_user : LCDI2C_user_logic 							-- Modified from SPI usr logic from last year
    Port map( iclk         => clk,
           dataIn          => datainLCD,
			  FirstLineInput  => firstline,
			  SecondLineInput => secondline,
          oLCDSDA         => oLCDSDA,       
          oLCDSCL         => oLCDSCL
			  );			  

  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN
      prev_ps2_code_new <= ps2_code_new; --keep track of previous ps2_code_new values to determine low-to-high transitions
      CASE state IS
      
        --ready state: wait for a new PS2 code to be received
        WHEN ready =>
          IF(prev_ps2_code_new = '0' AND ps2_code_new = '1') THEN --new PS2 code received
            ascii_new <= '0';                                       --reset new ASCII code indicator
            state <= new_code;                                      --proceed to new_code state
          ELSE                                                    --no new PS2 code received yet
            state <= ready;                                         --remain in ready state
          END IF;
          
        --new_code state: determine what to do with the new PS2 code  
        WHEN new_code =>
          IF(ps2_code = x"F0") THEN    --code indicates that next command is break
            break <= '1';                --set break flag
            state <= ready;              --return to ready state to await next PS2 code
          ELSIF(ps2_code = x"E0") THEN --code indicates multi-key command
            e0_code <= '1';              --set multi-code command flag
            state <= ready;              --return to ready state to await next PS2 code
          ELSE                         --code is the last PS2 code in the make/break code
            ascii(7) <= '1';             --set internal ascii value to unsupported code (for verification)
            state <= translate;          --proceed to translate state
          END IF;

        --translate state: translate PS2 code to ASCII value
        WHEN translate =>
            break <= '0';    --reset break flag
            e0_code <= '0';  --reset multi-code command flag
            
--         
                CASE ps2_code IS              
                  WHEN x"1C" => ascii <= x"61"; --a
                  WHEN x"32" => ascii <= x"62"; --b
                  WHEN x"21" => ascii <= x"63"; --c
                  WHEN x"23" => ascii <= x"64"; --d
                  WHEN x"24" => ascii <= x"65"; --e
                  WHEN x"2B" => ascii <= x"66"; --f
                  WHEN x"34" => ascii <= x"67"; --g
                  WHEN x"33" => ascii <= x"68"; --h
                  WHEN x"43" => ascii <= x"69"; --i
                  WHEN x"3B" => ascii <= x"6A"; --j
                  WHEN x"42" => ascii <= x"6B"; --k
                  WHEN x"4B" => ascii <= x"6C"; --l
                  WHEN x"3A" => ascii <= x"6D"; --m
                  WHEN x"31" => ascii <= x"6E"; --n
                  WHEN x"44" => ascii <= x"6F"; --o
                  WHEN x"4D" => ascii <= x"70"; --p
                  WHEN x"15" => ascii <= x"71"; --q
                  WHEN x"2D" => ascii <= x"72"; --r
                  WHEN x"1B" => ascii <= x"73"; --s
                  WHEN x"2C" => ascii <= x"74"; --t
                  WHEN x"3C" => ascii <= x"75"; --u
                  WHEN x"2A" => ascii <= x"76"; --v
                  WHEN x"1D" => ascii <= x"77"; --w
                  WHEN x"22" => ascii <= x"78"; --x
                  WHEN x"35" => ascii <= x"79"; --y
                  WHEN x"1A" => ascii <= x"7A"; --z
                  WHEN OTHERS => NULL;
                END CASE;
          
          IF(break = '0') THEN  --the code is a make
            state <= output;      --proceed to output state
          ELSE                  --code is a break
            state <= ready;       --return to ready state to await next PS2 code
          END IF;
        
        --output state: verify the code is valid and output the ASCII value
        WHEN output =>
          IF(ascii(7) = '0') THEN            --the PS2 code has an ASCII output
            ascii_new <= '1';                  --set flag indicating new ASCII output
            ascii_code <= ascii(6 DOWNTO 0);   --output the ASCII value
          END IF;
          state <= ready;                    --return to ready state to await next PS2 code

      END CASE;
    END IF;
  END PROCESS;
 
process(break)
begin 
if break = '1' then 
  keyboard_sig <= '1';  
else 
  keyboard_sig <= '0';
end if; 

end process;

END behavior;


