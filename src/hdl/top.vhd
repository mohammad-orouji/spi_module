library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity top is
    port (
        RESET_TOP       :   in      std_logic;
        CLK_TOP         :   in      std_logic;
        ENABLE_TOP      :   in      std_logic;
        START_SEN_TOP   :   in      std_logic;
        ERROR_TOP       :   out     std_logic_vector(3 downto 0)
    );
end top;

architecture structrual of top is

    --spi master
    signal ready_counter        : std_logic;
    signal valid_counter        : std_logic;
    signal DATA_counter         : std_logic_vector(7 downto 0) := (others => '0') ;
    signal DATA_rec_of_slave    : std_logic_vector(7 downto 0) := (others => '0') ;

    --spi slave
    signal data_err             : std_logic_vector(7 downto 0);

    signal data_send_of_master  : std_logic_vector(7 downto 0) := "01010101" ;
    signal ready_sender_slave   : std_logic;
    signal valid_sender_slave   : std_logic := '1';

    signal ready_err    : std_logic := '1';
    signal valid_err    : std_logic;
    
    signal SCLK_tb    : std_logic;
    signal MOSI_tb    : std_logic;
    signal MISO_tb    : std_logic;
    signal SS_tb      : std_logic;

begin

    ins0_counter : entity  work.COUNTER
        generic map( 
            reg_width_data => 8
        )    
        port map(
            ENABLE_I    => ENABLE_TOP,
            RESET_I     => RESET_TOP,
            CLK_I       => CLK_TOP,
            READY_I     => ready_counter,
            VALID_O     => valid_counter,
            DATA_O      => DATA_counter
        );  
        

    
    ins0_spi_master : entity work.spi_master 
        generic map(
            data_TX_spi_reg_width => 8,
            data_RX_spi_reg_width => 8,
            SYS_CLOCK             => 10, 
            SPI_CLOCK             => 100,
            CPOL                  => '1',
            CPHA                  => '0'
            -- MSB_first       : integer := 1; 
            -- LSB_first       : integer := 0
        )
        port map(
            CLK_I           => CLK_TOP,
            RESET_I         => RESET_TOP,
            SCLK            => SCLK_tb,
            MOSI            => MOSI_tb,
            MISO            => MISO_tb,
            SS              => SS_tb,
            ------------------------------------
            SEND_DATA_I     => DATA_counter,
            START_SEND_I    => START_SEN_TOP,
            READY_O         => ready_counter,
            VALID_I         => valid_counter,
            ------------------------------------
            RECEIVE_DATA_O  => DATA_rec_of_slave
            -- READY_I         : in  std_logic;
            -- VALID_O         : out std_logic
        );

    ins0_spi_slave : entity work.spi_slave 
        generic map(
            data_TX_spi_slave_reg_width => 8,
            data_RX_spi_slave_reg_width => 8,
            CPOL                        => '1',
            CPHA                        => '0'
            -- MSB_first       : integer := 1 
            -- LSB_first       : integer := 0
        )
        port map(
            CLK_I           => CLK_TOP,
            RESET_I         => RESET_TOP,
            ------------------------------------
            SCLK            => SCLK_tb,
            MOSI            => MOSI_tb,
            SS              => SS_tb,
            MISO            => MISO_tb,
            ------------------------------------
            SEND_DATA_I     => data_send_of_master,
            READY_O         => ready_sender_slave,
            VALID_I         => valid_sender_slave,
            ------------------------------------
            RECEIVE_DATA_O  => data_err,
            READY_I         => ready_err,
            VALID_O         => valid_err
        );

    ins0_err : entity  work.ERROR_CHECK
        generic map(
            number_of_bit_DATA_I   => 8,
            number_of_bit_ERROR_O  => 4
        )
        port map(
            CLK_I     => CLK_TOP,
            RESET_I   => RESET_TOP,
            VALID_I   => valid_err,
            DATA_I    => data_err,
            ERROR_O   => ERROR_TOP,
            READY_O   => ready_err
        );

end architecture structrual;  
 