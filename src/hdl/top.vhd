library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity top is
    generic (
        baud_rate        : integer := 1;        -- 1 MHz
        sys_clock        : integer := 100;      -- 100 MHz
        data_reg_width   : integer := 8;         
        error_reg_width  : integer := 4;         
        SPI_MODE         : std_logic_vector(1 downto 0) := "10"       
    );
    port (
        RESET_I         : in  std_logic;
        CLK_I           : in  std_logic;
        ENABLE_I        : in  std_logic;
        START_SEND_I    : in  std_logic;
        ERROR_MASTER_O  : out std_logic_vector(error_reg_width-1 downto 0);
        ERROR_SLAVE_O   : out std_logic_vector(error_reg_width-1 downto 0)
    );
end top;          
    
architecture structrual of top is

    constant spi_clk : integer   := (1000 / baud_rate); -- sclk according to ns
    constant sys_clk : integer   := (1000 / sys_clock); -- sys_clk according to ns
    constant CPHA    : std_logic := SPI_MODE(1);            
    constant CPOL    : std_logic := SPI_MODE(0);  

    --counter spi master
    signal ready_counter_spi_master : std_logic;
    signal valid_counter_spi_master : std_logic;
    signal DATA_counter_spi_master  : std_logic_vector(data_reg_width-1 downto 0) := (others => '0') ;

    --counter spi slave
    signal ready_counter_spi_slave : std_logic;
    signal valid_counter_spi_slave : std_logic;
    signal DATA_counter_spi_slave  : std_logic_vector(data_reg_width-1 downto 0) := (others => '0') ;


    --err_check spi master
    component ERROR_CHECK  is
        generic (
            constant number_of_bit_DATA_I   : integer ;
            constant number_of_bit_ERROR_O  : integer 
        );
        port(
            CLK_I     :   in    std_logic;
            RESET_I   :   in    std_logic;
            VALID_I   :   in    std_logic;
            DATA_I    :   in    std_logic_vector( number_of_bit_DATA_I-1 downto 0);
            ERROR_O   :   out   std_logic_vector(number_of_bit_ERROR_O-1 downto 0);
            READY_O   :   out   std_logic
        );
    end component;
    signal ready_err_spi_master   : std_logic;
    signal valid_err_spi_master   : std_logic;
    signal DATA_err_spi_master    : std_logic_vector(data_reg_width-1 downto 0) := (others => '0') ;

    --err_check spi slave
    signal ready_err_spi_slave   : std_logic;
    signal valid_err_spi_slave   : std_logic;
    signal DATA_err_spi_slave    : std_logic_vector(data_reg_width-1 downto 0) := (others => '0') ;

    --spi
    signal SCLK    : std_logic;
    signal MOSI    : std_logic;
    signal MISO    : std_logic;
    signal SS      : std_logic;
    
begin

    ins0_counter : entity  work.COUNTER
        generic map( 
            reg_width_data => data_reg_width
        )    
        port map(
            ENABLE_I    => ENABLE_I,
            RESET_I     => RESET_I,
            CLK_I       => CLK_I,
            READY_I     => ready_counter_spi_master,
            VALID_O     => valid_counter_spi_master,
            DATA_O      => DATA_counter_spi_master
        ); 
        
    ins0_spi_master : entity work.spi_master 
        generic map(
            data_TX_spi_reg_width => data_reg_width,
            data_RX_spi_reg_width => data_reg_width,
            SYS_CLOCK             => sys_clk, 
            SPI_CLOCK             => spi_clk,
            CPOL                  => CPOL,
            CPHA                  => CPHA
            -- MSB_first       : integer := 1; 
            -- LSB_first       : integer := 0
        )
        port map(
            CLK_I           => CLK_I,
            RESET_I         => RESET_I,
            SCLK            => SCLK,
            MOSI            => MOSI,
            MISO            => MISO,
            SS              => SS,
            ------------------------------------
            SEND_DATA_I     => DATA_counter_spi_master,
            START_SEND_I    => START_SEND_I,
            READY_O         => ready_counter_spi_master,
            VALID_I         => valid_counter_spi_master,
            ------------------------------------
            RECEIVE_DATA_O  => DATA_err_spi_master,
            READY_I         => ready_err_spi_master,
            VALID_O         => valid_err_spi_master
        );

    ins0_err : ERROR_CHECK
        generic map(
            number_of_bit_DATA_I   => data_reg_width,
            number_of_bit_ERROR_O  => error_reg_width
        )
        port map(
            CLK_I     => CLK_I,
            RESET_I   => RESET_I,
            VALID_I   => valid_err_spi_master,
            DATA_I    => DATA_err_spi_master,
            ERROR_O   => ERROR_MASTER_O,
            READY_O   => ready_err_spi_master
        );

    ins1_counter : entity  work.COUNTER
        generic map( 
            reg_width_data => data_reg_width
        )    
        port map(
            ENABLE_I    => ENABLE_I,
            RESET_I     => RESET_I,
            CLK_I       => CLK_I,
            READY_I     => ready_counter_spi_slave,
            VALID_O     => valid_counter_spi_slave,
            DATA_O      => DATA_counter_spi_slave
        );  

    ins0_spi_slave : entity work.spi_slave 
        generic map(
            data_TX_spi_slave_reg_width => data_reg_width,
            data_RX_spi_slave_reg_width => data_reg_width,
            CPOL                        => CPOL,
            CPHA                        => CPHA
            -- MSB_first       : integer := 1 
            -- LSB_first       : integer := 0
        )
        port map(
            CLK_I           => CLK_I,
            RESET_I         => RESET_I,
            ------------------------------------
            SCLK            => SCLK,
            MOSI            => MOSI,
            SS              => SS,
            MISO            => MISO,
            ------------------------------------
            SEND_DATA_I     => DATA_counter_spi_slave,
            READY_O         => ready_counter_spi_slave,
            VALID_I         => valid_counter_spi_slave,
            ------------------------------------
            RECEIVE_DATA_O  => DATA_err_spi_slave,
            READY_I         => ready_err_spi_slave,
            VALID_O         => valid_err_spi_slave
        );
 
    ins1_err : ERROR_CHECK
        generic map(
            number_of_bit_DATA_I   => data_reg_width,
            number_of_bit_ERROR_O  => error_reg_width
        )
        port map(
            CLK_I     => CLK_I,
            RESET_I   => RESET_I,
            VALID_I   => valid_err_spi_slave,
            DATA_I    => DATA_err_spi_slave,
            ERROR_O   => ERROR_SLAVE_O,
            READY_O   => ready_err_spi_slave
        );

end architecture structrual;  
 