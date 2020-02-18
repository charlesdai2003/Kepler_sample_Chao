LIBRARY ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;


entity AAC2M2P1 is port (                 	
   CP: 	in std_logic; 	-- clock
   SR:  in std_logic;  -- Active low, synchronous reset
   P:    in std_logic_vector(3 downto 0);  -- Parallel input
   PE:   in std_logic;  -- Parallel Enable (Load)
   CEP: in std_logic;  -- Count enable parallel input
   CET:  in std_logic; -- Count enable trickle input
   Q:   out std_logic_vector(3 downto 0);            			
    TC:  out std_logic  -- Terminal Count
);            		
end AAC2M2P1;

architecture Count_arch of AAC2M2P1 is begin
	-- Comb logic for TC
	TC_proc : process (Q, CET) begin
		TC <= Q(3) and Q(2) and Q(1) and Q(0) and CET;
	end process TC_proc;
	
	-- Sync logic
	Sync_proc : process (CP) begin
		if (rising_edge(CP)) then
			if (SR = '0') then Q <= "0000";
			elsif (PE = '0') then Q <= P;
			elsif ((CET and CEP) = '1') then Q <= Q + 1;
			end if;
		end if;
	end process Sync_proc;
end architecture Count_arch;
	