UPDATE drug_prescriptions
SET therapy_id = NULL;

UPDATE drug_prescriptions
SET therapy_id = (SELECT therapy_id
                    FROM @@@ramses_tc_table
                    WHERE id = drug_prescriptions.id )
WHERE EXISTS(SELECT therapy_id
             FROM @@@ramses_tc_table
             WHERE id = drug_prescriptions.id );
UPDATE drug_prescriptions
SET therapy_id = prescription_id
WHERE therapy_id IS NULL
  AND prescription_status NOT IN ('cancelled', 'draft', 'entered-in-error');

UPDATE drug_prescriptions
SET therapy_rank = (SELECT therapy_rank
                    FROM @@@ramses_tc_table
                    WHERE id = drug_prescriptions.id )
WHERE EXISTS(SELECT therapy_rank
             FROM @@@ramses_tc_table
             WHERE id = drug_prescriptions.id );

UPDATE drug_prescriptions
SET therapy_rank = 1
WHERE NOT EXISTS(SELECT therapy_rank
                 FROM @@@ramses_tc_table 
                 WHERE id = drug_prescriptions.id );

