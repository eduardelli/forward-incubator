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
  /*  ����� ���-�� ��������� ��� �������        
  when no_data_faund then
    raise_application_error(-20020, '������������ �� ������'); */

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
                            '������������ �� ������');
  when others then
    raise_application_error(-20020,
                            '������������ ' || pACTION || ' ����������');
end saveSigners;
-----
--2
/*����������� ������� getDecoder, ����������� �� ���� id_equip_kits_inst. 
� ������, ���� � scd_equip_kits � ���������� ������ ���������� ��������, 
� �������� � scd_contracts ���������� ������� b_agency = 1, 
����� ������� scd_equip_kits.v_cas_id, ����� scd_equip_kits.v_ext_ident. 
���� ������������ �� �������, �� ������ ������ ������������� �� �������.
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
                            '������������ �� �������');
  when others then
    raise_application_error(-20020,
                            '������������ ������');
end getDecoder;
-------------------------
--3.
/*����������� ��������� getEquip, ����������� �� ���� pID_EQUIP_KITS_INST default null
� ��������(out) sys_refcursor. � ��������� � ������� ����������� OPEN...FOR 
����������� ���������� ������� ���������� �������: 
������������ �������, ����� �������, ������������� ���������, ������������ ���������, 
����� ��������(������������ ������� getDecoder). 
� ������, ���� pID_EQUIP_KITS_INST is null, ����� ��� ��������� ������, 
����� ������ ������� � ������ pID_EQUIP_KITS_INST. 
������� scd_equip_kits.id_equip_kits_inst ������������� ���� ������� �������.*/

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
--4. ��� �� �������� ��-�� ���������� � ������� �� id_rec
/*����������� � ������� ����� �� ������� ��������� checkstatus. 
��������� ������ ��� �������, � ������� scd_equip_kits.id_dealer_client �� null, 
�� ������ �������� �� �������(scd_equipment_status) ���������� ������ �������. 
����� ����, ������� � dbms_output.put_line ���������� � ����: 
"��� ������������ scd_equip_kits.id_equip_kits_inst ������ fw_clients.v_long_tittle 
� ���������� fw_contracts.v_ext_ident, 
�����������(���� scd_contracts.b_agency = 1)/�������������(���� scd_contracts.b_agency = 0) 
��������� ����� ��� ���������� ������ �������."*/

create or replace procedure checkstatus is -- ������ �� ����� �� ����
begin
  for i in (select -- ������� ������� � ���� �� ��� ������
             k.id_equip_kits_inst, c.v_long_title, t.v_ext_ident, r.b_agency
            
              from scd_equip_kits k
              join scd_equipment_status s
                on s.id_equipment_status = k.id_status
               and s.v_name != '�������'
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
       set v_name = '�������'
     where v_name != '�������';
  
    if i.b_agency = 1 then
      dbms_output.put_line('"��� ������������ ' || i.id_equip_kits_inst ||
                           ' ������ ' || i.v_long_title ||
                           ' � ���������� ' || i.v_ext_ident ||
                           ', ����������� ��������� ����� ��� ���������� ������ �������."');
    else
      dbms_output.put_line('"��� ������������ ' || i.id_equip_kits_inst ||
                           ' ������ ' || i.v_long_title ||
                           ' � ���������� ' || i.v_ext_ident ||
                           ', �� ����������� ��������� ����� ��� ���������� ������ �������."');
    end if;
  end loop;

  /*   exception 
  when others then
    raise_application_error(-20020, '������������� ������');  */
end;

 
      






      

 
      






      
               
     

  
                                        
                                 
