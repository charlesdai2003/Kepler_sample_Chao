library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FIFO8x9 is
   port(
      clk, rst:		in std_logic;
      RdPtrClr, WrPtrClr:	in std_logic;    
      RdInc, WrInc:	in std_logic;
      DataIn:	 in std_logic_vector(8 downto 0);
      DataOut: out std_logic_vector(8 downto 0);
      rden, wren: in std_logic
	);
end entity FIFO8x9;

architecture RTL of FIFO8x9 is
	--signal declarations
	type fifo_array is array(7 downto 0) of std_logic_vector(8 downto 0);  -- makes use of VHDL’s enumerated type
	signal fifo:  fifo_array;
	signal wrptr, rdptr: std_logic_vector(2 downto 0);
	signal en: std_logic_vector(7 downto 0);
	signal dmuxout: std_logic_vector(8 downto 0);

begin
	proc : process (clk, rst, rden) begin
		if (rst = '1') then
			wrptr <= "000";
			rdptr <= "000";
			DataOut <= "ZZZZZZZZZ";
			fifo(0) <= "ZZZZZZZZZ";
			fifo(1) <= "ZZZZZZZZZ";
			fifo(2) <= "ZZZZZZZZZ";
			fifo(3) <= "ZZZZZZZZZ";
			fifo(4) <= "ZZZZZZZZZ";
			fifo(5) <= "ZZZZZZZZZ";
			fifo(6) <= "ZZZZZZZZZ";
			fifo(7) <= "ZZZZZZZZZ";
		elsif (rising_edge(clk)) then
			if (RdPtrClr = '1') then rdptr <= "000";
			end if;
			if (WrPtrClr = '1') then wrptr <= "000";
			end if;
			if (RdInc = '1') then rdptr <= rdptr + 1;
			end if;
			if (WrInc = '1') then wrptr <= wrptr + 1;
			end if;
			if (wren = '1') then fifo(to_integer(unsigned(wrptr))) <= DataIn;
			end if;
		end if;
		if (rden = '1') then DataOut <= fifo(to_integer(unsigned(rdptr)));
		else DataOut <= "ZZZZZZZZZ";
		end if;
	end process proc;
end architecture RTL;

			