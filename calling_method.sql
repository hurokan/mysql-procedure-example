

SET @out_message = '0';
CALL addPIPProcessBeforeCVSBatchCron(572903, 0.450, @out_message);
SELECT @out_message;

