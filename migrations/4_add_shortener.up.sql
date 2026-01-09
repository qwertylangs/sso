INSERT INTO apps (id, name, secret)
VALUES (2, 'shortener', 'shortener-secret')
ON CONFLICT DO NOTHING;