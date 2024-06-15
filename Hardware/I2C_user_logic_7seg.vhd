library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity I2C_user_logic_7seg is							-- Modified from SPI usr logic from last year
    Port ( iclk : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (15 downto 0);
           oSDA : inout STD_LOGIC;
           oSCL : inout STD_LOGIC);
end I2C_user_logic_7seg;

architecture Behavioral of I2C_user_logic_7seg is

------------------------------------------------------------------------------------------------------------------
component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; 					--input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   					--speed the i2c bus (scl) will run at in Hz (7-Segment can run from 100khz(slow mode) to 400khz(high speed mode))
  PORT(
    clk       : IN     STD_LOGIC;                    	--system clock
    reset_n   : IN     STD_LOGIC;                    	--active low reset
    ena       : IN     STD_LOGIC;                    	--latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); 	--address of target slave
    rw        : IN     STD_LOGIC;                    	--'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); 	--data to write to slave
    busy      : OUT    STD_LOGIC;                    	--indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); 	--data read from slave
    ack_error : BUFFER STD_LOGIC;                    	--flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    	--serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   	--serial clock output of i2c bus
END component i2c_master;
------------------------------------------------------------------------------------------------------------------
signal regBusy,sigBusy,reset,enable,rw_sig : std_logic;

signal wData : std_logic_vector(15 downto 0);

signal dataOut : std_logic_vector(7 downto 0);

signal byteSel : integer := 1;

type state_type is (start,write,stop);

signal State : state_type := start;

signal address : std_logic_vector(6 downto 0);

signal Counter : integer := 16383;			-- delay time when a new data transaction occurs

begin
------------------------------------------------------------------------------------------------------------------
INST_I2C_master: i2c_master
	Generic map(input_clk => 50_000_000,bus_clk=> 400_000)
	port map (
		clk=>iclk,
		reset_n=>reset,
		ena=>enable,
		addr=>address,						-- For implementation of 2 or more components, link address to a mux to select which component.
		rw=>rw_sig,
		data_wr=>dataOut,
		busy=>sigBusy,
		data_rd=>OPEN,
		ack_error=>open,					--Prof told to leave open :D, not my fault if 7 Seg blows up for somereason ¯\_(ツ)_/¯ 		
		sda=>oSDA,
		scl=>oSCL
		);
	
------------------------------------------------------------------------------------------------------------------
StateChange: process (iClk)
begin
	if rising_edge(iClk) then
		case State is
		
			when start =>
				if Counter /= 0 then
					Counter<=Counter-1;
					reset<='0';
					State<=start;
					enable<='0';
				else
					reset<='1';					-- Sent to I2C master to start ready transaction
					enable<='1';				-- Sent to I2C master to transition to start state.
					
					address<="1110001";		-- Hardcoded to X"71", 7seg's default address
					rw_sig<='0';				-- Only writing in this project
					State<=write;
				end if;
			
			when write=>
				regBusy <= sigBusy;
				wData <= dataIn;
			
				if regBusy /= sigBusy and sigBusy = '0' then
					if byteSel /= 13 then
						byteSel <= byteSel+1;
						State <= write;
					else
						byteSel <= 8;
						State<=stop;
					end if;
				end if;
			
			when stop=>
				enable<='0';
				if wData/=dataIn then	-- Halts transaction at slv_ack2 state until new iData comes in
					State<=start;
				else
					State<=stop;
				end if;
			end case;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------
process(byteSel,iClk)
begin
    case byteSel is
        when 1 => dataOut <= x"76";
        when 2 => dataOut <= x"76";
        when 3 => dataOut <= x"76";
        when 4 => dataOut <= x"7A";
        when 5 => dataOut <= x"FF";
        when 6 => dataOut <= x"77";
        when 7 => dataOut <= x"00";
        when 8 => dataOut <= x"79";
        when 9 => dataOut <= x"00";
        when 10 => dataOut <= x"0" & dataIn(15 downto 12);
        when 11 => dataOut <= x"0" & dataIn(11 downto 8);
        when 12 => dataOut <= x"0" & dataIn(7 downto 4);
        when 13 => dataOut <= x"0" & dataIn(3 downto 0);
        when others => dataOut <= x"76";
    end case;
end process;
------------------------------------------------------------------------------------------------------------------
end Behavioral;



--TODO:
-- Fully implement read functionality of I2C(including NACK)