/*Реализовать справочник коммутаторов. Необходимо обеспечить уникальность IP и MAC адресов. 
В случае, если remote_id должен использоваться в hex формате, поле REMOTE_ID_HEX становится обязательным к заполнению. 
Параметры доступов на чтение и запись, IP, MAC, remote_id являются обязательными для заполнения параметрами. 
Кроме того, необходимо проверять валидность IP. 
Результат: как минимум методы getCOMMUTATOR и saveCOMMUTATOR (при создании записи использовать s_incb_commutator.nextval 
для кода коммутатора) для справочника с учётом бизнес-ограничений и скрипт с примерами их использования 
(заполнение справочника, изменение записей, удаление записей, получение записей)
*/

--что-то пошло не так, пока не допер как
/*create or replace procedure saveCOMMUTATOR(pid_commutator      in incb_commutator.id_commutator%type, 
                                           pip_address         in incb_commutator.ip_address%type, 
                                           pid_commutator_type in incb_commutator.id_commutator_type%type,
                                           pv_description      in incb_commutator.v_description%type,
                                           pv_mac_address      in incb_commutator.v_mac_address%type,
                                           pv_community_read   in incb_commutator.v_community_read%type,
                                           pv_community_write  in incb_commutator.v_community_write%type,
                                           premote_id          in incb_commutator.remote_id%type,
                                           pb_need_convert_hex in incb_commutator.b_need_convert_hex%type,
                                           premote_id_hex      in incb_commutator.remote_id_hex%type,
                                           paction             in NUMBER default 1) is
   c_ip  in number;
   c_mac in number;
  begin */

--дальше, возможно, что-то похожее на правду..     
--Результат: как минимум методы getCOMMUTATOR 
/*create or replace procedure getCOMMUTATOR(pip_address         in incb_commutator.ip_address%type, 
                                            pv_mac_address      in incb_commutator.v_mac_address%type,
                                            premote_id          in incb_commutator.remote_id%type,
                                            dwr                 out  sys_refcursor) is                           
          begin 
            open dwr for
            select * from( select --
                                 c.* 
                             from incb_commutator c
                            where pip_address = c.ip_address
                              and c.b_deleted = 0) com1,
                         ( select --
                                 c.* 
                             from incb_commutator c
                            where pv_mac_address = c.v_mac_address
                              and c.b_deleted = 0) com2,
                         ( select --
                                 c.* 
                             from incb_commutator c
                            where premote_id= c.remote_id
                              and c.b_deleted = 0) com3
                            where com1.id_commutator = com2.id_commutator
                              and com2.id_commutator = com3.id_commutator;
                              close dwr;
                              end getCOMMUTATOR;
                              */
--2.
/*К описанному выше справочнику реализовать функцию check_access_comm, принимающая на вход IP-адрес, 
V_COMMUNITY (доступ на чтение или запиь) и B_MODE_WRITE, который равен 1, если нужно проверить доступ на запись, 
и 0 - на чтение. check_access_comm возвращает 1, если доступ есть, и 0 в противном случае. 
Метод должен уметь выбрасывать исключения в случае, если коммутатора с таким IP не существует. 
Результат: функция check_access_comm.*/

/*create or replace function check_access_commm(pip_address  in incb_commutator.ip_address%type,
                                                B_MODE_WRITE in number,
                                                V_COMMUNITY  in incb_commutator.v_community_read%type) 
  return number 
  is                                          
  ac_comm number;
begin 
  select -- ïðîâåðêà
   count(1)
    into ac_comm
    from incb_commutator c
   where pip_address = c.ip_address
     and c.b_deleted = 0;
   if ac_comm = 0 then
     raise_application_error(-20020,'IP íå ñóùåñòâóåò');
     end if;
     
   case B_MODE_WRITE 
     when 1 then 
       select v_community_read 
         into ac_comm
         from incb_commutator c
        where pip_address = c.ip_address
          and V_COMMUNITY = c.v_community_write
          and c.b_deleted = 0;
        if ac_comm = 1 then
          return 1;
        else 
          return 0;
          end if;
     when 0 then 
       select v_community_read 
         into ac_comm
         from incb_commutator c
        where pip_address = c.ip_address
          and V_COMMUNITY = c.v_community_read
          and c.b_deleted = 0;
        if ac_comm = 1 then
          return 1;
        else 
          return 0;
          end if;
          end case;
end check_access_commm;*/
--3.
/*К описанному выше справочнику реализовать функцию get_remote_id, принимающую на вход код коммутатора и 
возвращающую идентификатор коммутатора во внешней системе в hex формате, если признак использования remote_id в hex = 1, 
и просто REMOTE_ID в противном случае. Если признак использования remote_id в hex = 1, 
но идентификатор коммутатора в hex формате пуст, нужно выбрасывать исключение. 
Результат: функцию get_remote_id*/

/*       
create or replace function get_remote_id(pid_commutator in incb_commutator.id_commutator%type)  
 return varchar2
 is
 p_remote_id varchar2(255);
 p_remote_id_hex varchar2(255);
 ac_comm  number;
begin
  select -- ïðîâåðêà
   count(1)
    into ac_comm
    from incb_commutator c
   where pid_commutator = c.id_commutator
     and c.b_deleted = 0;
  if ac_comm = 0 then
    raise_application_error(-20020, 'ID êîììóòàòîðà íåò');
  end if;
  
  select --
      b_need_convert_hex,
      remote_id,
      remote_id_hex
    into
      ac_comm,
      p_remote_id,
      p_remote_id_hex
    from 
      incb_commutator c
   where pid_commutator = c.id_commutator
     and c.b_deleted = 0;
     
   case ac_comm
     when 0 then
       return p_remote_id;
     when 1 then 
       return p_remote_id_hex;
     else 
       raise_application_error(-20020, 'id íåïðàâèëüíî');
       end case;
     end get_remote_id;*/
      
      

        
     
                                               
             
                              
                               
