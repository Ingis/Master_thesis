

library ieee;

   use ieee.std_logic_1164.all;

   use ieee.std_logic_unsigned.all;

   

entity rx_uart is

  port (

     clk    : in  std_logic;  -- system clock signal
     areset_n  : in  std_logic;  -- Reset input
     rxd    : in  std_logic;  -- RS-232 data input
     data_av   : out std_logic;  -- Byte available
     data_out  : out std_logic_vector(7 downto 0) -- Byte received
  
     );

end rx_uart;

architecture Behaviour of rx_uart is


  signal Dout         : std_logic_vector(7 downto 0);
  signal data_reg       : std_logic_vector(7 downto 0);
  signal rx_rdy       : std_logic;
  signal rx_err       : std_logic;
 signal rxd_reg      : std_logic;
 signal rxd_reg_temp : std_logic;
  --signal rx_bit_count : std_logic_vector(3 downto 0);

---old---


type state_type is (IDLE, START_BIT, SAMPLE, STOP_BIT);
signal CURRENT_STATE       :state_type;

signal NEXT_STATE          :state_type;

--signal sample_rate : integer range 0 to 174;
signal sample_rate    : integer range 0 to 347;
signal wait_counter   : integer  range 0 to 174;
signal rx_bit_counter : integer range 0 to 10;
signal ena_sample_cnt   : std_logic;
signal ena_rx_cnt     : std_logic;
signal reset_rx_cnt   : std_logic;

begin




--synchronization registers--------------------
rxd_reg_temp_proc : process (clk, areset_n)
begin 
  if (areset_n = '0') then
     rxd_reg_temp <= '1' after 5 ns;
  elsif rising_edge(clk) then
     rxd_reg_temp <= rxd after 5 ns;
  end if;
end process rxd_reg_temp_proc;


rxd_reg_proc : process (clk, areset_n)
begin 
  if (areset_n = '0') then
     rxd_reg <= '1' after 5 ns;
  elsif rising_edge(clk) then
     rxd_reg <= rxd_reg_temp after 5 ns;
  end if;
end process rxd_reg_proc;
--synchonization registers--------------------



-------------old
data_out <= Dout;

Dout_proc: process (clk, areset_n)

begin
  if (areset_n = '0') then
     Dout <= "00000000" after 5 ns;
     data_av <= '0' after 5 ns;
  elsif rising_edge(clk) then
     if (rx_rdy ='1') then
       Dout <= data_reg after 5 ns;
       data_av <= '1' after 5 ns;
     else
       Dout <= Dout after 5 ns;
       data_av <= '0' after 5 ns;
     end if;
  end if;
end process Dout_proc;  
----old-------

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
     rx_bit_counter <= 0 after 5 ns;
     
  elsif rising_edge(clk) then
     if (ena_sample_cnt = '1') then
       sample_rate <= sample_rate + 1 after 5 ns;
     else
       sample_rate <= 0  after 5 ns;
     end if;  

     if (ena_rx_cnt = '1' and reset_rx_cnt = '0') then
       rx_bit_counter <= rx_bit_counter + 1 after 5 ns;
     elsif (reset_rx_cnt = '1') then
       rx_bit_counter <= 0 after 5 ns;
     else  
       rx_bit_counter <= rx_bit_counter after 5 ns;
     end if;    
       
  end if;  
end process count_proc;





rx_proc: process (CURRENT_STATE, rxd_reg, rx_bit_counter,sample_rate)
begin

  
  
 
    rx_err         <= '0' after 5 ns;
    rx_rdy         <= '0' after 5 ns;
    data_reg       <= data_reg after 5 ns;
    ena_sample_cnt <= '1' after 5 ns;
    ena_rx_cnt     <= '0' after 5 ns;
    reset_rx_cnt   <= '0' after 5 ns;
    
    
    

case CURRENT_STATE is

   when IDLE =>                         --Wait on startbit
      data_reg <= X"00" after 5 ns;
      ena_sample_cnt   <= '0' after 5 ns;
        
      if (rxd_reg = '0') then
        NEXT_STATE  <= START_BIT  after 5 ns;
      else
        NEXT_STATE  <= IDLE  after 5 ns;
      end if;      
  
   when START_BIT =>
     if (sample_rate = 174) then   -- check on sample_rate 175 to avoid conflict with next state
       if rxd_reg = '1'  then
         rx_err <= '1' after 5 ns;
         NEXT_STATE <= IDLE after 5 ns;
       else
         NEXT_STATE <= START_BIT after 5 ns;  
       end if;        
     elsif (sample_rate = 347) then
         NEXT_STATE <= SAMPLE after 5 ns;
         ena_sample_cnt <= '0' after 5 ns; --reset sample counter
     else
         NEXT_STATE <= START_BIT after 5 ns;   
     end if;    

   when SAMPLE =>
        data_reg <= data_reg after 5 ns;
       if  (sample_rate = 174)  then  
          data_reg(rx_bit_counter) <= rxd_reg after 5 ns;
          NEXT_STATE <= SAMPLE after 5 ns;
       elsif (sample_rate = 347) then
          ena_sample_cnt <= '0' after 5 ns; --reset sample counter
          if (rx_bit_counter = 7) then
             NEXT_STATE <= STOP_BIT after 5 ns;
             reset_rx_cnt   <= '1' after 5 ns; --rest rx_bit_counter counter
          else
             ena_rx_cnt <= '1' after 5 ns;
             NEXT_STATE <= SAMPLE after 5 ns;
          end if;   
       else 
          NEXT_STATE <= SAMPLE after 5 ns;          
       end if;

  when STOP_BIT =>
       if (sample_rate = 174) then   -- check on sample_rate 175 to avoid conflict with next state
         if rxd_reg = '0'  then
           rx_err <= '1' after 5 ns;
           rx_rdy <= '0' after 5 ns;
         else 
           rx_rdy <= '1' after 5 ns;   
         end if;    
         NEXT_STATE <= IDLE after 5 ns;
       else
         NEXT_STATE <= STOP_BIT after 5 ns;
       end if;  
         
  when others =>
      NEXT_STATE <= IDLE after 5 ns;       
         
           
 end case;
end process rx_proc;


end Behaviour;

