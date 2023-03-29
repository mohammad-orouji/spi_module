library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
    generic (
        control_command_RX_width    : integer   := 0;
        data_RX_width               : integer   := 8;
        data_TX_width               : integer   := 8;
        CPOL                        : std_logic := '0';
        CPHA                        : std_logic := '0';

        -- MODE = 00 -->  captur_edge ='1' & launch_edge ='0'
        -- MODE = 01 -->  captur_edge ='0' & launch_edge ='1'
        -- MODE = 10 -->  captur_edge ='0' & launch_edge ='1'
        -- MODE = 11 -->  captur_edge ='1' & launch_edge ='0'
        captur_edge                 : std_logic := '0';         -- '0' : falling_edge , '1' : rising_edge    
        launch_edge                 : std_logic := '0'          -- '0' : falling_edge , '1' : rising_edge    

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
        SEND_DATA_I     : in  std_logic_vector(data_TX_width-1 downto 0);
        READY_O         : out std_logic;
        VALID_I         : in  std_logic;
        ------------------------------------
        RECEIVE_DATA_O  : out std_logic_vector(data_RX_width-1 downto 0);  
        READY_I         : in  std_logic;
        VALID_O         : out std_logic
    );
end entity spi_slave;

architecture behavioral of spi_slave is

    constant control_data_bit_num       : integer := (control_command_RX_width + data_RX_width + data_TX_width);
    constant control_data_bit_num_rx    : integer := (control_command_RX_width + data_RX_width);  

    signal data_received    : std_logic;
    signal data_Transferred : std_logic;
    signal spi_ready        : std_logic;
    signal ready            : std_logic;
    signal r_READY_O        : std_logic;

------------------------------------------RX or MOSI------------------------------------------
    signal count_RX            : integer range 0 to control_data_bit_num_rx := 0;
    signal counting_RX         : std_logic;
    signal data_SR          : std_logic_vector(data_RX_width-1 downto 0);
    signal data             : std_logic_vector(data_RX_width-1 downto 0);
    signal data_r           : std_logic_vector(data_RX_width-1 downto 0);
    signal data_r2          : std_logic_vector(data_RX_width-1 downto 0);
    signal rx_spi_valid     : std_logic;
    signal rx_spi_valid_r   : std_logic;
    signal rx_spi_valid_r2  : std_logic;
    signal r_RECEIVE_DATA_O : std_logic_vector(data_RX_width-1 downto 0) := (others => '0');
    signal r_VALID_O        : std_logic := '0';

------------------------------------------TX or MISO------------------------------------------
    signal SEND_DATA_I_r    : std_logic_vector(data_TX_width-1 downto 0)  := (others => '0');
    signal SEND_DATA_I_r2   : std_logic_vector(data_TX_width-1 downto 0)  := (others => '0');
    signal count_TX         : integer range 0 to control_data_bit_num := 0;
    signal counting_TX      : std_logic;
    signal count_TX_Flag    : integer range 0 to data_TX_width := 0;

begin

    r_READY_O  <= spi_ready and ready;
    READY_O    <= r_READY_O;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            SEND_DATA_I_r   <= SEND_DATA_I_r;
            -- r_SS            <= SS;

            -- data_Transferred <= '1';
            spi_ready        <= '1';
            ready            <= '1';
            data_received    <= data_received;

            if VALID_I = '1' and r_READY_O = '1' then
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
        end if;
    end process;

-----------------------------------------RX or MOSI-----------------------------------------
    RECEIVE_DATA_O      <= r_RECEIVE_DATA_O;
    VALID_O             <= r_VALID_O;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if rx_spi_valid_r = '0' and rx_spi_valid_r2 = '1' then
                if r_VALID_O = '0' then
                    r_RECEIVE_DATA_O <= data_r2   ;
                else
                    r_RECEIVE_DATA_O <= r_RECEIVE_DATA_O;
                end if;
                r_VALID_O <= '1';
            end if;

            if r_VALID_O = '1' and READY_I = '1' then
                r_VALID_O       <= '0';
            end if;

            if RESET_I = '1' then
                r_RECEIVE_DATA_O    <= (others => '0');
                r_VALID_O           <= '0';
            end if;
        end if;
    end process;
 -- if generate statement
    RX: if RX_rising: captur_edge = '1' generate 
            process(SCLK, SS) 
            begin
                if SS = '1' then
                    count_RX       <= 0;
                    counting_RX    <= '0';
                elsif rising_edge(SCLK) then
                    counting_RX    <= '0';
                    count_RX       <= count_RX + 1;
                    if count_RX = (control_data_bit_num_rx - 1) then
                        counting_RX    <= '1';
                    end if;
                    if RESET_I = '1' then
                        count_RX       <= 0;
                        counting_RX    <= '0';
                    end if;
                end if;
            end process;

            process(SCLK)
            begin
                if rising_edge(SCLK) then
                    data_SR <= data_SR(6 downto 0) & MOSI;   
                end if;
            end process; 
        end RX_rising;
    else RX_falling: generate
            process(SCLK, SS) 
            begin
                if SS = '1' then
                    count_RX       <= 0;
                    counting_RX    <= '0';        
                elsif falling_edge(SCLK) then
                    counting_RX    <= '0';
                    count_RX       <= count_RX + 1;
                    if count_RX = (control_data_bit_num_rx - 1) then
                        counting_RX    <= '1';
                    end if;
                    if RESET_I = '1' then
                        count_RX       <= 0;
                        counting_RX    <= '0';
                    end if;
                end if;
            end process;

            process(SCLK)
            begin  
                if falling_edge(SCLK) then
                    data_SR <= data_SR(6 downto 0) & MOSI;   
                end if;
            end process; 
        end RX_falling;
    end generate RX;
 --end if generate statement

    data            <= data_SR when counting_RX = '1' else data_r;
    rx_spi_valid    <= '1'     when counting_RX = '1' else '0';

    process(CLK_I) 
    begin
        if rising_edge(CLK_I) then
            data_r            <= data;
            data_r2           <= data_r;
            rx_spi_valid_r    <= rx_spi_valid;
            rx_spi_valid_r2   <= rx_spi_valid_r;
            if RESET_I = '1' then
                data_r            <= (others => '0');
                data_r2           <= (others => '0');
                rx_spi_valid_r    <= '1';
                rx_spi_valid_r2   <= '1';
            end if;  
        end if;
    end process; 
-------------------------------------END RX or MOSI-----------------------------------------

-----------------------------------------TX or MISO-----------------------------------------
    count_TX_Flag <=  (control_data_bit_num_rx - 1) when CPHA = '1' else (control_data_bit_num_rx - 2);
 -- if generate statement
    TX: if TX_rising: launch_edge = '1' generate 

            process(SCLK, SS) 
            begin
                if SS = '1' then
                    count_TX       <= 0;
                    counting_TX    <= '0';
                elsif rising_edge(SCLK) then
                    counting_TX    <= '0';
                    count_TX       <= count_TX + 1;
                    if count_TX > count_TX_Flag then
                        counting_TX    <= '1';
                    end if;
                    if RESET_I = '1' then
                        count_TX       <= 0;
                        counting_TX    <= '0';
                    end if;
                end if;
            end process;

            process(SCLK) 
            begin
                if rising_edge(SCLK) then
                    SEND_DATA_I_r2 <= SEND_DATA_I_r;
                    if counting_TX = '1' then
                        SEND_DATA_I_r2 <= SEND_DATA_I_r2(data_TX_width - 2 downto 0) & '0';
                    end if;
                    if RESET_I = '1' then
                        SEND_DATA_I_r2 <= (others => '0');
                    end if;
                end if;
            end process;

        end TX_rising;
    else TX_falling: generate
            process(SCLK, SS) 
            begin
                if SS = '1' then
                    count_TX       <= 0;
                    counting_TX    <= '0';
                elsif falling_edge(SCLK) then
                    counting_TX    <= '0';
                    count_TX       <= count_TX + 1;
                    if count_TX > count_TX_Flag then
                        counting_TX    <= '1';
                    end if;
                    if RESET_I = '1' then
                        count_TX       <= 0;
                        counting_TX    <= '0';
                    end if;
                end if;
            end process;

            process(SCLK) 
            begin
                if falling_edge(SCLK) then
                    SEND_DATA_I_r2 <= SEND_DATA_I_r;
                    if counting_TX = '1' then
                        SEND_DATA_I_r2 <= SEND_DATA_I_r2(data_TX_width - 2 downto 0) & '0';
                    end if;
                    if RESET_I = '1' then
                        SEND_DATA_I_r2 <= (others => '0');
                    end if;
                end if;
            end process;

        end TX_falling;
    end generate TX;
 --end if generate statement

    MISO <= SEND_DATA_I_r2(data_TX_width -1) when counting_TX = '1' else 'Z';
-------------------------------------END TX or MISO-----------------------------------------

end architecture behavioral;





 

