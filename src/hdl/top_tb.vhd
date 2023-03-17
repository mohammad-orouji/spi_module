library ieee;
use ieee.std_logic_1164.all;

entity top_tb is
end;

architecture TESTBENCH of top_tb is
       
signal enable_tb    : std_logic := '0'; 
signal reset_tb     : std_logic := '0'; 
signal clk_tb       : std_logic := '0';
signal SCLK         : std_logic := '0';
signal start_send   : std_logic := '0';

constant T_10      : time    := 10    ns;
constant T_1000     : time    := 1000  ns;

begin

    ins_0 : entity work.top
        port map(
            RESET_TOP       => reset_tb,
            CLK_TOP         => clk_tb,
            SCLK            => SCLK,
            ENABLE_TOP      => enable_tb,
            START_SEN_TOP   => start_send
        );

process
begin
    clk_tb  <= '0' ;
    wait for T_10/2;
    clk_tb  <= '1' ;
    wait for T_10/2;
end process;

process
begin
    SCLK  <= '0' ;
    wait for T_1000/2;
    SCLK  <= '1' ;
    wait for T_1000/2;
end process;


reset_tb        <= '1'  , '0' after (T_10)/2;
enable_tb       <= '0'  , '1' after 50 ns;
start_send      <= '1' after 20 ns;

end architecture TESTBENCH;