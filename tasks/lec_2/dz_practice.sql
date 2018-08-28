
---- 1 поконтрактно вывести АП
select --
  f.v_ext_ident as contract_num,
  sum(n_cost_period) as summ,
  d.v_name as branch
  
  from fw_contracts f
  join fw_services_cost fs
    on fs.dt_stop > current_timestamp
   and fs.dt_start <= current_timestamp
   and fs.id_contract_inst = f.id_contract_inst
  join fw_departments d
    on d.id_department = f.id_department
   and d.b_deleted = 0
 where f.v_status = 'A'
   and current_timestamp >= f.dt_start
   and current_timestamp < f.dt_stop
 group by f.v_ext_ident, d.v_name;

-- 2 вывести среднюю АП пофилиально
with services_cost as ( -- 
  select sum(n_cost_period) as summ, fs.id_contract_inst
    from fw_services_cost fs
   where fs.dt_stop > current_timestamp
     and fs.dt_start <= current_timestamp
   group by fs.id_contract_inst
)
 
select --
    avg(ser.summ) as val, 
    d.v_name
    
  from fw_contracts f
  join services_cost ser
    on ser.id_contract_inst = f.id_contract_inst
  join fw_departments d
    on d.id_department = f.id_department
   and d.b_deleted = 0
 where f.v_status = 'A'
   and current_timestamp >= f.dt_start
   and current_timestamp < f.dt_stop
   group by  d.v_name; 
   
--
select --
    avg(ser.summ), 
    d.v_name
  from fw_contracts f
  left join (select --
                 sum(n_cost_period) as summ, 
                 fs.id_contract_inst
                 
               from fw_services_cost fs
              where fs.dt_stop > current_timestamp
                and fs.dt_start <= current_timestamp
              group by fs.id_contract_inst) ser
    on ser.id_contract_inst = f.id_contract_inst
  join fw_departments d
    on d.id_department = f.id_department
   and d.b_deleted = 0  
 where f.v_status = 'A'
   and current_timestamp >= f.dt_start
   and current_timestamp < f.dt_stop
 group by d.v_name;
 
-- 3 найти всех абонентов, чья АП больше средней АП(пофилиально)
with services_cost as ( -- суммы по филиалам и контрактам 
  select --
    d.id_department,
    cs.id_contract_inst,
    sum(n_cost_period) as summ
    from fw_contracts f
    join fw_services_cost cs
      on cs.id_contract_inst = f.id_contract_inst
  join fw_departments d
    on d.id_department = f.id_department
   and d.b_deleted = 0
   where cs.dt_start <= current_timestamp
     and cs.dt_stop > current_timestamp
     and f.v_status = 'A'
     and f.dt_start <= current_timestamp
     and f.dt_stop > current_timestamp 
   group by d.id_department, cs.id_contract_inst
),

service_cost_avg as ( -- средняя АП по филиалам 
  select --
    sc.id_department,
    avg(sc.summ) as val
    from services_cost sc
   group by sc.id_department
)

select --
  c.id_contract_inst as contract_num, --номер договора 
  c.summ --величина АП
  
  from services_cost c
 where c.summ > (select val
                     from service_cost_avg ca
                    where ca.id_department = c.id_department);
                    
                    
--4 найти услуги всех абонентов чья АП больше средней АП(пофилиально)
with service as ( -- суммы по филиалам и услугам
  select --
    d.id_department as dep_id, 
    d.v_name as dep_name, 
    s.id_service as serv_id, 
    s.v_name as ser_name,
    sum(n_cost_period) as summ
    
    from fw_contracts f
    join fw_services_cost cs
      on cs.id_contract_inst = f.id_contract_inst
    join fw_departments d
      on d.id_department = f.id_department
     and d.b_deleted = 0 
    join fw_services ss
      on ss.id_service_inst = cs.id_service_inst
     and ss.b_deleted = 0
     and ss.v_status = 'A'
    join fw_service s
      on s.id_service = ss.id_service
     and s.b_deleted = 0
   where cs.dt_start <= current_timestamp
     and cs.dt_stop > current_timestamp
     and f.v_status = 'A'
     and f.dt_start <= current_timestamp
     and f.dt_stop > current_timestamp 
     --and d.id_department = 2022
   group by d.id_department, d.v_name, s.id_service, s.v_name
),

service_avg as ( -- средняя АП по филиалам 
  select --
      s.dep_id,
     avg(s.summ) as val
    from service s
   group by s.dep_id
)

select --
  ser_name, -- название услуги
  dep_id,
  dep_name, --название филиала 
  c.summ --величина сумм АП за услугу внутри филиала
  
  from service c
 where c.summ > (select val
                   from service_avg ca
                   where ca.dep_id = c.dep_id);
                    
                    
--5 найти всех абонентов, у которых величина скидки на услугах менялась два и более раза в течение ноября 2017
select --
  sc.id_contract_inst as contract_num,
  s.id_service, --без типа услуги непонятно по какой услуге менялась величина скидки
  s.v_name, 
  count(1) cn
   
  from fw_services_cost sc
  join fw_services ss
    on ss.id_service_inst = sc.id_service_inst
   and ss.b_deleted = 0 
  join fw_service s
    on s.id_service = ss.id_service
   and s.b_deleted = 0  
 where sc.dt_start between  to_date('01.11.17', 'dd.mm.yy') and to_date('30.11.17', 'dd.mm.yy') 
    or sc.dt_stop  between  to_date('01.11.17', 'dd.mm.yy') and to_date('30.11.17', 'dd.mm.yy')
 group by s.id_service, s.v_name, sc.id_contract_inst
having count(1) > 1;
 
  
--6 вывести самый прибыльный ТП с точки зрения суммарной АП
with tariff_plan as ( --
select --
  d.v_name as branch,
  t.v_name as t_name,
  sum(n_cost_period) as summ
  
  from fw_contracts f
  join fw_services_cost fs
    on fs.dt_stop > current_timestamp
   and fs.dt_start <= current_timestamp
   and fs.id_contract_inst = f.id_contract_inst
  join fw_services ss  
    on ss.dt_stop > current_timestamp
   and ss.dt_start <= current_timestamp
   and ss.b_deleted = 0
   and ss.id_service_inst = fs.id_service_inst
  join fw_service s
    on s.id_service = ss.id_service
   and s.b_deleted = 0
  join fw_tariff_plan t
    on t.id_tariff_plan = ss.id_tariff_plan  
   and t.dt_stop > current_timestamp
   and t.dt_start <= current_timestamp
   and t.b_active = 1
   and t.b_deleted = 0
  join fw_departments d
    on d.id_department = f.id_department
   and d.b_deleted = 0
 where f.v_status = 'A'
   and current_timestamp >= f.dt_start
   and current_timestamp < f.dt_stop
 group by d.v_name, t.v_name
 ),

tariff_plan_rn as (
select --
  tp.branch, tp.t_name, tp.summ, row_number() over( order by tp.summ desc) rn
  from tariff_plan tp
 )


select --
  r.branch, 
  r.t_name, 
  r.summ
  from tariff_plan_rn r
 where r.rn = 1;



