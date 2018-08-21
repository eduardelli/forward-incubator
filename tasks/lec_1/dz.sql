--1.
select count(1) 
  from fw_process_log f  
 where f.n_status = 500;

--2.
select to_char(f.dt_timestamp, 'dd.mon.yyyy')  as times, f.id_log
  from fw_process_log f
 where f.n_status = 500
   and (f.dt_timestamp) = (select max((fw.dt_timestamp))
                           from fw_process_log fw 
                          where fw.n_status = f.n_status);
                       
--3.?  
select f.id_log
  from fw_process_log f
 where f.n_action = 12;

--4.?
select distinct count(1)
  from fw_process_log f
 where f.n_action = 12;

--5.
select  
 sum(to_number(substr(f.v_message, 141, 9)))
  from fw_process_log f
  where f.n_action = 11;
  
--6.
select count(1)
  from fw_process_log f
 where to_char(f.dt_timestamp, 'mm.yy') = '03.18'
   and f.n_action = 11;

--7.
select count(1)
  from fw_process_log f
 group by f.sid
 having count(1) > 1;

--8.
select f.os_username, f.dt_timestamp 
  from fw_process_log f
 where id_user = 11136
  and (dt_timestamp) = (select max((fw.dt_timestamp))
                           from fw_process_log fw 
                          where fw.id_user = f.id_user);

--9.
select to_char(f.dt_timestamp, 'mon'), count(1)
 from fw_process_log f
 group by to_char(f.dt_timestamp, 'mon');

--10.
select count(1), count(distinct f.v_message)
  from fw_process_log f
 where n_status = 500
   and f.id_process = 5 
   and f.dt_timestamp > to_date('22.02.2018', 'dd.mm.yyyy') 
   and f.dt_timestamp < to_date('02.03.2018', 'dd.mm.yyyy')
 --?group by v_message;

--11.
select min(f.n_sum)  
  from fw_transfers f
 where f.dt_incoming >= to_date('14.02.2017 10:00:00', 'dd.mm.yyyy hh:mi:ss') 
   and f.dt_incoming <= to_date('14.02.2017 12:00:00', 'dd.mm.yyyy hh:mi:ss')
   and f.id_contract_from != f.id_contract_to ;
 
--12.
select f.id_contract_to, f.dt_real, length(f.v_description) - 22
  from fw_transfers f
 where length(f.v_description) >= 22
 order by length(f.v_description) desc;

--13.
select to_char(f.dt_incoming, 'dd.mm.yyyy'), count(1)
  from fw_transfers f
 where f.id_contract_from = f.id_contract_to
 group by to_char(f.dt_incoming, 'dd.mm.yyyy');










