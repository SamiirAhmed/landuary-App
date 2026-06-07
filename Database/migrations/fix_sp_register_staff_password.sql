DROP PROCEDURE IF EXISTS sp_register_staff;

DELIMITER $$

CREATE PROCEDURE sp_register_staff(
    IN p_full_name VARCHAR(150),
    IN p_phone VARCHAR(30),
    IN p_sex ENUM('Male','Female'),
    IN p_email VARCHAR(150),
    IN p_has_login TINYINT,
    IN p_password VARCHAR(255),
    IN p_confirm_password VARCHAR(255),
    IN p_role ENUM('Staff','Delivery'),
    IN p_position VARCHAR(100),
    IN p_salary DECIMAL(10,2),
    IN p_hire_date DATE
)
BEGIN
    DECLARE v_person_id INT;
    DECLARE v_user_id INT DEFAULT NULL;

    -- NOTE: Password equality check is done in JavaScript (before hashing).
    -- bcrypt hashes are never equal even for the same input, so we skip it here.

    IF EXISTS (SELECT 1 FROM people WHERE phone = p_phone) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phone number already exists';
    END IF;

    IF EXISTS (SELECT 1 FROM people WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already exists';
    END IF;

    INSERT INTO people (full_name, phone, sex, email)
    VALUES (p_full_name, p_phone, p_sex, p_email);

    SET v_person_id = LAST_INSERT_ID();

    IF p_has_login = 1 THEN
        INSERT INTO users (person_id, password, role, status)
        VALUES (v_person_id, p_password, p_role, 'Active');

        SET v_user_id = LAST_INSERT_ID();
    END IF;

    INSERT INTO staff (person_id, user_id, position, salary, hire_date, status)
    VALUES (v_person_id, v_user_id, p_position, p_salary, p_hire_date, 'Active');
END$$

DELIMITER ;
