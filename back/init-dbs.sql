-- psql runs this both on an empty PostgreSQL volume and through db-init.
-- Keep existing databases and create only those introduced by new services.
SELECT pg_advisory_lock(8007000);

SELECT format('CREATE DATABASE %I', required.name)
FROM (VALUES
    ('coreDb'),
    ('authDb'),
    ('deliveryDb'),
    ('visitorDb'),
    ('reservationDb'),
    ('communicationDb'),
    ('complaintDb')
) AS required(name)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = required.name
)
\gexec

SELECT pg_advisory_unlock(8007000);
