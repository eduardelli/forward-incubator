
--1 —оздать отчет по результатам за последний мес€ц в разрезе депортаментов
  select --
      d.v_name,
  --  cs.id_contract,
      sum(cs.f_sum) as summ,
      count(1) as cn
    from fw_contracts f
    join trans_external cs
      on cs.id_contract = f.id_contract_inst
    join fw_departments d
      on d.id_department = f.id_department
     and d.b_deleted = 0
   where cs.dt_event between to_date('01.03.18', 'dd.mm.yy') and to_date('31.03.18', 'dd.mm.yy')
     and f.v_status = 'A'
     and cs.v_status = 'A'
   group by d.v_name;

--2 Ќайти контракты, на которые в 2017 году было совершено более 3 платежей
select -- 
    count(1),
    c.id_contract_inst,
    c.v_status
  from fw_contracts c
  join trans_external t
    on t.id_contract = c.id_contract_inst
   and c.dt_start <= to_date('01.01.17', 'dd.mm.yy')
   and c.dt_stop >   to_date('01.01.18', 'dd.mm.yy')
   and t.v_status = 'A' 
   and c.v_status = 'A'
 where t.dt_event between to_date('01.01.17', 'dd.mm.yy') and to_date('31.12.17', 'dd.mm.yy')
 group by c.id_contract_inst, c.v_status 
having count(1) > 3;

--3 Ќайти такие департаменты, к которым не прив€зано ни одно зан€тие
/*select d.v_name, c.id_contract_inst
  from fw_departments d 
  left join fw_contracts c 
    on c.id_department = d.id_department
   and d.b_deleted = 0 
   and c.id_contract_inst is null;*/

select d.v_name
  from fw_departments d
 where not exists (select 1
                     from fw_contracts c 
                    where c.id_department = d.id_department)
   and d.b_deleted = 0;

--4 ¬ывести количество платежей на контрактах
select --
    count(1),
    max(t.dt_event) as m_date, 
    t.id_contract, 
    c.v_description
    
  from trans_external t
  left join ci_users c
    on (c.id_user = t.id_manager
   and c.v_status = 'A')
 where t.v_status = 'A' 
 group by t.id_contract, c.v_description;
 
--5 Ќайти те контракты, у которых мен€лась валюта
with contracts as (
select --
    distinct c.id_contract_inst, 
    nvl(c.id_currency, -1) id_currency, 
    c.v_ext_ident,  
    c.v_status, 
    u.v_description
  from fw_contracts c
  left join trans_external t
    on t.id_contract = c.id_contract_inst
  left join ci_users u
    on (u.id_user = t.id_manager
   and u.v_status = 'A')
 where c.dt_stop + 180 > current_timestamp
   and c.dt_start <= current_timestamp
   and c.v_status = 'A'
 )

select 
    c.id_contract_inst, 
    count(1) as cn,
    c.v_ext_ident as personal_account,
    c.v_status,
    c.v_description
  from contracts c 
 group by c.id_contract_inst, c.v_ext_ident, c.v_status, c.v_description
having count(1) > 1;

--6 ¬ывести отчет по сумме активных платежей на контракте за каждый год.
select --
    sum(t.f_sum) as summ, 
    t.id_contract, d.v_name, 
    trunc(t.dt_event, 'yyyy') as datt
    
  from trans_external t
  join fw_contracts c
    on c.id_contract_inst = t.id_contract
   and t.v_status = 'A'
   and c.v_status = 'A'
  join fw_departments d 
    on d.id_department = c.id_department
   and d.b_deleted = 0
 group by trunc(t.dt_event, 'yyyy'), t.id_contract, d.v_name
 order by datt;



