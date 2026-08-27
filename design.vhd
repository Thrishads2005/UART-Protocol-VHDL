library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    generic (
        CLK_FREQ : integer := 1000000;
        BAUD_RATE : integer := 100000
    );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;

        tx_start  : in  std_logic;
        tx_data   : in  std_logic_vector(7 downto 0);
        tx        : out std_logic;
        tx_busy   : out std_logic;

        rx        : in  std_logic;
        rx_data   : out std_logic_vector(7 downto 0);
        rx_valid  : out std_logic
    );
end entity uart;

architecture rtl of uart is

    constant BIT_CYCLES : integer := CLK_FREQ / BAUD_RATE;

    -- Transmitter states
    type tx_state_type is (
        TX_IDLE_STATE,
        TX_START_STATE,
        TX_DATA_STATE,
        TX_STOP_STATE
    );

    -- Receiver states
    type rx_state_type is (
        RX_IDLE_STATE,
        RX_START_STATE,
        RX_DATA_STATE,
        RX_STOP_STATE
    );

    signal tx_state : tx_state_type := TX_IDLE_STATE;
    signal rx_state : rx_state_type := RX_IDLE_STATE;

    signal tx_counter : integer range 0 to BIT_CYCLES := 0;
    signal rx_counter : integer range 0 to BIT_CYCLES := 0;

    signal tx_bit_index : integer range 0 to 7 := 0;
    signal rx_bit_index : integer range 0 to 7 := 0;

    signal tx_shift : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_shift : std_logic_vector(7 downto 0) := (others => '0');

    signal tx_reg : std_logic := '1';
    signal tx_busy_reg : std_logic := '0';

    signal rx_data_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid_reg : std_logic := '0';

begin

    tx <= tx_reg;
    tx_busy <= tx_busy_reg;
    rx_data <= rx_data_reg;
    rx_valid <= rx_valid_reg;

    ----------------------------------------------------------------
    -- UART TRANSMITTER
    ----------------------------------------------------------------
    tx_process : process(clk)
    begin
        if rising_edge(clk) then

            if reset = '1' then

                tx_state <= TX_IDLE_STATE;
                tx_counter <= 0;
                tx_bit_index <= 0;
                tx_shift <= (others => '0');
                tx_reg <= '1';
                tx_busy_reg <= '0';

            else

                case tx_state is

                    when TX_IDLE_STATE =>

                        tx_reg <= '1';
                        tx_busy_reg <= '0';
                        tx_counter <= 0;
                        tx_bit_index <= 0;

                        if tx_start = '1' then
                            tx_shift <= tx_data;
                            tx_busy_reg <= '1';
                            tx_state <= TX_START_STATE;
                        end if;


                    when TX_START_STATE =>

                        tx_reg <= '0';

                        if tx_counter = BIT_CYCLES - 1 then
                            tx_counter <= 0;
                            tx_bit_index <= 0;
                            tx_state <= TX_DATA_STATE;
                        else
                            tx_counter <= tx_counter + 1;
                        end if;


                    when TX_DATA_STATE =>

                        tx_reg <= tx_shift(tx_bit_index);

                        if tx_counter = BIT_CYCLES - 1 then

                            tx_counter <= 0;

                            if tx_bit_index = 7 then
                                tx_state <= TX_STOP_STATE;
                            else
                                tx_bit_index <= tx_bit_index + 1;
                            end if;

                        else
                            tx_counter <= tx_counter + 1;
                        end if;


                    when TX_STOP_STATE =>

                        tx_reg <= '1';

                        if tx_counter = BIT_CYCLES - 1 then
                            tx_counter <= 0;
                            tx_busy_reg <= '0';
                            tx_state <= TX_IDLE_STATE;
                        else
                            tx_counter <= tx_counter + 1;
                        end if;

                end case;

            end if;
        end if;
    end process;


    ----------------------------------------------------------------
    -- UART RECEIVER
    ----------------------------------------------------------------
    rx_process : process(clk)
    begin
        if rising_edge(clk) then

            if reset = '1' then

                rx_state <= RX_IDLE_STATE;
                rx_counter <= 0;
                rx_bit_index <= 0;
                rx_shift <= (others => '0');
                rx_data_reg <= (others => '0');
                rx_valid_reg <= '0';

            else

                rx_valid_reg <= '0';

                case rx_state is

                    when RX_IDLE_STATE =>

                        rx_counter <= 0;
                        rx_bit_index <= 0;

                        -- Detect start bit
                        if rx = '0' then
                            rx_state <= RX_START_STATE;
                        end if;


                    when RX_START_STATE =>

                        -- Wait half a bit before checking start bit
                        if rx_counter = (BIT_CYCLES / 2) then

                            if rx = '0' then
                                rx_counter <= 0;
                                rx_bit_index <= 0;
                                rx_state <= RX_DATA_STATE;
                            else
                                rx_state <= RX_IDLE_STATE;
                            end if;

                        else
                            rx_counter <= rx_counter + 1;
                        end if;


                    when RX_DATA_STATE =>

                        if rx_counter = BIT_CYCLES - 1 then

                            rx_counter <= 0;
                            rx_shift(rx_bit_index) <= rx;

                            if rx_bit_index = 7 then
                                rx_state <= RX_STOP_STATE;
                            else
                                rx_bit_index <= rx_bit_index + 1;
                            end if;

                        else
                            rx_counter <= rx_counter + 1;
                        end if;


                    when RX_STOP_STATE =>

                        if rx_counter = BIT_CYCLES - 1 then

                            rx_counter <= 0;
                            rx_data_reg <= rx_shift;
                            rx_valid_reg <= '1';
                            rx_state <= RX_IDLE_STATE;

                        else
                            rx_counter <= rx_counter + 1;
                        end if;

                end case;

            end if;
        end if;
    end process;

end architecture rtl;
