library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_master is
    generic (
        control_command_TX_width    : integer   := 0;
        data_TX_width               : integer   := 8;
        data_RX_width               : integer   := 8;
        SYS_CLOCK       : integer   := 10;   --100 MHz 
        SPI_CLOCK       : integer   := 100;  --10 MHz 
        CPOL            : std_logic := '0';
        CPHA            : std_logic := '0'
        -- MSB_first       : integer := 1; 
        -- LSB_first       : integer := 0
    );
    port (
        CLK_I           : in  std_logic;
        RESET_I         : in  std_logic;
        ------------------------------------
        SCLK            : out std_logic;
        MOSI            : out std_logic;
        MISO            : in  std_logic;
        SS              : out std_logic;
        ------------------------------------
        SEND_DATA_I     : in  std_logic_vector(data_TX_width-1 downto 0);
        START_SEND_I    : in  std_logic;
        READY_O         : out std_logic;
        VALID_I         : in  std_logic;
        ------------------------------------
        RECEIVE_DATA_O  : out std_logic_vector(data_RX_width-1 downto 0);  
        READY_I         : in  std_logic;
        VALID_O         : out std_logic
    );
end entity spi_master;

architecture behavioral of spi_master is
    
    constant TX                : natural := control_command_TX_width + data_TX_width;
    signal   TX_bit_number     : natural range 0 to TX;
    signal   TX_bit_number_r   : natural range 0 to TX;

    constant RX                : natural := data_RX_width;
    signal   RX_bit_number     : natural range 0 to RX;
    signal   RX_bit_number_r   : natural range 0 to RX;

    constant half_period_spi    : natural := (SPI_CLOCK / sys_CLOCK) /2;
    constant period_spi         : natural := SPI_CLOCK / sys_CLOCK;
    signal   t2                 : natural range 0 to period_spi := period_spi;

    signal r_READY_O            : std_logic;
    signal START_SEND_I_r       : std_logic;
    signal SEND_DATA_I_r        : std_logic_vector(data_TX_width-1 downto 0) := (others => '0');
    signal SEND_DATA_I_r2       : std_logic_vector(data_TX_width-1 downto 0) := (others => '0');
    signal SEND_DATA_I_r3       : std_logic_vector(data_TX_width-1 downto 0) := (others => '0');
    
    signal receive_data        : std_logic_vector(data_RX_width-1 downto 0)  := (others => '0');
    signal receive_data_r      : std_logic_vector(data_RX_width-1 downto 0)  := (others => '0');
    signal r_RECEIVE_DATA_O    : std_logic_vector(data_RX_width-1 downto 0) := (others => '0');
    signal r_VALID_O           : std_logic;

    signal r_SCLK   : std_logic := CPOL;
    signal r2_SCLK  : std_logic := CPOL;
    signal r_MOSI   : std_logic;
    signal r2_MOSI  : std_logic;
    signal r_SS     : std_logic := '1';
    signal r2_SS    : std_logic := '1';
    -- signal MISO_r               : std_logic;
    signal data_rec_spi_valid   : std_logic;
    signal data_rec_spi_valid_r : std_logic;
    

    signal data_valid       : std_logic;
    signal data_valid_ack   : std_logic;

    type state is (idle, receive_date_send, wait_for_start_send, 
        determining_the_CPAH, TX_state_cphas_1, TX_state_cphas_0, 
        final_delay, RX_state_cphas_0, RX_state_cphas_1);
    signal present_state : state := idle;
    signal next_state    : state := idle;

begin
          
    MOSI    <= r2_MOSI; 
    SCLK    <= r2_SCLK; 
    SS      <= r2_SS;  
    READY_O <= r_READY_O;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            START_SEND_I_r <= START_SEND_I;
            SEND_DATA_I_r  <= SEND_DATA_I_r;
            data_valid     <= '0';
            if r_READY_O = '1' and VALID_I = '1' then
                SEND_DATA_I_r   <= SEND_DATA_I;
                data_valid      <= '1';
            end if;
            if data_valid_ack = '1' then
                data_valid  <= '0';
            end if;
            
            --FSM register
            SEND_DATA_I_r3      <= SEND_DATA_I_r2;
            r2_MOSI             <= r_MOSI;
            r2_SCLK             <= r_SCLK;
            r2_SS               <= r_SS;
            TX_bit_number_r     <= TX_bit_number;
            --------------------------------------------
            RX_bit_number_r     <= RX_bit_number;
            present_state       <= next_state;
            if RESET_I = '1' then
                present_state <= idle;
                SEND_DATA_I_r <= (others => '0');
                data_valid    <= '0';

                --FSM register
                SEND_DATA_I_r3      <= (others => '0');
                r2_MOSI             <= '0';
                r2_SCLK             <= CPOl;
                r2_SS               <= '1';
                TX_bit_number_r     <= 0;
                RX_bit_number_r     <= 0;
            end if;
        end if;
    end process;

    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if present_state /= next_state then
                t2 <= period_spi; 
            else
                if t2 /= 1 then
                    t2 <= t2 - 1;
                else
                    t2 <= period_spi;
                end if;
            end if;
        end if;
    end process;

    RECEIVE_DATA_O  <= r_RECEIVE_DATA_O;
    VALID_O         <= r_VALID_O;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            receive_data_r          <= receive_data;
            data_rec_spi_valid_r    <= data_rec_spi_valid;
            if data_rec_spi_valid = '0' and data_rec_spi_valid_r = '1' then
                if r_VALID_O = '0' then
                    r_RECEIVE_DATA_O <= receive_data_r;
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
                data_rec_spi_valid_r    <= '0';
                r_RECEIVE_DATA_O        <= (others => '0');
                r_VALID_O               <= '0';
            end if;
        end if;
    end process;

    process(all)
    begin
        case present_state is
            when idle =>
                r_SCLK             <= CPOL;
                r_MOSI             <= 'Z'; 
                r_SS               <= '1';
                receive_data       <= (others => '0'); 
                SEND_DATA_I_r2     <= (others => '0');
                TX_bit_number      <= 0;
                r_READY_O          <= '0';
                data_valid_ack     <= '0';
                data_rec_spi_valid <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;                  
                next_state          <= receive_date_send;
            when receive_date_send =>
                r_SCLK             <= CPOL;
                r_MOSI             <= 'Z'; 
                r_SS               <= '1';
                receive_data       <= receive_data_r;
                TX_bit_number      <= 0;
                r_READY_O          <= '1';
                SEND_DATA_I_r2     <= SEND_DATA_I_r3;
                data_valid_ack     <= '0';
                data_rec_spi_valid <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;                  
                next_state          <= receive_date_send;
                if data_valid = '1' then
                    SEND_DATA_I_r2  <= SEND_DATA_I_r;
                    next_state      <= wait_for_start_send;
                    r_READY_O       <= '0';
                    data_valid_ack  <= '1';
                end if;
            when wait_for_start_send =>
                r_SCLK             <= CPOL;
                r_MOSI             <= 'Z'; 
                r_SS               <= '1';
                receive_data       <= receive_data_r; 
                r_READY_O          <= '0';
                data_valid_ack     <= '0';
                SEND_DATA_I_r2     <= SEND_DATA_I_r3;
                TX_bit_number      <= 0;
                data_rec_spi_valid <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;                
                next_state          <= wait_for_start_send;
                if START_SEND_I_r = '1' then
                    next_state <= determining_the_CPAH;
                end if;
            when determining_the_CPAH =>
                r_SCLK             <= CPOL;
                r_MOSI             <= 'Z'; 
                r_SS               <= '1';
                receive_data       <= receive_data_r; 
                r_READY_O          <= '0';
                data_valid_ack     <= '0';
                SEND_DATA_I_r2     <= SEND_DATA_I_r3;
                TX_bit_number      <= 0;
                data_rec_spi_valid <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;
                next_state         <= TX_state_cphas_0;
                if CPHA = '1' then
                    next_state <= TX_state_cphas_1;
                end if;
            when TX_state_cphas_1 =>
                SEND_DATA_I_r2      <= SEND_DATA_I_r3;
                r_MOSI              <= r2_MOSI;
                r_SS                <= '0';
                r_SCLK              <= r2_SCLK;
                receive_data        <= receive_data_r;
                r_READY_O           <= '0';
                data_valid_ack      <= '0';
                TX_bit_number       <= TX_bit_number_r;
                data_rec_spi_valid  <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;
                if TX_bit_number_r = TX then
                    next_state  <= final_delay;
                else
                    if t2 = period_spi then
                        r_SCLK          <= CPOL;
                        TX_bit_number   <= TX_bit_number_r;
                    elsif t2 = half_period_spi then
                        r_MOSI        <= SEND_DATA_I_r3(TX - TX_bit_number_r - 1);
                        r_SCLK        <= not r2_SCLK;
                        TX_bit_number <= TX_bit_number_r + 1;
                    end if;
                    next_state <= TX_state_cphas_1;
                end if;
            when TX_state_cphas_0 =>
                SEND_DATA_I_r2      <= SEND_DATA_I_r3;
                r_MOSI              <= r2_MOSI;
                r_SS                <= '0';
                r_SCLK              <= r2_SCLK;
                receive_data        <= receive_data_r;
                r_READY_O           <= '0';
                data_valid_ack      <= '0';
                TX_bit_number       <= TX_bit_number_r;
                data_rec_spi_valid  <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;
                if TX_bit_number_r = TX then
                    next_state  <= final_delay;
                else
                    if t2 = period_spi then
                        r_MOSI          <= SEND_DATA_I_r3(TX - TX_bit_number_r - 1);
                        r_SCLK          <= CPOL;
                        TX_bit_number   <= TX_bit_number_r;
                    elsif t2 = half_period_spi then
                        r_SCLK          <= not r2_SCLK;
                        TX_bit_number   <= TX_bit_number_r + 1;
                    end if;
                    next_state <= TX_state_cphas_0;
                end if;
            when final_delay =>
                SEND_DATA_I_r2      <= SEND_DATA_I_r3;
                r_MOSI              <= r2_MOSI;
                r_SS                <= '0';
                r_SCLK              <= r2_SCLK;
                receive_data        <= receive_data_r;
                r_READY_O           <= '0';
                data_valid_ack      <= '0';
                TX_bit_number       <= 0;
                data_rec_spi_valid  <= '0';
                ---------------------------------------
                RX_bit_number       <= 0;
                next_state          <= final_delay;
                if t2 = half_period_spi + 2 then
                    r_SCLK  <= not r2_SCLK;
                    if CPHA = '0' then
                        r_MOSI <= 'Z';
                    else
                        r_MOSI <= r2_MOSI;
                    end if;
                end if;
                if t2 = 0 + 3 then
                    r_SCLK <= r2_SCLK;
                    if CPHA = '1' then
                        r_MOSI <= 'Z';
                        next_state  <= RX_state_cphas_1;
                    else
                        next_state  <= RX_state_cphas_0;
                    end if;
                end if;
            when RX_state_cphas_0 =>
                r_READY_O       <= '0';
                data_valid_ack  <= '0';
                TX_bit_number   <= 0;
                SEND_DATA_I_r2  <= SEND_DATA_I_r3;
                r_MOSI          <= 'Z';
                ---------------------------------------
                r_SCLK              <= r2_SCLK;
                receive_data        <= receive_data_r;
                RX_bit_number       <= RX_bit_number_r;
                data_rec_spi_valid  <= '0';
                r_SS                <= '0';
                next_state          <= RX_state_cphas_0;
                if t2 = period_spi then
                    if RX_bit_number_r = RX then
                        r_SS        <= '1';
                        data_rec_spi_valid  <= '1';     --MISO data completed
                        next_state  <= receive_date_send;
                    else
                        r_SCLK          <= not r2_SCLK;
                        receive_data(RX - RX_bit_number_r - 1)  <= MISO;
                        RX_bit_number   <= RX_bit_number_r + 1;
                    end if;
                end if;
                if t2 = half_period_spi then
                    r_SCLK          <= CPOL;
                    RX_bit_number   <= RX_bit_number_r;
                end if;
            when RX_state_cphas_1 =>
                r_READY_O       <= '0';
                data_valid_ack  <= '0';
                TX_bit_number   <= 0;
                SEND_DATA_I_r2  <= SEND_DATA_I_r3;
                r_MOSI          <= 'Z';
            ---------------------------------------
                r_SCLK              <= r2_SCLK;
                receive_data        <= receive_data_r;
                RX_bit_number       <= RX_bit_number_r;
                data_rec_spi_valid  <= '0';
                r_SS                <= '0';
                next_state          <= RX_state_cphas_1;
                if t2 = period_spi then
                    r_SCLK          <= not r2_SCLK;
                    if RX_bit_number = RX then
                        data_rec_spi_valid  <= '1';     --MISO data completed
                        r_SCLK              <= CPOL;
                        r_SS                <= '1';
                        next_state          <= receive_date_send;
                    end if;
                elsif t2 = half_period_spi then
                    receive_data(RX - RX_bit_number_r - 1)  <= MISO;
                    RX_bit_number   <= RX_bit_number_r + 1;
                    r_SCLK          <= CPOL;
                end if;
        end case;
    end process;

end architecture behavioral;
