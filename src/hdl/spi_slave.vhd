library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
    generic (
        data_TX_spi_slave_reg_width : integer   := 8;
        data_RX_spi_slave_reg_width : integer   := 8;
        CPOL            : std_logic := '0';
        CPHA            : std_logic := '0'
        -- MSB_first       : integer := 1; 
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
        RECEIVE_DATA_O  : out std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0)  
        READY_I         : in  std_logic;
        VALID_O         : out std_logic
    );
end entity spi_slave;

architecture behavioral of spi_slave is

    signal bit_number   : natural range 0 to data_TX_spi_slave_reg_width;

    signal spi_mode         : std_logic_vector(1 downto 0);
    signal captur_edge      : std_logic;

    signal data_received    : std_logic;
    signal data_Transferred : std_logic;
    signal spi_ready        : std_logic;

    signal SEND_DATA_I_r        : std_logic_vector(data_TX_spi_reg_width-1 downto 0);

    signal r_RECEIVE_DATA_O     : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0);
    signal r2_RECEIVE_DATA_O    : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0);
    signal r3_RECEIVE_DATA_O    : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0);
    signal r4_RECEIVE_DATA_O    : std_logic_vector(data_RX_spi_slave_reg_width-1 downto 0);

begin

    READY_O  <= spi_ready and data_Transferred;
    spi_mode <= CPHA & CPOL;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            SEND_DATA_I_r   <= SEND_DATA_I_r;
            r_SS            <= SS;

            data_Transferred <= '1';
            spi_ready        <= '1';
            data_received    <= '0';
            if VALID_I = '1' and READY_O = '1' then
                SEND_DATA_I_r   <= SEND_DATA_I;
                data_received   <= '1';
            end if;

            if r_SS = '0' then
                spi_ready        <= '0';
                data_Transferred <= '1';
            end if;

            if r_SS = '1' and data_received = '1' then
                data_Transferred <= '0';
            end if;

            if RESET_I = '1' then
                SEND_DATA_I_r    <= (others => '0');
                data_Transferred <= '1';
                spi_ready        <= '1';
                data_received    <= '0';
            end if;

            case spi_mode is
                --MODE 00
                when 00 =>
                    captur_edge <= '1';     --risng_edge
                --MODE 10
                when 10 =>
                    captur_edge <= '0';     --falling_edge
                --MODE 01
                when 01 =>
                    captur_edge <= '0';     --falling_edge
                --MODE 11
                when 11 =>
                    captur_edge <= '1';     --risng_edge
                --MODE 00
                when others =>
                    captur_edge <= '1';     --risng_edge
            end case;
                
        end if;
    end process;

    receive_data    <= r_RECEIVE_DATA_O;
    VALID_O         <= r_VALID_O;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            -- receive_data_r2       <= receive_data_r;
            -- receive_data_r3       <= receive_data_r2;
            receive_data_r          <= receive_data;
            receive_data_r2         <= receive_data_r;
            data_rec_spi_valid_r    <= data_rec_spi_valid;
            data_rec_spi_valid_r2   <= data_rec_spi_valid_r;
            if data_rec_spi_valid_r = '0' and data_rec_spi_valid_r2 = '1' then
                r_RECEIVE_DATA_O   <= receive_data_r2;
                r_VALID_O          <= '1';
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

    process(SCLK)
    begin
        if spi_mode = '1' then
            if rising_edge(SCLK) then
                receive_data(bit_number - 1) <= MOSI;
                data_rec_spi_valid           <= '0';
                -- receive_data_r            <= receive_data;
                MISO        <= SEND_DATA_I_r(bit_number - 1); 
                bit_number  <= bit_number - 1;
                if bit_number = 1 then
                    -- receive_data_r   <= receive_data;
                    data_rec_spi_valid  <= '1';
                    bit_number          <= data_TX_spi_slave_reg_width;
                end if;

                if RESET_I = '1' then
                    receive_data    <= (others => '0');
                    -- receive_data_r   <= (others => '0');
                    MISO                <= 'Z'; 
                    bit_number          <= data_TX_spi_slave_reg_width;
                end if;
            end if;
        else
            if falling_edge(SCLK) then
                receive_data(bit_number - 1) <= MOSI;
                data_rec_spi_valid           <= '0';
                -- receive_data_r            <= receive_data;
                MISO        <= SEND_DATA_I_r(bit_number - 1); 
                bit_number  <= bit_number - 1;
                if bit_number = 1 then
                    -- receive_data(bit_number - 1)   <= MOSI;
                    -- receive_data_r(bit_number - 1) <= MOSI;
                    data_rec_spi_valid  <= '1';
                    bit_number          <= data_TX_spi_slave_reg_width;
                end if;

                if RESET_I = '1' then
                    receive_data        <= (others => '0');
                    -- receive_data_r   <= (others => '0');
                    MISO                <= 'Z'; 
                    bit_number          <= data_TX_spi_slave_reg_width;
                end if;
            end if;
        end if;
    end process;

end architecture behavioral;





 

