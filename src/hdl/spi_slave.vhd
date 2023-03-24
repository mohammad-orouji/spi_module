library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
    generic (
        data_TX_spi_slave_reg_width : integer   := 8;
        data_RX_spi_slave_reg_width : integer   := 8;
        CPOL            : std_logic := '0';
        CPHA            : std_logic := '0'
        -- MSB_first       : integer := 1 
        -- LSB_first       : integer := 0
    );
    port (
        CLK_I           : in  std_logic;
        RESET_I         : in  std_logic;
        ------------------------------------
        SCLK            : in  std_logic;
        MOSI            : in  std_logic;
        SS              : in  std_logic;
        MISO            : out std_logic;
        ------------------------------------
        SEND_DATA_I     : in  std_logic_vector(data_TX_spi_slave_reg_width-1 downto 0);
        READY_O         : out std_logic;
        VALID_I         : in  std_logic;
        ------------------------------------
        RECEIVE_DATA_O  : out std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0);  
        READY_I         : in  std_logic;
        VALID_O         : out std_logic
    );
end entity spi_slave;

architecture behavioral of spi_slave is

    signal spi_mode         : std_logic_vector(1 downto 0);
    signal captur_edge      : std_logic;
    signal launch_edge      : std_logic;

    signal data_received    : std_logic;
    signal data_Transferred : std_logic;
    signal spi_ready        : std_logic;
    signal ready        : std_logic;

    signal SEND_DATA_I_r    : std_logic_vector(data_TX_spi_slave_reg_width-1 downto 0)  := (others => '0');
    signal SS_r             : std_logic;
    signal SS_r2            : std_logic;

    signal shift_falling_en     : std_logic;
    signal shift_rising_en      : std_logic;
    signal MISO_rising          : std_logic;
    signal MISO_falling         : std_logic;

    signal receive_data_risnig          : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0) := (others => '0');
    signal data_rec_spi_valid_risnig    : std_logic;

    signal receive_data_falling         : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0) := (others => '0');
    signal data_rec_spi_valid_falling   : std_logic;

    signal receive_data             : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0) := (others => '0');
    signal receive_data_r           : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0) := (others => '0');
    signal receive_data_r2          : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0) := (others => '0');
    signal data_rec_spi_valid       : std_logic;
    signal data_rec_spi_valid_r     : std_logic;
    signal data_rec_spi_valid_r2    : std_logic;

    signal r_RECEIVE_DATA_O : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0) := (others => '0');
    signal r_VALID_O        : std_logic := '0';

begin

    READY_O  <= spi_ready and ready;
    spi_mode <= CPHA & CPOL;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            SEND_DATA_I_r   <= SEND_DATA_I_r;
            -- r_SS            <= SS;

            -- data_Transferred <= '1';
            spi_ready        <= '1';
            ready            <= '1';
            data_received    <= data_received;

            if VALID_I = '1' and READY_O = '1' then
                SEND_DATA_I_r   <= SEND_DATA_I;
                ready           <= '0';
                data_received   <= '1';
            end if;

            if SS = '0' then
                spi_ready        <= '0';
                -- data_Transferred <= '1';
                data_received    <= '0';
            end if;

            if SS = '1' and data_received = '1' then
                ready <= '0';
            end if;

            if RESET_I = '1' then
                SEND_DATA_I_r    <= (others => '0');
                ready            <= '0';
                -- data_Transferred <= '0';
                spi_ready        <= '0';
                data_received    <= '0';
            end if;

            case spi_mode is
                --MODE 00
                when "00" =>
                    launch_edge <= '0';     --falling_edge
                    captur_edge <= '1';     --risng_edge
                --MODE 10
                when "10" =>
                    launch_edge <= '1';     --risng_edge
                    captur_edge <= '0';     --falling_edge
                --MODE 01
                when "01" =>
                    launch_edge <= '1';     --risng_edge
                    captur_edge <= '0';     --falling_edge
                --MODE 11
                when "11" =>
                    launch_edge <= '0';     --falling_edge
                    captur_edge <= '1';     --risng_edge
                --MODE 00
                when others =>
                    launch_edge <= '0';     --falling_edge
                    captur_edge <= '1';     --risng_edge
            end case;
                
        end if;
    end process;

    RECEIVE_DATA_O      <= r_RECEIVE_DATA_O;
    VALID_O             <= r_VALID_O;
    receive_data        <= receive_data_risnig       when captur_edge = '1' else receive_data_falling;
    data_rec_spi_valid  <= data_rec_spi_valid_risnig when captur_edge = '1' else data_rec_spi_valid_falling;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            SS_r                    <= SS;
            SS_r2                   <= SS_r;
            receive_data_r          <= receive_data;
            receive_data_r2         <= receive_data_r;
            data_rec_spi_valid_r    <= data_rec_spi_valid;
            data_rec_spi_valid_r2   <= data_rec_spi_valid_r;

            if data_rec_spi_valid_r = '0' and data_rec_spi_valid_r2 = '1' then
                if r_VALID_O = '0' then
                    r_RECEIVE_DATA_O <= receive_data_r2;
                else
                    r_RECEIVE_DATA_O <= r_RECEIVE_DATA_O;
                end if;
                r_VALID_O <= '1';
            end if;

            if r_VALID_O = '1' and READY_I = '1' then
                r_VALID_O       <= '0';
            end if;

            if RESET_I = '1' then
                receive_data_r          <= (others => '0');
                receive_data_r2         <= (others => '0');
                data_rec_spi_valid_r    <= '0';
                data_rec_spi_valid_r2   <= '0';
                r_RECEIVE_DATA_O        <= (others => '0');
                r_VALID_O               <= '0';
            end if;
        end if;
    end process;

    RX_capture_rising : process(SCLK, SS)
        variable bit_number_rx_rising : integer range 0 to data_RX_spi_slave_reg_width := data_RX_spi_slave_reg_width;
    begin
        if SS = '1' then
            bit_number_rx_rising := data_RX_spi_slave_reg_width;
        end if;

        if rising_edge(SCLK) then
            receive_data_risnig(bit_number_rx_rising - 1)   <= MOSI;
            data_rec_spi_valid_risnig                       <= '0';
            bit_number_rx_rising                            := bit_number_rx_rising - 1;
            if bit_number_rx_rising = 0 then
                data_rec_spi_valid_risnig  <= '1';
                bit_number_rx_rising := data_RX_spi_slave_reg_width;
            end if;
        end if;
    end process RX_capture_rising;

    RX_capture_falling : process(SCLK, SS)
        variable bit_number_rx_falling : integer range 0 to data_RX_spi_slave_reg_width := data_RX_spi_slave_reg_width;
    begin      
        if SS = '1' then
            bit_number_rx_falling := data_RX_spi_slave_reg_width;
        end if;

        if falling_edge(SCLK) then
            receive_data_falling(bit_number_rx_falling - 1) <= MOSI;
            data_rec_spi_valid_falling                      <= '0';
            bit_number_rx_falling                           := bit_number_rx_falling - 1;
            if bit_number_rx_falling = 0 then
                data_rec_spi_valid_falling  <= '1';
                bit_number_rx_falling       := data_RX_spi_slave_reg_width;
            end if;
        end if;
    end process RX_capture_falling;
          

    MISO    <= MISO_rising when launch_edge = '1' else MISO_falling;
    TX_launch_edge_rising : process(SCLK, SS)
        variable bit_number_tx_rising : integer range 0 to data_TX_spi_slave_reg_width := data_TX_spi_slave_reg_width ;
    begin
        if SS = '1' then
            shift_rising_en         <= '1'; 
            MISO_rising             <= 'Z'; 
            bit_number_tx_rising    := data_TX_spi_slave_reg_width;
        end if;

        if SS = '0' and shift_rising_en = '1' then
            shift_rising_en <= '0';
            if CPHA = '0' then
                MISO_rising             <= SEND_DATA_I_r(data_TX_spi_slave_reg_width - 1);
                bit_number_tx_rising    := bit_number_tx_rising - 1;
            end if;
        end if;

        if rising_edge(SCLK) then
            if CPHA = '0' then
                if bit_number_tx_rising /= 0 then
                    MISO_rising             <= SEND_DATA_I_r(bit_number_tx_rising - 1); 
                    bit_number_tx_rising    := bit_number_tx_rising - 1;
                end if;
            else
                MISO_rising             <= SEND_DATA_I_r(bit_number_tx_rising - 1); 
                bit_number_tx_rising    := bit_number_tx_rising - 1;
            end if;
        end if;
    end process TX_launch_edge_rising;

    TX_launch_edge_falling : process(SCLK, SS)
        variable bit_number_tx_falling : integer range 0 to data_TX_spi_slave_reg_width := data_TX_spi_slave_reg_width ;
    begin
        if SS = '1' then
            shift_falling_en        <= '1'; 
            MISO_falling            <= 'Z'; 
            bit_number_tx_falling   := data_TX_spi_slave_reg_width;
        end if;

        if SS = '0' and shift_falling_en = '1' then
            shift_falling_en <= '0';
            if CPHA = '0' then
                MISO_falling            <= SEND_DATA_I_r(data_TX_spi_slave_reg_width - 1);
                bit_number_tx_falling   := bit_number_tx_falling - 1;
            end if;
        end if;

        if falling_edge(SCLK) then
            if CPHA = '0' then
                if bit_number_tx_falling /= 0 then
                    MISO_falling            <= SEND_DATA_I_r(bit_number_tx_falling - 1); 
                    bit_number_tx_falling   := bit_number_tx_falling - 1;
                end if;
            else
                MISO_falling            <= SEND_DATA_I_r(bit_number_tx_falling - 1); 
                bit_number_tx_falling   := bit_number_tx_falling - 1;
            end if;
        end if;
    end process TX_launch_edge_falling;

end architecture behavioral;





 

