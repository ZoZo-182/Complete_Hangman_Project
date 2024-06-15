library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity LCDI2C_user_logic is							-- Modified from SPI usr logic from last year
    Port ( iclk : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (15 downto 0);
			  FirstLineInput: in std_LOGIC_VECTOR(127 downto 0);
			  SecondLineInput: in std_LOGIC_VECTOR(127 downto 0);
           oLCDSDA : inout STD_LOGIC;
           oLCDSCL : inout STD_LOGIC
			  );
end LCDI2C_user_logic;

architecture Behavioral of LCDI2C_user_logic is

------------------------------------------------------------------------------------------------------------------
component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component i2c_master;
------------------------------------------------------------------------------------------------------------------
signal regBusy,sigBusy,reset,enable,rw_sig : std_logic;

signal prev_data : std_logic_vector(127 downto 0);
signal prev_data1 : std_logic_vector(127 downto 0);

signal dataOut : std_logic_vector(7 downto 0):= "00000000";

signal byteSel : integer range 0 to 180 := 0;

type state_type is (start,write,stop);

signal State : state_type := start;

signal address : std_logic_vector(6 downto 0);

signal Counter : integer range 0 to 16383 := 16383;			-- delay time when a new data transaction occurs



begin
------------------------------------------------------------------------------------------------------------------
INST_I2C_master: i2c_master
	Generic map(input_clk => 50_000_000,bus_clk=> 100_000)
	port map (
		clk=>iclk,
		reset_n=>reset,
		ena=>enable,
		addr=>address,						-- For implementation of 2 or more components, link address to a mux to select which component.
		rw=>rw_sig,
		data_wr=>dataOut,
		busy=>sigBusy,
		data_rd=> OPEN,
		ack_error=> open,					--Prof told to leave open :D, not my fault if 7 Seg blows up for somereason |_(ツ)_|	
		sda=>oLCDSDA,
		scl=>oLCDSCL
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
					address<="0100111";		-- Hardcoded to X"27", LCD's default address
					rw_sig<='0';				-- Only writing in this project
					State<=write;
				end if;
			
			when write=>
				enable<='1';				-- Sent to I2C master to transition to start state.
				regBusy <= sigBusy;
				prev_Data <= SecondLineInput;		-- Will rewrite new data if detects new data
				prev_data1 <= FirstLineInput;
				if regBusy /= sigBusy and sigBusy = '0' then
					if byteSel /= 180 then
						byteSel <= byteSel+1;
						State <= write;
					else
						byteSel <= 45;
						State<=stop;
					end if;
				end if;
			
			when stop=>
				enable<='0';
				if prev_Data /= SecondLineInput or prev_data1 /= FirstLineInput then	-- Halts transaction at slv_ack2 state until new iData comes in
					State<=start;
				else
					State<=stop;
				end if;
			end case;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------
process(byteSel,FirstLineInput,SecondLineInput)
begin
    case byteSel is
	 -- D7, D6, D5, D4, LED:= '1', EN ,R/W , RS
	 -- STARTS WITH ALL 0
	 
when 0  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 1  => dataOut <= x"3" & '1' & '1' & '0' & '0';
when 2  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 3  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 4  => dataOut <= x"8" & '1' & '0' & '0' & '0';

when 5  => dataOut <= x"3" & '1' & '1' & '0' & '0';
when 6  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 7  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 8  => dataOut <= x"8" & '1' & '0' & '0' & '0';

when 9  => dataOut <= x"3" & '1' & '1' & '0' & '0';
when 10  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 11  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 12  => dataOut <= x"8" & '1' & '0' & '0' & '0';

when 13  => dataOut <= x"3" & '1' & '1' & '0' & '0';
when 14  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 15  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 16  => dataOut <= x"8" & '1' & '0' & '0' & '0';

when 17  => dataOut <= x"3" & '1' & '1' & '0' & '0';
when 18  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 19  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 20  => dataOut <= x"8" & '1' & '0' & '0' & '0';

when 21  => dataOut <= x"3" & '1' & '1' & '0' & '0';     --INIT
when 22  => dataOut <= x"3" & '1' & '0' & '0' & '0';
when 23  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 24  => dataOut <= x"8" & '1' & '0' & '0' & '0';

when 25  => dataOut <= x"0" & '1' & '1' & '0' & '0';     --4bit mode
when 26  => dataOut <= x"0" & '1' & '0' & '0' & '0';
when 27  => dataOut <= x"2" & '1' & '1' & '0' & '0';
when 28  => dataOut <= x"2" & '1' & '0' & '0' & '0';

when 29  => dataOut <= x"2" & '1' & '1' & '0' & '0';     --4 bit mode and others
when 30  => dataOut <= x"2" & '1' & '0' & '0' & '0';
when 31  => dataOut <= x"8" & '1' & '1' & '0' & '0';
when 32  => dataOut <= x"8" & '1' & '0' & '0' & '0';
    
when 33  => dataOut <= x"0" & '1' & '1' & '0' & '0';     --Clear ALL
when 34  => dataOut <= x"0" & '1' & '0' & '0' & '0';
when 35  => dataOut <= x"1" & '1' & '1' & '0' & '0';
when 36  => dataOut <= x"1" & '1' & '0' & '0' & '0';

when 37  => dataOut <= x"0" & '1' & '1' & '0' & '0';     --Cursor @firstline first spot
when 38  => dataOut <= x"0" & '1' & '0' & '0' & '0';
when 39  => dataOut <= x"C" & '1' & '1' & '0' & '0';
when 40  => dataOut <= x"C" & '1' & '0' & '0' & '0';
        
when 41  => dataOut <= x"0" & '1' & '1' & '0' & '0';     --shift Cursor right every time
when 42  => dataOut <= x"0" & '1' & '0' & '0' & '0';
when 43  => dataOut <= x"6" & '1' & '1' & '0' & '0';
when 44  => dataOut <= x"6" & '1' & '0' & '0' & '0';


when 45  => dataOut <= x"8" & '1' & '1' & '0' & '0';     --First line
when 46  => dataOut <= x"8" & '1' & '0' & '0' & '0';
when 47  => dataOut <= x"0" & '1' & '1' & '0' & '0';
when 48  => dataOut <= x"0" & '1' & '0' & '0' & '0';

when 49  => dataOut <= FirstLineInput(127 downto 124) & '1' & '1' & '0' & '1';     --1st Letter
when 50  => dataOut <= FirstLineInput(127 downto 124) & '1' & '0' & '0' & '1';
when 51  => dataOut <= FirstLineInput(123 downto 120) & '1' & '1' & '0' & '1';
when 52  => dataOut <= FirstLineInput(123 downto 120) & '1' & '0' & '0' & '1';

when 53  => dataOut <= FirstLineInput(119 downto 116) & '1' & '1' & '0' & '1';     --2nd Letter
when 54  => dataOut <= FirstLineInput(119 downto 116) & '1' & '0' & '0' & '1';
when 55  => dataOut <= FirstLineInput(115 downto 112) & '1' & '1' & '0' & '1';
when 56  => dataOut <= FirstLineInput(115 downto 112) & '1' & '0' & '0' & '1';

when 57  => dataOut <= FirstLineInput(111 downto 108) & '1' & '1' & '0' & '1';     --3rd Letter
when 58  => dataOut <= FirstLineInput(111 downto 108) & '1' & '0' & '0' & '1';
when 59  => dataOut <= FirstLineInput(107 downto 104) & '1' & '1' & '0' & '1';
when 60  => dataOut <= FirstLineInput(107 downto 104) & '1' & '0' & '0' & '1';

when 61  => dataOut <= FirstLineInput(103 downto 100) & '1' & '1' & '0' & '1';     --4th Letter
when 62  => dataOut <= FirstLineInput(103 downto 100) & '1' & '0' & '0' & '1';
when 63  => dataOut <= FirstLineInput(99 downto 96) & '1' & '1' & '0' & '1';
when 64  => dataOut <= FirstLineInput(99 downto 96) & '1' & '0' & '0' & '1';

when 65  => dataOut <= FirstLineInput(95 downto 92) & '1' & '1' & '0' & '1';     --5th Letter
when 66  => dataOut <= FirstLineInput(95 downto 92) & '1' & '0' & '0' & '1';
when 67  => dataOut <= FirstLineInput(91 downto 88) & '1' & '1' & '0' & '1';
when 68  => dataOut <= FirstLineInput(91 downto 88) & '1' & '0' & '0' & '1';

when 69  => dataOut <= FirstLineInput(87 downto 84) & '1' & '1' & '0' & '1';     --6th Letter
when 70  => dataOut <= FirstLineInput(87 downto 84) & '1' & '0' & '0' & '1';
when 71  => dataOut <= FirstLineInput(83 downto 80) & '1' & '1' & '0' & '1';
when 72  => dataOut <= FirstLineInput(83 downto 80) & '1' & '0' & '0' & '1';

when 73  => dataOut <= FirstLineInput(79 downto 76) & '1' & '1' & '0' & '1';     --7th Letter
when 74  => dataOut <= FirstLineInput(79 downto 76) & '1' & '0' & '0' & '1';
when 75  => dataOut <= FirstLineInput(75 downto 72) & '1' & '1' & '0' & '1';
when 76  => dataOut <= FirstLineInput(75 downto 72) & '1' & '0' & '0' & '1';

when 77  => dataOut <= FirstLineInput(71 downto 68) & '1' & '1' & '0' & '1';     --8th Letter
when 78  => dataOut <= FirstLineInput(71 downto 68) & '1' & '0' & '0' & '1';
when 79  => dataOut <= FirstLineInput(67 downto 64) & '1' & '1' & '0' & '1';
when 80  => dataOut <= FirstLineInput(67 downto 64) & '1' & '0' & '0' & '1';

when 81  => dataOut <= FirstLineInput(63 downto 60) & '1' & '1' & '0' & '1';     --9th Letter
when 82  => dataOut <= FirstLineInput(63 downto 60) & '1' & '0' & '0' & '1';
when 83  => dataOut <= FirstLineInput(59 downto 56) & '1' & '1' & '0' & '1';
when 84  => dataOut <= FirstLineInput(59 downto 56) & '1' & '0' & '0' & '1';


when 85  => dataOut <= FirstLineInput(55 downto 52) & '1' & '1' & '0' & '1';     --10th Letter
when 86  => dataOut <= FirstLineInput(55 downto 52) & '1' & '0' & '0' & '1';
when 87  => dataOut <= FirstLineInput(51 downto 48) & '1' & '1' & '0' & '1';
when 88  => dataOut <= FirstLineInput(51 downto 48) & '1' & '0' & '0' & '1';

when 89  => dataOut <= FirstLineInput(47 downto 44) & '1' & '1' & '0' & '1';     --11th Letter
when 90  => dataOut <= FirstLineInput(47 downto 44) & '1' & '0' & '0' & '1';
when 91  => dataOut <= FirstLineInput(43 downto 40) & '1' & '1' & '0' & '1';
when 92  => dataOut <= FirstLineInput(43 downto 40) & '1' & '0' & '0' & '1';

when 93  => dataOut <= FirstLineInput(39 downto 36) & '1' & '1' & '0' & '1';     --12th Letter
when 94  => dataOut <= FirstLineInput(39 downto 36) & '1' & '0' & '0' & '1';
when 95  => dataOut <= FirstLineInput(35 downto 32) & '1' & '1' & '0' & '1';
when 96  => dataOut <= FirstLineInput(35 downto 32) & '1' & '0' & '0' & '1';

when 97  => dataOut <= FirstLineInput(31 downto 28) & '1' & '1' & '0' & '1';     --13th Letter
when 98  => dataOut <= FirstLineInput(31 downto 28) & '1' & '0' & '0' & '1';
when 99  => dataOut <= FirstLineInput(27 downto 24) & '1' & '1' & '0' & '1';
when 100 => dataOut <= FirstLineInput(27 downto 24) & '1' & '0' & '0' & '1';

when 101 => dataOut <= FirstLineInput(23 downto 20) & '1' & '1' & '0' & '1';     --14th Letter
when 102 => dataOut <= FirstLineInput(23 downto 20) & '1' & '0' & '0' & '1';
when 103 => dataOut <= FirstLineInput(19 downto 16) & '1' & '1' & '0' & '1';
when 104 => dataOut <= FirstLineInput(19 downto 16) & '1' & '0' & '0' & '1';

when 105 => dataOut <= FirstLineInput(15 downto 12) & '1' & '1' & '0' & '1';     --15th Letter
when 106 => dataOut <= FirstLineInput(15 downto 12) & '1' & '0' & '0' & '1';
when 107 => dataOut <= FirstLineInput(11 downto 8)  & '1' & '1' & '0' & '1';
when 108 => dataOut <= FirstLineInput(11 downto 8)  & '1' & '0' & '0' & '1';

when 109 => dataOut <= FirstLineInput(7 downto 4)  & '1' & '1' & '0' & '1';     --16th Letter
when 110 => dataOut <= FirstLineInput(7 downto 4)  & '1' & '0' & '0' & '1';
when 111 => dataOut <= FirstLineInput(3 downto 0)  & '1' & '1' & '0' & '1';     
when 112 => dataOut <= FirstLineInput(3 downto 0)  & '1' & '0' & '0' & '1';

when 113 => dataOut <= X"C"   & '1' & '1' & '0' & '0';     --2nd Line
when 114 => dataOut <= X"C"   & '1' & '0' & '0' & '0';
when 115 => dataOut <= X"0"   & '1' & '1' & '0' & '0';
when 116 => dataOut <= X"0"   & '1' & '0' & '0' & '0';

when 117  => dataOut <= SecondLineInput(127 downto 124) & '1' & '1' & '0' & '1';     --1st Letter
when 118  => dataOut <= SecondLineInput(127 downto 124) & '1' & '0' & '0' & '1';
when 119  => dataOut <= SecondLineInput(123 downto 120) & '1' & '1' & '0' & '1';
when 120  => dataOut <= SecondLineInput(123 downto 120) & '1' & '0' & '0' & '1';

when 121  => dataOut <= SecondLineInput(119 downto 116) & '1' & '1' & '0' & '1';     --2nd Letter
when 122  => dataOut <= SecondLineInput(119 downto 116) & '1' & '0' & '0' & '1';
when 123  => dataOut <= SecondLineInput(115 downto 112) & '1' & '1' & '0' & '1';
when 124  => dataOut <= SecondLineInput(115 downto 112) & '1' & '0' & '0' & '1';

when 125 => dataOut <= SecondLineInput(111 downto 108) & '1' & '1' & '0' & '1';     --3rd Letter
when 126 => dataOut <= SecondLineInput(111 downto 108) & '1' & '0' & '0' & '1';
when 127 => dataOut <= SecondLineInput(107 downto 104) & '1' & '1' & '0' & '1';
when 128 => dataOut <= SecondLineInput(107 downto 104) & '1' & '0' & '0' & '1';

when 129 => dataOut <= SecondLineInput(103 downto 100) & '1' & '1' & '0' & '1';     --4th Letter
when 130 => dataOut <= SecondLineInput(103 downto 100) & '1' & '0' & '0' & '1';
when 131 => dataOut <= SecondLineInput(99 downto 96)   & '1' & '1' & '0' & '1';
when 132 => dataOut <= SecondLineInput(99 downto 96)   & '1' & '0' & '0' & '1';

when 133 => dataOut <= SecondLineInput(95 downto 92)   & '1' & '1' & '0' & '1';     --5th Letter
when 134 => dataOut <= SecondLineInput(95 downto 92)   & '1' & '0' & '0' & '1';
when 135 => dataOut <= SecondLineInput(91 downto 88)   & '1' & '1' & '0' & '1';
when 136 => dataOut <= SecondLineInput(91 downto 88)   & '1' & '0' & '0' & '1';

when 137 => dataOut <= SecondLineInput(87 downto 84)   & '1' & '1' & '0' & '1';     --6th Letter
when 138 => dataOut <= SecondLineInput(87 downto 84)   & '1' & '0' & '0' & '1';
when 139 => dataOut <= SecondLineInput(83 downto 80)   & '1' & '1' & '0' & '1';
when 140 => dataOut <= SecondLineInput(83 downto 80)   & '1' & '0' & '0' & '1';

when 141 => dataOut <= SecondLineInput(79 downto 76)   & '1' & '1' & '0' & '1';     --7th Letter
when 142 => dataOut <= SecondLineInput(79 downto 76)   & '1' & '0' & '0' & '1';
when 143 => dataOut <= SecondLineInput(75 downto 72)   & '1' & '1' & '0' & '1';
when 144 => dataOut <= SecondLineInput(75 downto 72)   & '1' & '0' & '0' & '1';

when 145 => dataOut <= SecondLineInput(71 downto 68)   & '1' & '1' & '0' & '1';     --8th Letter
when 146 => dataOut <= SecondLineInput(71 downto 68)   & '1' & '0' & '0' & '1';
when 147 => dataOut <= SecondLineInput(67 downto 64)   & '1' & '1' & '0' & '1';
when 148 => dataOut <= SecondLineInput(67 downto 64)   & '1' & '0' & '0' & '1';

when 149 => dataOut <= SecondLineInput(63 downto 60)   & '1' & '1' & '0' & '1';     --9th Letter
when 150 => dataOut <= SecondLineInput(63 downto 60)   & '1' & '0' & '0' & '1';
when 151 => dataOut <= SecondLineInput(59 downto 56)   & '1' & '1' & '0' & '1';
when 152 => dataOut <= SecondLineInput(59 downto 56)   & '1' & '0' & '0' & '1';

when 153 => dataOut <= SecondLineInput(55 downto 52)   & '1' & '1' & '0' & '1';     --10th Letter
when 154 => dataOut <= SecondLineInput(55 downto 52)   & '1' & '0' & '0' & '1';
when 155 => dataOut <= SecondLineInput(51 downto 48)   & '1' & '1' & '0' & '1';
when 156 => dataOut <= SecondLineInput(51 downto 48)   & '1' & '0' & '0' & '1';

when 157 => dataOut <= SecondLineInput(47 downto 44)   & '1' & '1' & '0' & '1';     --11th Letter
when 158 => dataOut <= SecondLineInput(47 downto 44)   & '1' & '0' & '0' & '1';
when 159 => dataOut <= SecondLineInput(43 downto 40)   & '1' & '1' & '0' & '1';
when 160 => dataOut <= SecondLineInput(43 downto 40)   & '1' & '0' & '0' & '1';

when 161 => dataOut <= SecondLineInput(39 downto 36)   & '1' & '1' & '0' & '1';     --12th Letter
when 162 => dataOut <= SecondLineInput(39 downto 36)   & '1' & '0' & '0' & '1';
when 163 => dataOut <= SecondLineInput(35 downto 32)   & '1' & '1' & '0' & '1';
when 164 => dataOut <= SecondLineInput(35 downto 32)   & '1' & '0' & '0' & '1';

when 165 => dataOut <= SecondLineInput(31 downto 28)   & '1' & '1' & '0' & '1';     --13th Letter
when 166 => dataOut <= SecondLineInput(31 downto 28)   & '1' & '0' & '0' & '1';
when 167 => dataOut <= SecondLineInput(27 downto 24)   & '1' & '1' & '0' & '1';
when 168 => dataOut <= SecondLineInput(27 downto 24)   & '1' & '0' & '0' & '1';

when 169 => dataOut <= SecondLineInput(23 downto 20)   & '1' & '1' & '0' & '1';     --14th Letter
when 170 => dataOut <= SecondLineInput(23 downto 20)   & '1' & '0' & '0' & '1';
when 171 => dataOut <= SecondLineInput(19 downto 16)   & '1' & '1' & '0' & '1';
when 172 => dataOut <= SecondLineInput(19 downto 16)   & '1' & '0' & '0' & '1';

when 173 => dataOut <= SecondLineInput(15 downto 12)   & '1' & '1' & '0' & '1';     --15th Letter
when 174 => dataOut <= SecondLineInput(15 downto 12)   & '1' & '0' & '0' & '1';
when 175 => dataOut <= SecondLineInput(11 downto 8)    & '1' & '1' & '0' & '1';
when 176 => dataOut <= SecondLineInput(11 downto 8)    & '1' & '0' & '0' & '1';

when 177 => dataOut <= SecondLineInput(7 downto 4)    & '1' & '1' & '0' & '1';     --16th Letter
when 178 => dataOut <= SecondLineInput(7 downto 4)    & '1' & '0' & '0' & '1';
when 179 => dataOut <= SecondLineInput(3 downto 0)    & '1' & '1' & '0' & '1'; 
when 180 => dataOut <= SecondLineInput(3 downto 0)    & '1' & '0' & '0' & '1';

        when others => dataOut <= x"00";
    end case;
end process;
------------------------------------------------------------------------------------------------------------------
end Behavioral;



--TODO:
-- Fully implement read functionality of I2C(including NACK)