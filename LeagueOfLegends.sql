-- Tablas
-- Tabla de servidores del juego
CREATE TABLE servers (
    server_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    region VARCHAR(50) NOT NULL,
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de cuentas de usuario
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    server_id INT NOT NULL REFERENCES servers(server_id),
    rp_balance NUMERIC NOT NULL DEFAULT 0,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de estadísticas agregadas por cuenta
CREATE TABLE account_stats (
    account_id INT PRIMARY KEY REFERENCES accounts(account_id),
    total_matches INT NOT NULL DEFAULT 0,
    wins INT NOT NULL DEFAULT 0,
    losses INT NOT NULL DEFAULT 0,
    total_kills INT NOT NULL DEFAULT 0,
    total_assists INT NOT NULL DEFAULT 0
);

-- Tabla de campeones
CREATE TABLE champions (
    champion_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    role VARCHAR(20),
    release_date DATE,
    price NUMERIC NOT NULL
);

-- Tabla de skins de campeones
CREATE TABLE skins (
    skin_id SERIAL PRIMARY KEY,
    champion_id INT NOT NULL REFERENCES champions(champion_id),
    name VARCHAR(50) NOT NULL,
    price NUMERIC NOT NULL,
    release_date DATE,
    UNIQUE (champion_id, name)
);

-- Tabla de partidas, particionada por rango de fecha
CREATE TABLE matches (
    match_id BIGINT PRIMARY KEY,
    home_team_id INT,
    away_team_id INT,
    start_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    competition_id INT,
    season TEXT
);

-- Tabla de hechizos del invocador
CREATE TABLE summoners (
    summoner_id BIGINT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    region TEXT NOT NULL,
    level INT DEFAULT 1,
    email TEXT UNIQUE NOT NULL,
    registration_date DATE DEFAULT CURRENT_DATE
);

-- Tabla de participantes en cada partida, con estadísticas individuales
CREATE TABLE match_participants (
    participant_id BIGSERIAL PRIMARY KEY,
    match_id BIGINT NOT NULL,
    summoner_id BIGINT NOT NULL,
    team TEXT CHECK (team IN ('blue', 'red')),
    role TEXT,
    champion_id INT,
    FOREIGN KEY (match_id) REFERENCES matches(match_id),
    FOREIGN KEY (summoner_id) REFERENCES summoners(summoner_id),
    FOREIGN KEY (champion_id) REFERENCES champions(champion_id)
);

-- Tabla de historial de compras de RP
CREATE TABLE rp_purchases (
    purchase_id BIGINT,
    account_id BIGINT,
    amount INT,
    purchase_date DATE NOT NULL,
    PRIMARY KEY (purchase_id, purchase_date)
) PARTITION BY RANGE (purchase_date);

-- Particiones de rp_purchases por año
CREATE TABLE rp_purchases_2022 PARTITION OF rp_purchases
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE rp_purchases_2023 PARTITION OF rp_purchases
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE rp_purchases_default PARTITION OF rp_purchases DEFAULT;

-- Tabla de compras de campeones por cuenta
CREATE TABLE champion_purchases (
    purchase_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES accounts(account_id),
    champion_id INT NOT NULL REFERENCES champions(champion_id),
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_id, champion_id)
);

-- Tabla de compras de skins por cuenta
CREATE TABLE skin_purchases (
    purchase_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES accounts(account_id),
    skin_id INT NOT NULL REFERENCES skins(skin_id),
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_id, skin_id)
);

-- Tabla de lista de amigos entre cuentas
CREATE TABLE friend_list (
    request_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES accounts(account_id),
    friend_id INT NOT NULL REFERENCES accounts(account_id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_id, friend_id)
);

-- Tabla de historial de inicio de sesión de cuentas
CREATE TABLE account_login_history (
    login_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES accounts(account_id),
    login_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET
);

-- Tabla de rangos por temporada para cada cuenta
CREATE TABLE account_rank (
    rank_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES accounts(account_id),
    season VARCHAR(20) NOT NULL,
    rank_tier VARCHAR(30),
    rank_points INT NOT NULL DEFAULT 0,
    UNIQUE (account_id, season)
);

-- Indices
CREATE INDEX idx_champions_role ON champions(role);
CREATE INDEX idx_skins_champion ON skins(champion_id);
CREATE INDEX idx_matches_start_time ON matches(start_time);
CREATE INDEX idx_matches_home_team ON matches(home_team_id);
CREATE INDEX idx_matches_away_team ON matches(away_team_id);
CREATE INDEX idx_summoners_region ON summoners(region);
CREATE INDEX idx_summoners_level ON summoners(level);
CREATE INDEX idx_match_participants_match ON match_participants(match_id);
CREATE INDEX idx_match_participants_summoner ON match_participants(summoner_id);
CREATE INDEX idx_match_participants_champion ON match_participants(champion_id);
CREATE INDEX idx_rp_purchases_account ON rp_purchases(account_id, purchase_date);
CREATE INDEX idx_champion_purchases_account ON champion_purchases(account_id);
CREATE INDEX idx_champion_purchases_champion ON champion_purchases(champion_id);
CREATE INDEX idx_skin_purchases_account ON skin_purchases(account_id);
CREATE INDEX idx_skin_purchases_skin ON skin_purchases(skin_id);
CREATE INDEX idx_friend_list_account_status ON friend_list(account_id, status);
CREATE INDEX idx_friend_list_friend ON friend_list(friend_id);
CREATE INDEX idx_login_history_account ON account_login_history(account_id, login_time);
CREATE INDEX idx_account_rank_season_points ON account_rank(season, rank_points DESC);



-- Funciones
-- Win rate de un jugador (%) [0-100]
CREATE OR REPLACE FUNCTION get_win_rate(p_account_id INT)
RETURNS NUMERIC LANGUAGE SQL IMMUTABLE AS $$
    SELECT CASE WHEN total_matches = 0 THEN 0
                ELSE (wins::NUMERIC / total_matches) * 100
           END
      FROM account_stats
     WHERE account_id = p_account_id;
$$;

SELECT get_win_rate(1);

-- Veces jugadas de un campeón por un jugador
CREATE OR REPLACE FUNCTION get_champion_play_count(p_account_id INT, p_champion_id INT)
RETURNS INT LANGUAGE SQL IMMUTABLE AS $$
    SELECT COUNT(*)
      FROM match_participants
     WHERE participant_id = p_account_id
       AND champion_id = p_champion_id;
$$;

SELECT get_champion_play_count(1, 101);

-- Total de RP gastados en campeones y skins por un jugador
CREATE OR REPLACE FUNCTION get_total_rp_spent(p_account_id INT)
RETURNS NUMERIC LANGUAGE SQL IMMUTABLE AS $$
    SELECT
      COALESCE((SELECT SUM(c.price) 
                  FROM champion_purchases cp
                  JOIN champions c ON cp.champion_id = c.champion_id
                 WHERE cp.account_id = p_account_id), 0)
      +
      COALESCE((SELECT SUM(s.price) 
                  FROM skin_purchases sp
                  JOIN skins s ON sp.skin_id = s.skin_id
                 WHERE sp.account_id = p_account_id), 0);
$$;

SELECT get_total_rp_spent(1);

-- Enmascarar tarjeta de crédito (sólo últimos 4 dígitos visibles)
CREATE OR REPLACE FUNCTION mask_credit_card(cc TEXT)
RETURNS TEXT LANGUAGE SQL IMMUTABLE AS $$
    SELECT overlay(cc placing '****-****-****-' from 1 for length(cc)-4);
$$;

SELECT mask_credit_card('1234-5678-9101-1121');

-- Resumen de cuenta (username, RP balance, wins, losses, etc.)

DROP FUNCTION get_account_summary(integer)

CREATE OR REPLACE FUNCTION get_account_summary(p_account_id INT)
RETURNS TABLE(
    account_id INT,
    username TEXT,
    rp_balance NUMERIC,
    total_matches INT,
    wins INT,
    losses INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.account_id::INT,
        a.username::TEXT,
        a.rp_balance::NUMERIC,
        s.total_matches::INT,
        s.wins::INT,
        s.losses::INT
    FROM accounts a
    JOIN account_stats s ON a.account_id = s.account_id
    WHERE a.account_id = p_account_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_account_summary(3);


-- Top N jugadores por victorias

DROP FUNCTION get_top_players(integer)

CREATE OR REPLACE FUNCTION get_top_players(p_limit INT)
RETURNS TABLE(account_id INT, username TEXT, wins INT) AS $$
BEGIN
    RETURN QUERY
    SELECT a.account_id, a.username::TEXT, s.wins
      FROM accounts a
      JOIN account_stats s ON a.account_id = s.account_id
     ORDER BY s.wins DESC
     LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_top_players(1);

-- Triggers
-- Trigger BEFORE INSERT en accounts para hashear la contraseña
CREATE OR REPLACE FUNCTION accounts_before_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.password_hash := crypt(NEW.password_hash, gen_salt('bf'));
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_accounts_hash
BEFORE INSERT ON accounts
FOR EACH ROW EXECUTE FUNCTION accounts_before_insert();


INSERT INTO accounts (account_id, username, password_hash, rp_balance, email, server_id)
VALUES (100, 'testuser100', 'mi_password_plain', 1000, 'testuser100@example.com', 8);


SELECT username, password_hash FROM accounts WHERE account_id = 100;

-- Trigger AFTER INSERT en accounts para inicializar account_stats

CREATE OR REPLACE FUNCTION accounts_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO account_stats(account_id) VALUES (NEW.account_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_accounts_stats
AFTER INSERT ON accounts
FOR EACH ROW EXECUTE FUNCTION accounts_after_insert();

SELECT * FROM account_stats WHERE account_id = 100;

-- Trigger AFTER INSERT en rp_purchases para sumar RP al balance

CREATE OR REPLACE FUNCTION rp_purchase_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE accounts
       SET rp_balance = rp_balance + NEW.amount
     WHERE account_id = NEW.account_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_rp_add
AFTER INSERT ON rp_purchases
FOR EACH ROW EXECUTE FUNCTION rp_purchase_after_insert();

-- Inserta una compra de RP para el usuario
INSERT INTO rp_purchases (purchase_id, account_id, amount, purchase_date)
VALUES (1, 100, 500, CURRENT_DATE);


-- Verifica que el rp_balance se haya actualizado
SELECT rp_balance FROM accounts WHERE account_id = 100;




-- Trigger AFTER INSERT en champion_purchases para restar RP del balance al comprar un campeon

CREATE OR REPLACE FUNCTION champion_purchase_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    champ_price NUMERIC;
BEGIN
    SELECT price INTO champ_price FROM champions WHERE champion_id = NEW.champion_id;
    UPDATE accounts
       SET rp_balance = rp_balance - champ_price
     WHERE account_id = NEW.account_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_champion_buy
AFTER INSERT ON champion_purchases
FOR EACH ROW EXECUTE FUNCTION champion_purchase_after_insert();

-- Asegúramos que exista un campeón con champion_id = 10 y precio, por ejemplo:
INSERT INTO champions (champion_id, name, price) VALUES (10, 'ChampionX', 300);

-- Insertamos la compra de campeón para el usuario
INSERT INTO champion_purchases (purchase_id, account_id, champion_id)
VALUES (1, 100, 10);

-- Verifica rp_balance actualizado (disminuido en 300)
SELECT rp_balance FROM accounts WHERE account_id = 100;



-- Trigger AFTER INSERT en skin_purchases para restar RP del balance al comprar una skin

CREATE OR REPLACE FUNCTION skin_purchase_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    skin_price NUMERIC;
BEGIN
    SELECT price INTO skin_price FROM skins WHERE skin_id = NEW.skin_id;
    UPDATE accounts
       SET rp_balance = rp_balance - skin_price
     WHERE account_id = NEW.account_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_skin_buy
AFTER INSERT ON skin_purchases
FOR EACH ROW EXECUTE FUNCTION skin_purchase_after_insert();

-- Asegúramos que exista una skin con skin_id = 20 y precio, por ejemplo:
INSERT INTO skins (skin_id, champion_id ,name, price ) VALUES (20, 10 ,'SkinX', 150);

-- Insertamos la compra de skin para el usuario
INSERT INTO skin_purchases (purchase_id, account_id, skin_id)
VALUES (1, 100, 20);

-- Verificamos si hizo la compra(disminuido en 150)
SELECT rp_balance FROM accounts WHERE account_id = 100;


-- Trigger AFTER INSERT en account_login_history para actualizar last_login

CREATE OR REPLACE FUNCTION login_history_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE accounts
       SET last_login = NEW.login_time
     WHERE account_id = NEW.account_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_login_update
AFTER INSERT ON account_login_history
FOR EACH ROW EXECUTE FUNCTION login_history_after_insert();

INSERT INTO account_login_history (login_id, account_id, login_time)
VALUES (1, 100, NOW());

-- Verifica last_login actualizado en accounts por el id del usuario
SELECT last_login FROM accounts WHERE account_id = 100;


-- Trigger AFTER INSERT en match_participants para actualizar account_stats

CREATE OR REPLACE FUNCTION match_participants_after_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE account_stats
       SET total_matches = total_matches + 1,
           total_kills   = total_kills   + NEW.kills,
           total_assists = total_assists + NEW.assists,
           wins = wins + CASE WHEN NEW.is_winner THEN 1 ELSE 0 END,
           losses = losses + CASE WHEN NEW.is_winner THEN 0 ELSE 1 END
     WHERE account_id = NEW.account_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_match_update_stats
AFTER INSERT ON match_participants
FOR EACH ROW EXECUTE FUNCTION match_participants_after_insert();

INSERT INTO match_participants (participant_id, match_id, summoner_id)
VALUES (100, 1, 5);

-- Verifica account_stats actualizado
SELECT total_matches, total_kills, total_assists, wins, losses
FROM account_stats WHERE account_id = 100;


-- Sp's
-- Crear cuenta nueva con manejo de error
CREATE OR REPLACE PROCEDURE create_account(
    p_username VARCHAR, p_password VARCHAR, p_email VARCHAR, p_server_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        INSERT INTO accounts(username, password_hash, email, server_id)
        VALUES (p_username, p_password, p_email, p_server_id);
        COMMIT;
    EXCEPTION WHEN UNIQUE_VIOLATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'Username or email already exists.';
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
END;
$$;

-- Comprar RP (añadir fondos)
CREATE OR REPLACE PROCEDURE purchase_rp(
    p_account_id INT, p_amount NUMERIC, p_cc_number TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        INSERT INTO rp_purchases(account_id, amount, cc_number)
        VALUES (p_account_id, p_amount, p_cc_number);
        -- El trigger actual sumará p_amount al balance
        COMMIT;
    EXCEPTION WHEN FK_VIOLATION OR INVALID_TEXT_REPRESENTATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'Error: account does not exist or invalid data.';
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
END;
$$;

-- Comprar campeón (resta RP del balance)
CREATE OR REPLACE PROCEDURE purchase_champion(
    p_account_id INT, p_champion_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    acct_balance NUMERIC;
    champ_price NUMERIC;
BEGIN
    SELECT rp_balance INTO acct_balance FROM accounts WHERE account_id = p_account_id;
    SELECT price INTO champ_price FROM champions WHERE champion_id = p_champion_id;
    IF acct_balance IS NULL OR champ_price IS NULL THEN
        RAISE EXCEPTION 'Account or champion not found.';
    END IF;
    IF acct_balance < champ_price THEN
        RAISE EXCEPTION 'Insufficient RP for this purchase.';
    END IF;
    BEGIN
        INSERT INTO champion_purchases(account_id, champion_id)
        VALUES (p_account_id, p_champion_id);
        -- El trigger restará champ_price del balance
        COMMIT;
    EXCEPTION WHEN UNIQUE_VIOLATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'Champion already owned by this account.';
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
END;
$$;

-- Comprar skin (resta RP del balance)
CREATE OR REPLACE PROCEDURE purchase_skin(
    p_account_id INT, p_skin_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    acct_balance NUMERIC;
    skin_price NUMERIC;
BEGIN
    SELECT rp_balance INTO acct_balance FROM accounts WHERE account_id = p_account_id;
    SELECT price INTO skin_price FROM skins WHERE skin_id = p_skin_id;
    IF acct_balance IS NULL OR skin_price IS NULL THEN
        RAISE EXCEPTION 'Account or skin not found.';
    END IF;
    IF acct_balance < skin_price THEN
        RAISE EXCEPTION 'Insufficient RP for this purchase.';
    END IF;
    BEGIN
        INSERT INTO skin_purchases(account_id, skin_id)
        VALUES (p_account_id, p_skin_id);
        -- El trigger restará skin_price del balance
        COMMIT;
    EXCEPTION WHEN UNIQUE_VIOLATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'Skin already owned by this account.';
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
END;
$$;

-- Enviar solicitud de amistad (pending)
CREATE OR REPLACE PROCEDURE add_friend(
    p_account_id INT, p_friend_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        INSERT INTO friend_list(account_id, friend_id)
        VALUES (p_account_id, p_friend_id);
        COMMIT;
    EXCEPTION WHEN UNIQUE_VIOLATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'Friend request already exists.';
    WHEN FK_VIOLATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'One of the accounts does not exist.';
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
END;
$$;

-- Registrar inicio de sesión
CREATE OR REPLACE PROCEDURE login(
    p_account_id INT, p_ip INET
)
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        INSERT INTO account_login_history(account_id, ip_address)
        VALUES (p_account_id, p_ip);
        -- El trigger actualizará last_login en accounts
        COMMIT;
    EXCEPTION WHEN FK_VIOLATION THEN
        ROLLBACK;
        RAISE EXCEPTION 'Account not found for login.';
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;
END;
$$;


-- Views
-- Vista de resumen de cuenta con estadísticas
CREATE VIEW view_account_summary AS
SELECT a.account_id, a.username, a.email, a.rp_balance,
       s.total_matches, s.wins, s.losses, s.total_kills, s.total_assists,
       a.last_login
  FROM accounts a
  JOIN account_stats s ON a.account_id = s.account_id;

-- Vista de estadísticas de campeones
CREATE VIEW view_champion_stats AS
SELECT c.champion_id, c.name AS champion_name,
       COALESCE(cp.purchased_count, 0) AS times_purchased,
       COALESCE(mp.played_count, 0)   AS times_played
  FROM champions c
  LEFT JOIN (
      SELECT champion_id, COUNT(*) AS purchased_count
      FROM champion_purchases GROUP BY champion_id
  ) cp ON c.champion_id = cp.champion_id
  LEFT JOIN (
      SELECT champion_id, COUNT(*) AS played_count
      FROM match_participants GROUP BY champion_id
  ) mp ON c.champion_id = mp.champion_id;

-- Vista de carga de servidores (número de partidas)
CREATE VIEW view_server_load AS
SELECT s.server_id, s.name AS server_name, s.region,
       COUNT(m.match_id) AS total_matches
  FROM servers s
  LEFT JOIN matches m ON s.server_id = m.server_id
  GROUP BY s.server_id, s.name, s.region;


-- Consultas optimizadas
EXPLAIN ANALYZE
SELECT a.username, ROUND((s.wins::NUMERIC/s.total_matches)*100,2) AS win_rate
  FROM accounts a
  JOIN account_stats s ON a.account_id = s.account_id
 WHERE s.total_matches > 0
 ORDER BY win_rate DESC
 LIMIT 5;


EXPLAIN ANALYZE
SELECT a.username, COUNT(mp.match_id) AS total_matches
  FROM accounts a
  JOIN match_participants mp ON a.account_id = mp.account_id
 GROUP BY a.username
 ORDER BY total_matches DESC
 LIMIT 10;


EXPLAIN ANALYZE
SELECT c.name AS champion, COUNT(mp.match_id) AS games_played
  FROM champions c
  LEFT JOIN match_participants mp ON c.champion_id = mp.champion_id
 GROUP BY c.name
 ORDER BY games_played DESC
 LIMIT 5;


EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM rp_purchases
 WHERE account_id = 123;


-- Ofuscar datos sensibles
-- Por ejemplo
SELECT purchase_id, account_id, amount, purchase_date,
       mask_credit_card(cc_number) AS cc_masked
  FROM rp_purchases;

-- Ingresar datos de servers
INSERT INTO servers (name, region, ip_address)
VALUES
    ('NA1', 'North America', '192.168.1.1'),
    ('EUW1', 'Europe West', '192.168.2.1'),
    ('EUNE1', 'Europe Nordic & East', '192.168.3.1'),
    ('KR1', 'Korea', '192.168.4.1'),
    ('BR1', 'Brazil', '192.168.5.1'),
    ('JP1', 'Japan', '192.168.6.1'),
    ('LA1', 'Latin America North', '192.168.7.1'),
    ('LA2', 'Latin America South', '192.168.8.1'),
    ('OCE1', 'Oceania', '192.168.9.1'),
    ('RU1', 'Russia', '192.168.10.1');
-- Script ejecutado para los 30 en accounts
