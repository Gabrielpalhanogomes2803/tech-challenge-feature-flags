CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    
    -- key_hash armazena o hash SHA-256 da chave, que tem 64 caracteres hexadecimais
    key_hash VARCHAR(64) NOT NULL UNIQUE, 
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- Chave conhecida apenas para comunicação entre serviços no ambiente local.
-- Produção usa um Secret externo e nunca esta credencial fixa.
INSERT INTO api_keys (name, key_hash, is_active)
VALUES (
    'evaluation-service-local',
    '6824b9492a256553c7af7c10d866a430291da6745f7335b7eb5abcaee23bdecb',
    true
)
ON CONFLICT (key_hash) DO NOTHING;
