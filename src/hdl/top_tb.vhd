library ieee;
use ieee.std_logic_1164.all;

entity top_tb is
end;

architecture testbench of top_tb is
       
signal enable_tb                    : std_logic; 
signal reset_tb                     : std_logic; 
signal clk_tb                       : std_logic;
signal start_send_tb                : std_logic;
signal DATA_RECEIVED_of_master_tb   : std_logic_vector(7 downto 0);

constant T_10      : time    := 10    ns;

begin

    ins_0 : entity work.top
        port map(
            RESET_TOP                => reset_tb,
            CLK_TOP                  => clk_tb,
            ENABLE_TOP               => enable_tb,
            START_SEN_TOP            => start_send_tb,
            DATA_RECEIVED_of_master  => DATA_RECEIVED_of_master_tb
        );

process
begin
    clk_tb  <= '0' ;
    wait for T_10/2;
    clk_tb  <= '1' ;
    wait for T_10/2;
end process;

reset_tb        <= '1'  , '0' after (T_10)/2;
enable_tb       <= '0'  , '1' after 50 ns;
start_send_tb   <= '1' after 20 ns;

end architecture testbench;