/* =====================================================================
   FIELDTECH ENGINEERING CHALLENGE - MOTIVA / CCR
   Data Science - Sprint 3: SQL aplicado ao Challenge
   Projeto: LEO (Lawn Engineering Operator) - robô 6WD autônomo de corte de grama
   Banco: PostgreSQL

   Problema da empresa: manter a vegetação das faixas de domínio das rodovias sob
   controle, reduzindo a exposição das equipes de campo a áreas de risco.
   Decisão que o banco apoia: ONDE implantar o LEO primeiro, QUANTAS horas de
   operação cada trecho exige e O QUE corrigir no robô antes da implantação.

   Como executar:
     1) Crie um banco vazio:   CREATE DATABASE fieldtech;
     2) Rode este arquivo:     psql -d fieldtech -f fieldtech_sprint3.sql
     3) As consultas estão na SEÇÃO 3 (Q1 a Q5).
   Os dados são SIMULADOS, porém coerentes com o problema (trechos de rodovia,
   produtividade que cai com a inclinação e a densidade da vegetação, consumo de
   energia proporcional à dificuldade do terreno, falhas de GPS, patinagem etc.).
   Premissa: bateria de 480 Wh; o LEO interrompe a operação abaixo de 15%.
   ===================================================================== */

-- ---------------------------------------------------------------------
-- SEÇÃO 0 - Limpeza (permite rodar o script mais de uma vez)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS operacoes_leo;
DROP TABLE IF EXISTS trechos;

-- ---------------------------------------------------------------------
-- SEÇÃO 1 - Estrutura do banco de dados (CREATE TABLE)
-- ---------------------------------------------------------------------

-- Tabela 1: trechos de rodovia onde o LEO poderia atuar (o "problema" da empresa)
CREATE TABLE trechos (
    id_trecho            INTEGER       PRIMARY KEY,
    localizacao          VARCHAR(60)   NOT NULL,
    tipo_terreno         VARCHAR(20)   NOT NULL,   -- Plano, Talude ou Irregular
    tipo_vegetacao       VARCHAR(30)   NOT NULL,   -- Grama rasteira, Grama alta, Mato denso...
    densidade_vegetacao  VARCHAR(10)   NOT NULL,   -- Baixa, Média ou Alta
    inclinacao_graus     NUMERIC(4,1)  NOT NULL CHECK (inclinacao_graus >= 0),
    area_m2              NUMERIC(8,1)  NOT NULL CHECK (area_m2 > 0),
    nivel_risco_equipe   VARCHAR(10)   NOT NULL CHECK (nivel_risco_equipe IN ('Baixo', 'Médio', 'Alto')),
    cortes_por_mes       INTEGER       NOT NULL CHECK (cortes_por_mes > 0)   -- frequência de roçada exigida
);

-- Tabela 2: cada saída de teste/corte do LEO em um trecho (1 trecho : N operações)
CREATE TABLE operacoes_leo (
    id_operacao           INTEGER       PRIMARY KEY,
    data_operacao         DATE          NOT NULL,
    id_trecho             INTEGER       NOT NULL REFERENCES trechos (id_trecho),
    duracao_min           INTEGER       NOT NULL CHECK (duracao_min > 0),   -- tempo total, incluindo paradas
    area_cortada_m2       NUMERIC(8,1)  NOT NULL,
    energia_consumida_wh  NUMERIC(8,1)  NOT NULL,
    bateria_final_pct     NUMERIC(5,1)  NOT NULL,                           -- todas começam em 100%
    falhas_gps            INTEGER       NOT NULL DEFAULT 0,
    tempo_parado_min      INTEGER       NOT NULL DEFAULT 0,
    status                VARCHAR(15)   NOT NULL CHECK (status IN ('Concluída', 'Interrompida')),
    motivo_interrupcao    VARCHAR(30)                                        -- NULL quando concluída
);

-- ---------------------------------------------------------------------
-- SEÇÃO 2 - Carga dos dados (INSERT INTO)
-- Alternativa: importar os CSVs da pasta dados/ com \copy, por exemplo:
--   \copy trechos FROM 'dados/trechos.csv' WITH (FORMAT csv, HEADER true)
--   \copy operacoes_leo FROM 'dados/operacoes_leo.csv' WITH (FORMAT csv, HEADER true)
-- (se usar os CSVs, comente os INSERTs abaixo para não duplicar os dados)
-- ---------------------------------------------------------------------

INSERT INTO trechos (id_trecho, localizacao, tipo_terreno, tipo_vegetacao, densidade_vegetacao, inclinacao_graus, area_m2, nivel_risco_equipe, cortes_por_mes) VALUES
    (1, 'Canteiro central km 12', 'Plano', 'Grama rasteira', 'Baixa', 2, 1500, 'Alto', 2),
    (2, 'Faixa lateral km 18', 'Plano', 'Grama alta', 'Média', 3, 2200, 'Médio', 2),
    (3, 'Talude km 25', 'Talude', 'Grama alta', 'Média', 18, 1800, 'Alto', 2),
    (4, 'Área de escape km 31', 'Irregular', 'Mato denso', 'Alta', 8, 2500, 'Alto', 3),
    (5, 'Talude km 40', 'Talude', 'Mato denso', 'Alta', 22, 2000, 'Alto', 3),
    (6, 'Praça de pedágio km 47', 'Plano', 'Grama rasteira', 'Baixa', 1, 1000, 'Médio', 2),
    (7, 'Faixa de domínio km 55', 'Irregular', 'Vegetação mista', 'Média', 10, 3000, 'Baixo', 1),
    (8, 'Acesso de serviço km 62', 'Irregular', 'Grama alta', 'Média', 12, 1600, 'Baixo', 1);

INSERT INTO operacoes_leo (id_operacao, data_operacao, id_trecho, duracao_min, area_cortada_m2, energia_consumida_wh, bateria_final_pct, falhas_gps, tempo_parado_min, status, motivo_interrupcao) VALUES
    (1, '2026-08-04', 3, 61, 140.1, 193.9, 59.6, 2, 6, 'Interrompida', 'Perda de sinal GPS'),
    (2, '2026-08-04', 3, 61, 162.0, 199.6, 58.4, 0, 0, 'Concluída', NULL),
    (3, '2026-08-05', 5, 106, 100.4, 404.7, 15.7, 0, 7, 'Interrompida', 'Bateria baixa'),
    (4, '2026-08-05', 6, 83, 359.6, 143.9, 70.0, 0, 0, 'Concluída', NULL),
    (5, '2026-08-05', 8, 83, 240.7, 231.3, 51.8, 0, 0, 'Concluída', NULL),
    (6, '2026-08-07', 2, 62, 171.8, 151.5, 68.4, 1, 5, 'Concluída', NULL),
    (7, '2026-08-12', 3, 48, 73.3, 151.9, 68.4, 1, 16, 'Interrompida', 'Fio de nylon enroscado'),
    (8, '2026-08-14', 4, 61, 83.2, 193.4, 59.7, 2, 10, 'Interrompida', 'Perda de sinal GPS'),
    (9, '2026-08-15', 8, 118, 364.5, 353.9, 26.3, 0, 0, 'Concluída', NULL),
    (10, '2026-08-16', 7, 113, 359.8, 326.7, 31.9, 0, 0, 'Concluída', NULL),
    (11, '2026-08-16', 8, 107, 312.4, 320.6, 33.2, 0, 0, 'Concluída', NULL),
    (12, '2026-08-18', 6, 141, 646.5, 254.6, 47.0, 0, 0, 'Concluída', NULL),
    (13, '2026-08-18', 7, 83, 221.1, 234.8, 51.1, 0, 9, 'Interrompida', 'Patinagem das rodas'),
    (14, '2026-08-20', 7, 59, 122.5, 159.2, 66.8, 1, 20, 'Interrompida', 'Obstáculo no terreno'),
    (15, '2026-08-21', 1, 92, 388.0, 165.3, 65.6, 0, 0, 'Concluída', NULL),
    (16, '2026-08-21', 5, 100, 109.6, 404.3, 15.8, 0, 15, 'Interrompida', 'Bateria baixa'),
    (17, '2026-08-22', 3, 71, 200.9, 219.2, 54.3, 0, 0, 'Concluída', NULL),
    (18, '2026-08-22', 4, 119, 239.4, 396.1, 17.5, 0, 0, 'Concluída', NULL),
    (19, '2026-08-22', 5, 74, 60.6, 285.8, 40.5, 1, 11, 'Concluída', NULL),
    (20, '2026-08-22', 7, 73, 173.6, 192.9, 59.8, 1, 16, 'Interrompida', 'Fio de nylon enroscado'),
    (21, '2026-08-23', 1, 118, 487.7, 220.5, 54.1, 0, 0, 'Concluída', NULL),
    (22, '2026-08-23', 2, 55, 131.3, 126.5, 73.6, 2, 16, 'Interrompida', 'Perda de sinal GPS'),
    (23, '2026-08-23', 4, 71, 116.1, 226.5, 52.8, 0, 0, 'Concluída', NULL),
    (24, '2026-08-23', 5, 104, 113.2, 406.3, 15.4, 2, 10, 'Interrompida', 'Bateria baixa'),
    (25, '2026-08-24', 8, 125, 315.8, 350.0, 27.1, 1, 22, 'Concluída', NULL),
    (26, '2026-08-25', 2, 60, 196.7, 143.0, 70.2, 0, 0, 'Concluída', NULL),
    (27, '2026-08-25', 3, 82, 227.3, 272.1, 43.3, 0, 0, 'Concluída', NULL),
    (28, '2026-08-26', 4, 105, 194.2, 345.7, 28.0, 0, 0, 'Concluída', NULL),
    (29, '2026-08-27', 2, 126, 397.9, 284.0, 40.8, 0, 0, 'Concluída', NULL),
    (30, '2026-08-27', 6, 111, 516.5, 202.7, 57.8, 0, 0, 'Concluída', NULL),
    (31, '2026-08-28', 4, 80, 110.9, 259.6, 45.9, 1, 4, 'Concluída', NULL),
    (32, '2026-08-29', 2, 102, 334.5, 251.5, 47.6, 2, 4, 'Concluída', NULL),
    (33, '2026-08-30', 1, 77, 303.0, 140.3, 70.8, 1, 11, 'Interrompida', 'Fio de nylon enroscado'),
    (34, '2026-08-30', 1, 99, 425.1, 181.8, 62.1, 0, 0, 'Concluída', NULL),
    (35, '2026-08-30', 3, 88, 195.9, 277.4, 42.2, 0, 4, 'Concluída', NULL),
    (36, '2026-08-31', 6, 79, 338.6, 146.3, 69.5, 0, 0, 'Concluída', NULL),
    (37, '2026-08-31', 7, 78, 245.5, 212.5, 55.7, 0, 0, 'Concluída', NULL),
    (38, '2026-08-31', 8, 67, 159.8, 184.2, 61.6, 1, 10, 'Concluída', NULL),
    (39, '2026-08-31', 8, 83, 250.5, 237.7, 50.5, 0, 0, 'Concluída', NULL),
    (40, '2026-09-01', 5, 101, 107.2, 405.4, 15.5, 0, 10, 'Interrompida', 'Bateria baixa'),
    (41, '2026-09-04', 1, 122, 524.9, 245.6, 48.8, 0, 0, 'Concluída', NULL),
    (42, '2026-09-04', 6, 88, 393.3, 164.9, 65.6, 0, 0, 'Concluída', NULL),
    (43, '2026-09-05', 7, 86, 202.4, 230.1, 52.1, 3, 15, 'Concluída', NULL),
    (44, '2026-09-06', 5, 106, 126.4, 405.4, 15.5, 2, 16, 'Interrompida', 'Bateria baixa'),
    (45, '2026-09-10', 1, 127, 579.6, 253.7, 47.1, 1, 4, 'Concluída', NULL),
    (46, '2026-09-10', 4, 97, 146.5, 322.8, 32.8, 1, 9, 'Concluída', NULL),
    (47, '2026-09-11', 2, 110, 371.5, 272.2, 43.3, 1, 3, 'Concluída', NULL),
    (48, '2026-09-12', 6, 63, 296.0, 109.8, 77.1, 0, 0, 'Concluída', NULL);

-- ---------------------------------------------------------------------
-- SEÇÃO 3 - Consultas de negócio
-- Produtividade (m²/h) = area_cortada_m2 / (duracao_min / 60)
-- ---------------------------------------------------------------------

-- ===== Q1 =====
-- Pergunta: Em quais trechos o LEO é mais produtivo? (define por onde começar a implantação)
-- Conceitos: JOIN, AVG, COUNT, GROUP BY, ORDER BY
SELECT t.localizacao,
       t.tipo_terreno,
       t.tipo_vegetacao,
       COUNT(o.id_operacao)                                       AS qtd_operacoes,
       ROUND(AVG(o.area_cortada_m2 / (o.duracao_min / 60.0)), 1)  AS produtividade_media_m2_h
FROM operacoes_leo o
JOIN trechos t ON t.id_trecho = o.id_trecho
GROUP BY t.id_trecho, t.localizacao, t.tipo_terreno, t.tipo_vegetacao
ORDER BY produtividade_media_m2_h DESC;

-- ===== Q2 =====
-- Pergunta: Nos trechos de risco ALTO para as equipes de campo, o LEO já consegue assumir o corte? (quais trocar primeiro)
-- Conceitos: WHERE, JOIN, COUNT, AVG, MIN, GROUP BY, ORDER BY
SELECT t.localizacao,
       COUNT(o.id_operacao)                                              AS qtd_operacoes,
       ROUND(AVG(o.area_cortada_m2 / (o.duracao_min / 60.0)), 1)         AS produtividade_media_m2_h,
       ROUND(100.0 * COUNT(*) FILTER (WHERE o.status = 'Concluída')
             / COUNT(*), 0)                                              AS pct_operacoes_concluidas
FROM operacoes_leo o
JOIN trechos t ON t.id_trecho = o.id_trecho
WHERE t.nivel_risco_equipe = 'Alto'
GROUP BY t.id_trecho, t.localizacao
ORDER BY pct_operacoes_concluidas DESC, produtividade_media_m2_h DESC;

-- ===== Q3 =====
-- Pergunta: Quantas horas de operação do LEO cada trecho exige por mês? (dimensiona a frota e a agenda)
-- Conceitos: JOIN, AVG, GROUP BY, ORDER BY
SELECT t.localizacao,
       t.area_m2,
       t.cortes_por_mes,
       ROUND(AVG(o.area_cortada_m2 / (o.duracao_min / 60.0)), 1)                   AS produtividade_media_m2_h,
       ROUND(t.area_m2 * t.cortes_por_mes
             / AVG(o.area_cortada_m2 / (o.duracao_min / 60.0)), 1)                 AS horas_leo_por_mes
FROM trechos t
JOIN operacoes_leo o ON o.id_trecho = t.id_trecho
GROUP BY t.id_trecho, t.localizacao, t.area_m2, t.cortes_por_mes
ORDER BY horas_leo_por_mes DESC;

-- ===== Q4 =====
-- Pergunta: Qual o principal motivo das operações interrompidas? (o que corrigir primeiro no projeto do LEO)
-- Conceitos: WHERE, COUNT, SUM, AVG, GROUP BY, ORDER BY
SELECT motivo_interrupcao,
       COUNT(*)                        AS qtd_interrupcoes,
       COUNT(DISTINCT id_trecho)       AS trechos_afetados,
       ROUND(AVG(duracao_min), 0)      AS duracao_media_min
FROM operacoes_leo
WHERE status = 'Interrompida'
GROUP BY motivo_interrupcao
ORDER BY qtd_interrupcoes DESC;

-- ===== Q5 =====
-- Pergunta: Em quais trechos a bateria chegou perto do limite (menos de 25%)? (dimensiona bateria e painel solar)
-- Conceitos: WHERE, JOIN, COUNT, MIN, MAX, GROUP BY, ORDER BY
SELECT t.localizacao,
       t.inclinacao_graus,
       COUNT(*)                        AS operacoes_bateria_critica,
       MIN(o.bateria_final_pct)        AS menor_bateria_final_pct,
       MAX(o.energia_consumida_wh)     AS maior_consumo_wh
FROM operacoes_leo o
JOIN trechos t ON t.id_trecho = o.id_trecho
WHERE o.bateria_final_pct < 25
GROUP BY t.id_trecho, t.localizacao, t.inclinacao_graus
ORDER BY operacoes_bateria_critica DESC, menor_bateria_final_pct ASC;
