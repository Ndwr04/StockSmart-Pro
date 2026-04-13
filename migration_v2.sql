-- ============================================================
-- MIGRATION — Ajouter code_invitation à la table enseignes
-- À exécuter UNE FOIS dans phpMyAdmin > SQL
-- ============================================================

USE stocksmart_v2;

ALTER TABLE enseignes
  ADD COLUMN code_invitation VARCHAR(20) DEFAULT NULL,
  ADD COLUMN actif TINYINT(1) NOT NULL DEFAULT 1,
  ADD UNIQUE KEY uq_enseignes_code_invitation (code_invitation);

ALTER TABLE utilisateurs
  ADD COLUMN actif TINYINT(1) NOT NULL DEFAULT 1;

UPDATE enseignes
SET code_invitation = CONCAT(
  UPPER(LEFT(REPLACE(nom, ' ', ''), 6)),
  '-',
  FLOOR(1000 + RAND() * 9000)
)
WHERE code_invitation IS NULL OR code_invitation = '';

SELECT id, nom, code_invitation, actif
FROM enseignes;


ALTER TABLE categories
ADD COLUMN enseigne_id INT NULL AFTER id;

ALTER TABLE produits
ADD COLUMN enseigne_id INT NULL AFTER id;

ALTER TABLE utilisateurs
ADD COLUMN enseigne_id INT NULL AFTER id;

UPDATE categories SET enseigne_id = 1 WHERE enseigne_id IS NULL;
UPDATE produits SET enseigne_id = 1 WHERE enseigne_id IS NULL;
UPDATE utilisateurs SET enseigne_id = 1 WHERE enseigne_id IS NULL;

ALTER TABLE categories
MODIFY enseigne_id INT NOT NULL;

ALTER TABLE produits
MODIFY enseigne_id INT NOT NULL;

ALTER TABLE utilisateurs
MODIFY enseigne_id INT NOT NULL;

ALTER TABLE categories
ADD CONSTRAINT fk_categories_enseigne
FOREIGN KEY (enseigne_id) REFERENCES enseignes(id)
ON DELETE CASCADE;

ALTER TABLE produits
ADD CONSTRAINT fk_produits_enseigne
FOREIGN KEY (enseigne_id) REFERENCES enseignes(id)
ON DELETE CASCADE;

ALTER TABLE utilisateurs
ADD CONSTRAINT fk_utilisateurs_enseigne
FOREIGN KEY (enseigne_id) REFERENCES enseignes(id)
ON DELETE CASCADE;
