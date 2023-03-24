library ieee;
use ieee.std_logic_1164.all;

entity top_tb is
end;

architecture testbench of top_tb is
       
signal enable_tb        : std_logic; 
signal reset_tb         : std_logic; 
signal clk_tb           : std_logic;
signal start_send_tb    : std_logic;
signal error_master_tb  : std_logic_vector(3 downto 0);
signal error_slave_tb   : std_logic_vector(3 downto 0);

constant T_10 : time := 10 ns;

begin

    ins_0 : entity work.top
        generic map(
            baud_rate        => 1,       
            sys_clock        => 100,     
            data_reg_width   => 8,         
            error_reg_width  => 4,         
            SPI_MODE         => "10"       
        )
        port map(
            RESET_I         => reset_tb,
            CLK_I           => clk_tb,
            ENABLE_I        => enable_tb,
            START_SEND_I    => start_send_tb,
            ERROR_MASTER_O  => error_master_tb,
            ERROR_SLAVE_O   => error_slave_tb
        );

    process
    begin
        clk_tb  <= '0' ;
        wait for T_10/2;
        clk_tb  <= '1' ;
        wait for T_10/2;
    end process;

    -- reset_tb        <= '0';
    -- reset_tb        <= '1'  , '0' after (T_10)/2, '1' after 20 us, '0' after 30 us, '1' after 100 us , '0' after 200 us ;
    reset_tb    <= '1'  , '0' after (T_10)/2, '1' after 20 us, '0' after 30 us, '1' after 500 us , '0' after 900 us,
                '1' after 1500 us , '0' after 2100 us, '1' after 2500 us , '0' after 2650 us, '1' after 2700 us , '0' after 3900 us ;
    enable_tb       <= '0'  , '1' after 50 us;
    start_send_tb   <= '1' after 20 ns, '0' after 50 us, '1' after 70 us;

end architecture testbench;