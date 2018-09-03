  --1.
  create or replace procedure saveSigners(pV_FIO      in scd_signers.v_fio%type,
                                          pID_MANAGER in scd_signers.id_manager%type,
                                          pACTION     in number) as
  p_user number;
begin

  select --
   cu.id_user
    into p_user
    from ci_users cu
   where cu.id_user = pID_MANAGER;
  /*  нужно как-то проверить это условие        
  when no_data_faund then
    raise_application_error(-20020, 'Пользователь не найден'); */

  case
    when pACTION = 1 then
      insert into scd_signers
        (V_FIO, ID_MANAGER)
      values
        (pV_FIO, pID_MANAGER);
    when pACTION = 2 then
      update scd_signers set V_FIO = pV_FIO where ID_MANAGER = pID_MANAGER;
    when pACTION = 3 then
      delete from scd_signers where ID_MANAGER = pID_MANAGER;
  end case;
exception
  when no_data_found then
    raise_application_error(-20020,
                            'Пользователь не найден');
  when others then
    raise_application_error(-20020,
                            'Пользователь ' || pACTION || ' существует');
end saveSigners;
-----
--2
/*Реализовать функцию getDecoder, принимающий на вход id_equip_kits_inst. 
В случае, если в scd_equip_kits у актуальной записи проставлен контракт, 
у которого в scd_contracts проставлен признак b_agency = 1, 
тогда вернуть scd_equip_kits.v_cas_id, иначе scd_equip_kits.v_ext_ident. 
Если оборудование не найдено, то выдать ошибку «Оборудование не найдено».
*/
create or replace function getDecoder(d_kits_inst in scd_equip_kits.id_equip_kits_inst%type)
  return varchar2 is
  dv_cas_id    varchar2(255);
  dv_ext_ident varchar2(255);
  db_agency    number;
  d_vivod      varchar2(255);
begin
  begin
    select --
     k.v_cas_id, k.v_ext_ident, c.b_agency
      into dv_cas_id, dv_ext_ident, db_agency
      from scd_equip_kits k
      join scd_contracts c
        on c.id_contract_inst = k.id_contract_inst
     where k.id_contract_inst = d_kits_inst
       and k.dt_stop > current_timestamp
       and k.dt_start <= current_timestamp;
  end;

  if (db_agency = 1) then
    d_vivod := dv_cas_id;
  else
    d_vivod := dv_ext_ident;
  end if;
  return d_vivod;
exception
  when no_data_found then
    raise_application_error(-20020,
                            'Оборудование не найдено');
  when others then
    raise_application_error(-20020,
                            'Неизведанная ошибка');
end getDecoder;
-------------------------
--3.
/*Реализовать процедуру getEquip, принимающую на вход pID_EQUIP_KITS_INST default null
и отдающую(out) sys_refcursor. В процедуре с помощью конструкции OPEN...FOR 
реализовать наполнение курсора следующими данными: 
Наименование клиента, логин клиента, идентификатор контракта, наименование комплекта, 
номер декодера(использовать функцию getDecoder). 
В случае, если pID_EQUIP_KITS_INST is null, тогда все имеющиеся данные, 
иначе только строчку с данным pID_EQUIP_KITS_INST. 
Каждому scd_equip_kits.id_equip_kits_inst соответствует одна строчка курсора.*/

create or replace procedure getEquip(pID_EQUIP_KITS_INST in scd_equip_kits.id_equip_kits_inst%type,
                                     dwr                 out sys_refcursor) is
begin

  if pID_EQUIP_KITS_INST is null then
    open dwr for
      select --
       cl.v_long_title,
       cl.id_rec,
       c.id_contract_inst,
       k.v_name,
       getDecoder(k.id_equip_kits_type)
        from fw_contracts c
        join fw_clients cl
          on cl.id_client_inst = c.id_client_inst
         and cl.dt_stop > current_timestamp
         and cl.dt_start <= current_timestamp
        join scd_equip_kits e
          on e.id_contract_inst = c.id_contract_inst
         and e.dt_stop > current_timestamp
         and e.dt_start <= current_timestamp
        join scd_equipment_kits_type k
          on k.id_equip_kits_type = e.id_equip_kits_type
         and k.dt_stop > current_timestamp
         and k.dt_start <= current_timestamp
       where c.v_status = 'A'
         and c.dt_stop > current_timestamp
         and c.dt_start <= current_timestamp;
  
  else
    open dwr for
      select --
       cl.v_long_title,
       cl.id_rec,
       c.id_contract_inst,
       k.v_name,
       getDecoder(k.id_equip_kits_type)
        from fw_contracts c
        join fw_clients cl
          on cl.id_client_inst = c.id_client_inst
         and cl.dt_stop > current_timestamp
         and cl.dt_start <= current_timestamp
        join scd_equip_kits e
          on e.id_contract_inst = c.id_contract_inst
         and e.dt_stop > current_timestamp
         and e.dt_start <= current_timestamp
        join scd_equipment_kits_type k
          on k.id_equip_kits_type = e.id_equip_kits_type
         and k.dt_stop > current_timestamp
         and k.dt_start <= current_timestamp
       where c.v_status = 'A'
         and c.dt_stop > current_timestamp
         and c.dt_start <= current_timestamp
         and k.id_equip_kits_type = '||pID_EQUIP_KITS_INST||';
  end if;

end getEquip;
------------------------------
--4. тут не работает из-за соединения в джоинах по id_rec
/*Реализовать с помощью цикла по курсору процедуру checkstatus. 
Процедура должна для записей, у которых scd_equip_kits.id_dealer_client не null, 
но статус отличный от Продано(scd_equipment_status) проставить статус Продано. 
Кроме того, вывести в dbms_output.put_line информацию в виде: 
"Для оборудования scd_equip_kits.id_equip_kits_inst дилера fw_clients.v_long_tittle 
с контрактом fw_contracts.v_ext_ident, 
являющегося(если scd_contracts.b_agency = 1)/неявляющегося(если scd_contracts.b_agency = 0) 
агентской сетью был проставлен статус Продано."*/

create or replace procedure checkstatus is -- ничего не нужно на вход
begin
  for i in (select -- находим условия и идем по ним циклом
             k.id_equip_kits_inst, c.v_long_title, t.v_ext_ident, r.b_agency
            
              from scd_equip_kits k
              join scd_equipment_status s
                on s.id_equipment_status = k.id_status
               and s.v_name != 'Продано'
               and s.b_deleted = 0
              join fw_contracts t
                on t.id_contract_inst = k.id_contract_inst
               and t.dt_stop > current_timestamp
               and t.dt_start <= current_timestamp
               and t.v_status = 'A'
              join fw_clients c
                on c.id_client_inst = t.id_client_inst
               and c.dt_stop > current_timestamp
               and c.dt_start <= current_timestamp
              join scd_contracts r
                on r.id_contract_inst = k.id_contract_inst
             where k.dt_stop > current_timestamp
               and k.dt_start <= current_timestamp
               and k.id_dealer_client is not null) loop
    update scd_equipment_status st
       set v_name = 'Продано'
     where v_name != 'Продано';
  
    if i.b_agency = 1 then
      dbms_output.put_line('"Для оборудования ' || i.id_equip_kits_inst ||
                           ' дилера ' || i.v_long_title ||
                           ' с контрактом ' || i.v_ext_ident ||
                           ', являющегося агентской сетью был проставлен статус Продано."');
    else
      dbms_output.put_line('"Для оборудования ' || i.id_equip_kits_inst ||
                           ' дилера ' || i.v_long_title ||
                           ' с контрактом ' || i.v_ext_ident ||
                           ', не являющегося агентской сетью был проставлен статус Продано."');
    end if;
  end loop;

  /*   exception 
  when others then
    raise_application_error(-20020, 'Неизведданная ошибка');  */
end;

 
      






      

 
      






      
               
     

  
                                        
                                 
