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
        -- RESET_I         : in  std_logic;
        -- CLK_I           : in  std_logic;
        -- ENABLE_I        : in  std_logic;
        -- START_SEND_I    : in  std_logic;
        -- ERROR_MASTER_O  : out std_logic_vector(error_reg_width-1 downto 0);
        -- ERROR_SLAVE_O   : out std_logic_vector(error_reg_width-1 downto 0)
        CLK_12m_i        :   in      std_logic
    );
end top;          
    
architecture structrual of top is
--####################################################################################
--###					ILA						                   ###
--####################################################################################
    COMPONENT ila_0
    PORT (
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe2  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
         
        probe3  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe4  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe5  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe6  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe7  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe8  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe9  : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 

        probe10  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe11  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe12  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe13  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe14  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe15  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe16  : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;
    signal SS_ila     : std_logic_vector(0 downto 0);
    signal MOSI_ila   : std_logic_vector(0 downto 0);
    signal MISO_ila   : std_logic_vector(0 downto 0);
-----------
    signal ready_counter_master_ila : std_logic_vector(0 downto 0);
    signal valid_counter_master_ila : std_logic_vector(0 downto 0);

    signal ready_err_slave_ila : std_logic_vector(0 downto 0);
    signal valid_err_slave_ila : std_logic_vector(0 downto 0);
-----------
    signal ready_counter_slave_ila : std_logic_vector(0 downto 0);
    signal valid_counter_slave_ila : std_logic_vector(0 downto 0);
    
    signal ready_err_master_ila : std_logic_vector(0 downto 0);
    signal valid_err_master_ila : std_logic_vector(0 downto 0);
--####################################################################################
--###					END ILA						                   ###
--####################################################################################

--####################################################################################
--###					VIO						                   ###
--####################################################################################
COMPONENT vio_0
    PORT (
        clk         : IN STD_LOGIC;
        probe_in0   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        
        probe_out0  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out1  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out2  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT;
    signal locked_ila       : std_logic_vector(0 downto 0);
    signal reset_ila        : std_logic_vector(0 downto 0);
    signal enable_ila       : std_logic_vector(0 downto 0);
    signal start_send_ila   : std_logic_vector(0 downto 0);
--####################################################################################
--###					END VIO						                   ###
--####################################################################################

--####################################################################################
--###					 Clock 						                   ###
--####################################################################################

    component clk_wiz_a
        port (
            -- Clock in ports
            -- Clock out ports
            clk_out1          : out    std_logic;
            clk_out2          : out    std_logic;
            -- Status and control signals
            locked            : out    std_logic;
            clk_in1           : in     std_logic
        );
        end component;
    signal locked_vio   : std_logic;
    signal CLK_200m      : std_logic;
    signal CLK_100m     : std_logic;
--####################################################################################
--###					END Clock 						                   ###
--####################################################################################
    signal reset        : std_logic;
    signal enable       : std_logic;    
    signal start_send   : std_logic;
    
    signal error_master  : std_logic_vector(error_reg_width-1 downto 0);
    signal error_slave   : std_logic_vector(error_reg_width-1 downto 0);

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

    --spi
    signal SCLK    : std_logic;
    signal MOSI    : std_logic;
    signal MISO    : std_logic;
    signal SS      : std_logic;
--####################################################################################
--###					END Error check 						                   ###
--####################################################################################
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
--####################################################################################
--###					END Error check 						                   ###
--####################################################################################
    
begin

--####################################################################################
--###					SPI Master 						                   ###
--####################################################################################
    ins0_counter : entity  work.COUNTER
        generic map( 
            reg_width_data => data_reg_width
        )    
        port map(
            ENABLE_I    => enable,
            RESET_I     => reset,
            CLK_I       => CLK_100m,
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
            CLK_I           => CLK_100m,
            RESET_I         => reset,
            SCLK            => SCLK,
            MOSI            => MOSI,
            MISO            => MISO,
            SS              => SS,
            ------------------------------------
            SEND_DATA_I     => DATA_counter_spi_master,
            START_SEND_I    => start_send,
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
            CLK_I     => CLK_100m,
            RESET_I   => reset,
            VALID_I   => valid_err_spi_master,
            DATA_I    => DATA_err_spi_master,
            ERROR_O   => error_master,
            READY_O   => ready_err_spi_master
        );
--####################################################################################
--###					END SPI Master 						                   ###
--####################################################################################

--####################################################################################
--###					SPI Slave 						                   ###
--####################################################################################
    ins1_counter : entity  work.COUNTER
        generic map( 
            reg_width_data => data_reg_width
        )    
        port map(
            ENABLE_I    => enable,
            RESET_I     => reset,
            CLK_I       => CLK_100m,
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
            CLK_I           => CLK_100m,
            RESET_I         => reset,
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
            CLK_I     => CLK_100m,
            RESET_I   => reset,
            VALID_I   => valid_err_spi_slave,
            DATA_I    => DATA_err_spi_slave,
            ERROR_O   => error_slave,
            READY_O   => ready_err_spi_slave
        );
--####################################################################################
--###					END SPI Slave 						                   ###
--####################################################################################

--####################################################################################
--###					ILA						                   ###
--####################################################################################
    ins0_ila_0 : ila_0
    PORT map(
        clk     => CLK_100m,
        probe0  => SS_ila,
        probe1  => MOSI_ila,
        probe2  => MISO_ila,
        
        probe3  => ready_counter_master_ila,
        probe4  => valid_counter_master_ila,
        probe5  => DATA_counter_spi_master,
        probe6  => ready_err_slave_ila,
        probe7  => valid_err_slave_ila,
        probe8  => DATA_err_spi_slave, 
        probe9  => error_slave,

        probe10 => ready_counter_slave_ila,
        probe11 => valid_counter_slave_ila, 
        probe12 => DATA_counter_spi_slave, 
        probe13 => ready_err_master_ila,
        probe14 => valid_err_master_ila,
        probe15 => DATA_err_spi_master,
        probe16 => error_master
    );
    SS_ila(0)     <= SS;
    MOSI_ila(0)   <= MOSI;
    MISO_ila(0)   <= MISO;

    ready_counter_master_ila(0) <= ready_counter_spi_master;
    valid_counter_master_ila(0) <= valid_counter_spi_master;

    ready_err_slave_ila(0)  <= ready_err_spi_slave;
    valid_err_slave_ila(0)  <= valid_err_spi_slave;
    
    ready_counter_slave_ila(0)  <= ready_counter_spi_slave;
    valid_counter_slave_ila(0)  <= valid_counter_spi_slave;

    ready_err_master_ila(0) <= ready_err_spi_master;
    valid_err_master_ila(0) <= valid_err_spi_master;
--####################################################################################
--###					END ILA						                   ###
--####################################################################################

--####################################################################################
--###					VIO						                   ###
--####################################################################################
    ins0_vio_0 : vio_0
        PORT map(
            clk         => CLK_100m,
            probe_in0   => locked_ila,
            
            probe_out0  => reset_ila,
            probe_out1  => enable_ila,
            probe_out2  => start_send_ila
        );
    locked_ila(0)   <= locked_vio;
    reset           <= reset_ila(0);
    enable          <= enable_ila(0);
    start_send      <= start_send_ila(0);
--####################################################################################
--###					END VIO						                   ###
--####################################################################################

--####################################################################################
--###					 Clock 						                   ###
--####################################################################################
    ins0_clk_wiz_a : clk_wiz_a
        port map(
            -- Clock in ports
            -- Clock out ports
            clk_out1 => CLK_100m,
            clk_out2 => CLK_200m,
            -- Status and control signals
            locked   => locked_vio,
            clk_in1  => CLK_12m_i
        );
--####################################################################################
--###					END Clock 						                   ###
--####################################################################################

end architecture structrual;  
 