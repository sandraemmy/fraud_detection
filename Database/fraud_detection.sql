DROP DATABASE IF EXISTS fraud_detection;
-- CREATE DATABASE IF NOT EXISTS fraud_detection;
USE fraud_detection;

-- Policies Table
CREATE TABLE policies (
    policy_number INT PRIMARY KEY,  
    policy_deductable INT,
    policy_annual_premium FLOAT
);

-- Customers Table
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    age INT,
    insured_sex VARCHAR(10),
    insured_education_level VARCHAR(50),
    insured_relationship VARCHAR(50),
    capital_loss INT,
    capital_gains INT,
    policy_number INT,  -- Changed from BIGINT to INT
    FOREIGN KEY (policy_number) REFERENCES policies(policy_number)
);

-- Incidents Table
CREATE TABLE incidents (
    incident_id VARCHAR(10) PRIMARY KEY,
    incident_type VARCHAR(24),
    collision_type VARCHAR(15),
    incident_severity VARCHAR(14),
    authorities_contacted VARCHAR(9),
    incident_state VARCHAR(2),
    number_of_vehicles_involved INT,
    policy_number INT,  -- Ensured it matches policies table
    FOREIGN KEY (policy_number) REFERENCES policies(policy_number)
);

-- Claims Table
CREATE TABLE claim (
    claim_id VARCHAR(8) PRIMARY KEY,
    property_damage VARCHAR(50),
    bodily_injuries INT,
    witnesses INT,
    police_report_available VARCHAR(50),
    injury_claim DECIMAL(10,2),
    property_claim DECIMAL(10,2),
    vehicle_claim DECIMAL(10,2),
    fraud_reported VARCHAR(10),
    policy_number INT,  -- Ensured it matches policies table
    FOREIGN KEY (policy_number) REFERENCES policies(policy_number)
);

USE fraud_detection;

-- Compute the average total claim amount
SELECT 
    AVG(injury_claim + property_claim + vehicle_claim) AS avg_claim_amount
FROM claim;



SELECT 
    claim_id, 
    policy_number, 
    (injury_claim + property_claim + vehicle_claim) AS total_claim_amount,
    CASE 
        WHEN (injury_claim + property_claim + vehicle_claim) > 
             (SELECT AVG(injury_claim + property_claim + vehicle_claim) * 1.5 FROM claim)
        THEN 'High'
        ELSE 'Normal'
    END AS claim_flag
FROM claim
ORDER BY total_claim_amount DESC;

SELECT 
    fraud_reported, 
    COUNT(*) AS claim_count,
    AVG(injury_claim + property_claim + vehicle_claim) AS avg_claim_amount,
    MAX(injury_claim + property_claim + vehicle_claim) AS max_claim_amount,
    MIN(injury_claim + property_claim + vehicle_claim) AS min_claim_amount
FROM claim
GROUP BY fraud_reported;

-- Claim Frequency for Each Customer
SELECT 
    c.customer_id, 
    COUNT(cl.claim_id) AS total_claims
FROM customers c
JOIN policies p ON c.policy_number = p.policy_number
JOIN claim cl ON p.policy_number = cl.policy_number
GROUP BY c.customer_id;

-- Premium-to-Claim Ratio
SELECT 
    cl.policy_number, 
    p.policy_annual_premium, 
    (cl.injury_claim + cl.property_claim + cl.vehicle_claim) AS total_claim_amount,
    (cl.injury_claim + cl.property_claim + cl.vehicle_claim) / NULLIF(p.policy_annual_premium, 0) AS premium_to_claim_ratio
FROM claim cl
JOIN policies p ON cl.policy_number = p.policy_number;

-- State-wise Fraud Rate
SELECT 
    i.incident_state, 
    SUM(CASE WHEN cl.fraud_reported = 'Y' THEN 1 ELSE 0 END) AS fraud_cases,
    COUNT(*) AS total_claims,
    (SUM(CASE WHEN cl.fraud_reported = 'Y' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS fraud_rate
FROM claim cl
JOIN incidents i ON cl.policy_number = i.policy_number
GROUP BY i.incident_state
ORDER BY fraud_rate DESC;


-- To summarize the data using mean, max, min, and standard deviation (std), you can use the following SQL query:

USE fraud_detection;

-- Summary Statistics for Claims
SELECT 
    COUNT(*) AS total_claims,
    AVG(injury_claim + property_claim + vehicle_claim) AS mean_total_claim,
    MAX(injury_claim + property_claim + vehicle_claim) AS max_total_claim,
    MIN(injury_claim + property_claim + vehicle_claim) AS min_total_claim,
    STD(injury_claim + property_claim + vehicle_claim) AS std_total_claim
FROM claim;

-- Summary Statistics for Policy Premiums
SELECT 
    COUNT(*) AS total_policies,
    AVG(policy_annual_premium) AS mean_annual_premium,
    MAX(policy_annual_premium) AS max_annual_premium,
    MIN(policy_annual_premium) AS min_annual_premium,
    STD(policy_annual_premium) AS std_annual_premium
FROM policies;

-- Summary Statistics for Bodily Injuries in Claims
SELECT 
    COUNT(*) AS total_bodily_injury_claims,
    AVG(bodily_injuries) AS mean_bodily_injuries,
    MAX(bodily_injuries) AS max_bodily_injuries,
    MIN(bodily_injuries) AS min_bodily_injuries,
    STD(bodily_injuries) AS std_bodily_injuries
FROM claim;

-- Summary Statistics for Number of Vehicles Involved in Incidents
SELECT 
    COUNT(*) AS total_incidents,
    AVG(number_of_vehicles_involved) AS mean_vehicles_involved,
    MAX(number_of_vehicles_involved) AS max_vehicles_involved,
    MIN(number_of_vehicles_involved) AS min_vehicles_involved,
    STD(number_of_vehicles_involved) AS std_vehicles_involved
FROM incidents;
