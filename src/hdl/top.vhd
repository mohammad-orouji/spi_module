
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity top is
    port (
        RESET_TOP       :   in      std_logic;
        CLK_TOP         :   in      std_logic;
        SS_top              :   out     std_logic;
        MOSI_top            :   out     std_logic;
        MISO_top            :   in     std_logic;
        SCLK_top            :   out     std_logic;
        ENABLE_TOP      :   in      std_logic;
        START_SEN_TOP   :   in      std_logic
        -- CLK_12m        :   in      std_logic
    );
end top;

architecture STRUCTRUAL of top is

    -- COMPONENT ila_0
    -- PORT (
    --     clk     : IN STD_LOGIC;
    --     probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --     probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --     probe2  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
         
    --     probe3  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --     probe4  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --     probe5  : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    -- );
    -- END COMPONENT;

    -- signal SS     : std_logic_vector(0 downto 0);
    -- signal MOSI   : std_logic_vector(0 downto 0);
    -- signal MISO   : std_logic_vector(0 downto 0);

    signal ready        : std_logic;
    signal valid        : std_logic;
    signal DATA_counter : std_logic_vector(7 downto 0)   := (others => '0') ;
    signal DATA_rec_im  : std_logic_vector(7 downto 0)   := (others => '0') ;

    -- COMPONENT vio_0
    -- PORT (
    --     clk         : IN STD_LOGIC;
    --     probe_in0   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --     probe_out0  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    --     probe_out1  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    --     probe_out2  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    -- );
    -- END COMPONENT;

    -- signal locked           : std_logic_vector(0 downto 0);
    -- signal reset            : std_logic_vector(0 downto 0);
    -- signal enable           : std_logic_vector(0 downto 0);
    -- signal start_send_top   : std_logic_vector(0 downto 0);

    -- component clk_wiz_a
    -- port (
    --     -- Clock in ports
    --     -- Clock out ports
    --     clk_out1          : out    std_logic;
    --     clk_out2          : out    std_logic;
    --     -- Status and control signals
    --     locked            : out    std_logic;
    --     clk_in1           : in     std_logic
    -- );
    -- end component;

    -- signal CLK_10m   : std_logic;
    -- signal CLK_100m  : std_logic;

begin
    -- ins0_err : entity work.ERROR_CHECK
    --     generic map(
    --         number_of_bit_DATA_I   => 8,
    --         number_of_bit_ERROR_O  => 4
    --     )
    --     port map(
    --         CLK1      => CLK_TOP,
    --         CLK2      => CLK_TOP_2,
    --         RESET_I   => RESET_TOP,
    --         VALID_I   => VALID_im,
    --         DATA_I    => DATA_im,
    --         ERROR_O   => err_im,
    --         READY_O   => READY_im
    --     );
        ins0_counter : entity  work.COUNTER
            generic map( 
                reg_width_data => 8
            )    
            port map(
                ENABLE_I    => ENABLE_TOP,
                RESET_I     => RESET_TOP,
                CLK_I       => CLK_TOP,
                READY_I     => ready,
                VALID_O     => valid,
                DATA_O      => DATA_counter
            );        
    
    ins0_spi : entity work.spi 
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
            SCLK            => SCLK_top,
            MOSI            => MOSI_top,
            MISO            => MISO_top,
            SS              => SS_top,
            ------------------------------------
            SEND_DATA_I     => DATA_counter,
            START_SEND_I    => START_SEN_TOP,
            READY_O         => ready,
            VALID_I         => valid,
            ------------------------------------
            RECEIVE_DATA_O  => DATA_rec_im
            -- READY_I         : in  std_logic;
            -- VALID_O         : out std_logic
        );
        
    -- ins0_ila_0 : ila_0
    --     PORT MAP (
    --         clk     => CLK_100m,
    --         probe0  => ready, 
    --         probe1  => valid, 
    --         probe2  => DATA_counter, 

    --         probe3  => SS, 
    --         probe4  => MOSI, 
    --         probe5  => MISO
    --     );

    -- ins0_vio_0 : vio_0
    --     PORT MAP (
    --         clk         => CLK_100m,
    --         probe_in0   => locked,
    --         probe_out0  => reset,
    --         probe_out1  => enable,
    --         probe_out2  => start_send_top
    --     );

        ------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
    -- ins0_clk_wiz_a_0 : clk_wiz_a
    --     port map ( 
    --         -- Clock out ports  
    --         clk_out1    => CLK_100m,
    --         clk_out2    => CLK_10m,
    --         -- Status and control signals                
    --         locked      => locked(0),
    --         -- Clock in ports
    --         clk_in1     => CLK_12m
    --     );
end architecture STRUCTRUAL;  
 