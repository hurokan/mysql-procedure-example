DELIMITER $$
CREATE FUNCTION `getNewUUID`(p_uuid varchar(100)) 
RETURNS varchar(100) 
    DETERMINISTIC
BEGIN
 declare v_new_uuid varchar(100);
 
	set v_new_uuid:= (select CONCAT(LEFT(p_uuid, LENGTH(p_uuid) - 6),
					'',
					LEFT(p_uuid, 2),
					'',
					LEFT(UUID(), 4)));
 
RETURN v_new_uuid;
END$$

DELIMITER ;