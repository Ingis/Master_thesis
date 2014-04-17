

library ieee;

   use ieee.std_logic_1164.all;

   use ieee.std_logic_unsigned.all;

  -- use ieee.numeric_signed.all;

   

entity tx_uart is

  port (

     clk    : in  std_logic;  -- system clock signal
     areset_n  : in  std_logic;  -- Reset input
     tx_busy : out std_logic;
     txd    : out  std_logic;  -- RS-232 data output
     data_load : in std_logic;
     data_in  : in std_logic_vector(7 downto 0)); -- Byte received

    

end tx_uart;

architecture Behaviour of tx_uart is

signal tx_reg       : std_logic_vector(7 downto 0);
signal txd_int      : std_logic;

type state_type is (IDLE, START, SAMPLE, STOP);
signal CURRENT_STATE       :state_type;
signal BAUD_STATE          :state_type;
signal NEXT_STATE          :state_type;

--signal sample_rate : integer range 0 to 174;
signal sample_rate    : integer range 0 to 347;
signal tx_bit_counter : integer range 0 to 10;
signal ena_sample_cnt   : std_logic;
signal ena_tx_cnt     : std_logic;
signal reset_tx_cnt   : std_logic;

begin

data_in_proc:  process (clk, areset_n)

begin

  if (areset_n = '0') then
     tx_reg <= "00000000" after 5 ns;
  elsif rising_edge(clk) then
    if (data_load = '1') then 
      tx_reg <= data_in after 5 ns;
    else
      tx_reg <= tx_reg after 5 ns;
   end if;
  end if;
end process data_in_proc;





state_proc:  process (clk, areset_n)
begin
  if (areset_n = '0') then
     CURRENT_STATE <= IDLE after 5 ns;
  elsif rising_edge(clk) then
     CURRENT_STATE <= NEXT_STATE after 5 ns;
    end if;  
end process state_proc;


count_proc:  process (clk, areset_n)
begin
  if (areset_n = '0') then
     sample_rate <= 0 after 5 ns;
     tx_bit_counter <= 0 after 5 ns;
  elsif rising_edge(clk) then
     if (ena_sample_cnt = '1') then
       sample_rate <= sample_rate + 1 after 5 ns;
     else
       sample_rate <= 0  after 5 ns;
     end if;  

     if (ena_tx_cnt = '1' and reset_tx_cnt = '0') then
       tx_bit_counter <= tx_bit_counter + 1 after 5 ns;
     elsif (reset_tx_cnt = '1') then
       tx_bit_counter <= 0 after 5 ns;
     else  
       tx_bit_counter <= tx_bit_counter after 5 ns;
     end if;    

  end if;  
end process count_proc;


txd <= txd_int ;

tx_proc: process (CURRENT_STATE, data_load, tx_bit_counter,sample_rate,tx_reg)

begin


    txd_int <= txd_int after 5 ns;
    BAUD_STATE     <= IDLE after 5 ns;  
    tx_busy        <= '1' after 5 ns;  
    reset_tx_cnt   <= '0' after 5 ns;
    ena_tx_cnt     <= '0' after 5 ns;
    ena_sample_cnt   <= '0' after 5 ns;

case CURRENT_STATE is

 when IDLE =>                         --Wait on startbit
      reset_tx_cnt   <= '0' after 5 ns;
	  txd_int <= '1' after 5 ns;
      tx_busy <= '0' after 5 ns;
      NEXT_STATE <= IDLE after 5 ns;
      if data_load = '1' then
         tx_busy <= '0' after 5 ns;
         NEXT_STATE <= START after 5 ns;
      end if;

   when START =>
         reset_tx_cnt   <= '0' after 5 ns;
		 ena_sample_cnt   <= '1' after 5 ns;
         txd_int <= '0' after 5 ns;
         if (sample_rate = 347) then
           NEXT_STATE <= SAMPLE after 5 ns;
           ena_sample_cnt   <= '0' after 5 ns;
         else
           NEXT_STATE <= START after 5 ns;
         end if;

   when SAMPLE =>         
         reset_tx_cnt   <= '0' after 5 ns;
         txd_int <= tx_reg(tx_bit_counter) after 5 ns;
         ena_sample_cnt   <= '1' after 5 ns;
         if sample_rate = 347 then
           ena_tx_cnt <= '1' after 5 ns; --increase sample counter
           ena_sample_cnt <= '0' after 5 ns; --reset sample counter
           if tx_bit_counter = 7 then
               NEXT_STATE <= STOP after 5 ns;               
            else
               NEXT_STATE <= SAMPLE after 5 ns;                              
            end if;
         else             
             NEXT_STATE  <= SAMPLE after 5 ns;          
         end if;
  
   when STOP =>
       txd_int <= '1' after 5 ns;
       if sample_rate = 347 then
          ena_sample_cnt <= '0' after 5 ns; --reset sample counter
          reset_tx_cnt   <= '1' after 5 ns;
          NEXT_STATE <= IDLE after 5 ns;
       else
          reset_tx_cnt   <= '0' after  5 ns;
          ena_sample_cnt   <= '1' after 5 ns;
          NEXT_STATE <= STOP after 5 ns;          
       end if;
       
   when others =>
      NEXT_STATE <= IDLE after 5 ns;

   end case;

end process tx_proc;

end Behaviour;

