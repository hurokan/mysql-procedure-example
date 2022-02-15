DELIMITER $$
create PROCEDURE addPIPProcessBeforeCVSBatchCron(
    in p_cbs_id int,
    in p_pip_percentage decimal(10,3),
	OUT out_message VARCHAR(500)
)
BEGIN  
    declare v_cbs_uuout_messageid varchar(100);
    declare v_invoice_id int;
    declare v_loan_id int;
    declare v_pr_id int;
    declare v_credit_type int;
    declare v_credit_amount float;
    declare v_cal_credit_amount decimal(10,2);
    declare v_update_pamnt_amt float;
    
    declare v_cbs_uuid varchar(100);
    declare v_credit_ac_number varchar(50);
    declare v_credit_ac_id varchar(50);
    declare v_od_account varchar(50);
    declare v_invoice_number varchar(100);
	declare v_percentage varchar(50);
    set v_credit_ac_number:=1000173510063;
    set v_credit_ac_id:=520;
    set v_credit_type:=4;

    SELECT 
    pr_id,
    invoice_id,
	credit_amount,
    (credit_amount * p_pip_percentage) / 100,
    debit_ac,
    GETNEWUUID(uuid)
  INTO v_pr_id , 
      v_invoice_id ,
      v_credit_amount,
	  v_cal_credit_amount ,
      v_od_account ,
      v_cbs_uuid FROM
    cbs_instructions
WHERE
    id = p_cbs_id
ORDER BY id ASC
LIMIT 1;

  set v_invoice_number:=( select invoice_number from invoices where id=v_invoice_id);
    
   set v_loan_id:=( select  id
					from discountings
					WHERE invoice_id = v_invoice_id);
                    

 begin   
   INSERT INTO pr_credit 
   (pr_id,
   pr_uuid,
   credit_to,
   credit_amount,
   credit_type,
   currency,
   od_id,
   remark,
   credit_type_name)
   SELECT 
   v_pr_id,
   pr_uuid,
   v_credit_ac_number,
   v_cal_credit_amount,
   v_credit_type,
   currency,
   od_id,
   remark,
   credit_type_name 
   FROM pr_credit
   where pr_id=v_pr_id;
   
end;
   

   begin
    INSERT INTO idiscounting_charges
				(loan_id,
				name,
				value,
				type,
				description,
				bank_id,
				loan_amount,
				total_per,
				total_value,
				fi_type,
				created_at,
				updated_at,
				tax_details,
				pi_id)
				select 
				loan_id,
				'PIP',
				p_pip_percentage,
				'percentage',
				'PIP',
				bank_id,
				loan_amount,
				v_cal_credit_amount,
				total_value,
				fi_type,
				created_at,
				updated_at,
				tax_details,
				pi_id
				FROM idiscounting_charges
				where loan_id= v_loan_id
                order by id asc
                limit 1; 
     end;        
         
            begin    
               INSERT INTO cbs_instructions
				(
				uuid,
				pr_id,
				pi_id,
				debit_ac,
				debit_ac_id,
				credit_ac,
				credit_ac_id,
				invoice_id,
				credit_amount, 
				created_at,
				updated_at,
				transaction_date,
				cbs_transaction_id,
				status,
				currency,
				pr_uuid,
				bank_id,
				pay_date,
				type,
				cbs_reference_id,
				loan_repayment_pi, 
				transaction_type, 
				suspense_status, 
				updated_by, 
				mail_type,
				cbs_remark, 
				created_by,
				cron_flag,
				cbs_type, 
				is_failure_mail_sent,
				cbs_narrations,
				credit_type, 
				suspense_tran_remark
                )
				select 
				v_cbs_uuid,
				v_pr_id,
				pi_id,
				v_od_account,
				debit_ac_id,
				v_credit_ac_number,
				v_credit_ac_id,
				invoice_id,
				v_cal_credit_amount, 
				created_at,
				updated_at,
				CURDATE(),
				null,
				0,
				currency,
				pr_uuid,
				bank_id,
				pay_date,
				type,
				cbs_reference_id,
				loan_repayment_pi, 
				transaction_type, 
				suspense_status, 
				updated_by, 
				mail_type,
				'', 
				created_by,
				cron_flag,
				cbs_type, 
				is_failure_mail_sent,
				CONCAT("DF charge ",v_invoice_number),
				4,
                suspense_tran_remark
				from cbs_instructions
				where pr_id=v_pr_id
                order by id asc
                limit 1;
            end;
            
            begin
                insert into od_transactions (
                uuid,
                od_account_id,
                loan_id,
                payment_request_id,
                date,
                debit_entry,
                credit_entry,
                balance,
                interest_balance,
                priority,
                interest_indicator,
                is_bank_reco_tran,
                settlement_status,
                settlement_date_time,
                settlement_pr_id,
                remark,
                created_at, 
                updated_at, 
                last_cron_accrual_date, 
                total_penal_interest,
                total_interest, 
                last_cron_date,
                particulars, 
                credit_type_id, 
                invoice_number, 
                currency,
                tran_order,
                penal_interest,
                is_overdue,
                overdue_date,
                credit_balance)
               select 
                v_cbs_uuid,
                od_account_id,
                null,
                payment_request_id,
                date,
                v_cal_credit_amount,
                credit_entry,
                v_cal_credit_amount,
                null,
                0,
                0,
                is_bank_reco_tran,
                settlement_status,
                settlement_date_time,
                settlement_pr_id,
                remark,
                created_at, 
                updated_at, 
                null, 
                null,
                null, 
                last_cron_date,
               CONCAT('Charge and TAX against invoice ',v_invoice_number), 
                4, 
                invoice_number, 
                currency,
                0,
                null,
                0,
                overdue_date,
                credit_balance
               from od_transactions
               where payment_request_id= v_pr_id
               and loan_id =v_invoice_id
               and debit_entry=v_credit_amount
               order by id asc
               limit 1;
          end;
         
			begin
             set v_update_pamnt_amt:=( select (amount + v_cal_credit_amount)
               from payment_requests
               where id=v_pr_id);
               
               update payment_requests
               set amount= v_update_pamnt_amt
               where id= v_pr_id; 
           end;  
END$$

DELIMITER ;