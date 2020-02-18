library ieee;
use ieee.std_logic_1164.all;

entity FSM is
port (In1: in std_logic;
   RST: in std_logic; 
   CLK: in std_logic;
   Out1 : inout std_logic);
end FSM;

architecture FSM_Arch of FSM is
type SName is (A,B,C);
signal CState, NState : SName;
begin
	comb_proc : process (In1,CState) begin
			case (CState) is
				when A =>
					Out1 <= '0';
					if (In1 = '1') then NState <= B;
					else NState <= A;
					end if;
				when B =>
					Out1 <= '0';
					if (In1 = '0') then NState <= C;
					else NState <= B;
					end if;
				when C =>
					Out1 <= '1';
					if (In1 = '1') then NState <= A;
					else NState <= C;
					end if;
				when others => NState <= A;
			end case;
	end process comb_proc;
	
	sync_proc : process (CLK, RST) begin
		if (RST = '1') then CState <= A;
		elsif (rising_edge(CLK)) then CState <= NState;
		end if;
	end process sync_proc;
end architecture FSM_Arch;