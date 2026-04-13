-- =====================================================
-- STOCKSMART V2 - BASE MULTI-TENANT CORRIGÉE
-- Une seule base, filtrage enseigne_id automatique
-- =====================================================

CREATE DATABASE IF NOT EXISTS stocksmart_v2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE stocksmart_v2;

-- Nettoyage
DROP TRIGGER IF EXISTS after_mouvement_insert;
DROP TABLE IF EXISTS mouvements;
DROP TABLE IF EXISTS produits;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS utilisateurs;
DROP TABLE IF EXISTS enseignes;

-- ═══════════════════════════════════════════════════
-- 1. ENSEIGNES (global)
-- ═══════════════════════════════════════════════════
CREATE TABLE enseignes (
  id int(11) NOT NULL AUTO_INCREMENT,
  nom varchar(100) NOT NULL,
  logo_url varchar(255) DEFAULT '',
  couleur varchar(20) DEFAULT '#e94560',
  actif tinyint(1) DEFAULT 1,
  created_at timestamp NOT NULL DEFAULT current_timestamp(),
  code_invitation varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  INDEX idx_actif (actif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ═══════════════════════════════════════════════════
-- 2. UTILISATEURS (enseigne_id OBLIGATOIRE)
-- ═══════════════════════════════════════════════════
CREATE TABLE utilisateurs (
  id int(11) NOT NULL AUTO_INCREMENT,
  nom varchar(100) NOT NULL,
  prenom varchar(100) NOT NULL,
  email varchar(150) NOT NULL,
  mot_de_passe varchar(255) NOT NULL,
  role enum('admin','gerant','chef_rayon','magasinier','caissier','employe','lecture','consultant') DEFAULT 'employe',
  enseigne_id int(11) NOT NULL,  -- ✅ OBLIGATOIRE
  actif tinyint(1) DEFAULT 1,
  created_at timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (id),
  UNIQUE KEY uk_email_enseigne (email, enseigne_id),
  KEY idx_enseigne_role (enseigne_id, role),
  KEY idx_enseigne_actif (enseigne_id, actif),
  FOREIGN KEY (enseigne_id) REFERENCES enseignes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ═══════════════════════════════════════════════════
-- 3. CATÉGORIES (GLOBALES, partagées entre enseignes)
-- ═══════════════════════════════════════════════════
CREATE TABLE categories (
  id int(11) NOT NULL AUTO_INCREMENT,
  nom varchar(100) NOT NULL,
  PRIMARY KEY (id),
  INDEX idx_nom (nom)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ═══════════════════════════════════════════════════
-- 4. PRODUITS (enseigne_id OBLIGATOIRE)
-- ═══════════════════════════════════════════════════
CREATE TABLE produits (
  id int(11) NOT NULL AUTO_INCREMENT,
  enseigne_id int(11) NOT NULL,        -- ✅ OBLIGATOIRE
  reference varchar(50) NOT NULL,
  nom varchar(150) NOT NULL,
  marque varchar(100) DEFAULT '',
  fournisseur varchar(100) DEFAULT '',
  categorie_id int(11) DEFAULT NULL,
  quantite int(11) DEFAULT 0,
  seuil_alerte int(11) DEFAULT 5,
  prix decimal(10,2) DEFAULT 0.00,
  image varchar(255) DEFAULT '',
  created_at timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (id),
  UNIQUE KEY uk_reference_enseigne (reference, enseigne_id),  -- référence unique PAR ENSEIGNE
  KEY idx_enseigne_nom (enseigne_id, nom),
  KEY idx_enseigne_quantite (enseigne_id, quantite),
  KEY idx_enseigne_seuil (enseigne_id, seuil_alerte),
  FOREIGN KEY (enseigne_id) REFERENCES enseignes(id) ON DELETE CASCADE,
  FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ═══════════════════════════════════════════════════
-- 5. MOUVEMENTS (enseigne_id OBLIGATOIRE)
-- ═══════════════════════════════════════════════════
CREATE TABLE mouvements (
  id int(11) NOT NULL AUTO_INCREMENT,
  enseigne_id int(11) NOT NULL,        -- ✅ OBLIGATOIRE
  produit_id int(11) NOT NULL,
  utilisateur_id int(11) DEFAULT NULL,
  type_mouvement enum('approvisionnement','vente','perte_peremption','casse','retour_fournisseur','inventaire_regularisation','transfert','perte') NOT NULL,
  quantite int(11) NOT NULL,
  commentaire text DEFAULT NULL,
  date_mouvement datetime DEFAULT current_timestamp(),
  PRIMARY KEY (id),
  KEY idx_enseigne_date (enseigne_id, date_mouvement),
  KEY idx_produit (produit_id),
  KEY idx_utilisateur (utilisateur_id),
  FOREIGN KEY (enseigne_id) REFERENCES enseignes(id) ON DELETE CASCADE,
  FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ═══════════════════════════════════════════════════
-- DONNÉES DE TEST CORRIGÉES
-- ═══════════════════════════════════════════════════

-- Enseigne
INSERT INTO enseignes (id, nom, logo_url, couleur, actif, created_at, code_invitation) VALUES
(1, 'Carrefour Paris-Est', 'https://ui-avatars.com/api/?name=CA&background=003189&color=fff', '#003189', 1, '2026-04-09 09:59:04', '');

-- Catégories
INSERT INTO categories (id, nom) VALUES
(1, 'Fruits et légumes'),
(2, 'Charcuterie / traiteur'),
(3, 'Boucherie / volaille'),
(4, 'Poissonnerie'),
(5, 'Crèmerie / produits laitiers'),
(6, 'Épicerie salée'),
(7, 'Épicerie sucrée'),
(8, 'Petit-déjeuner'),
(9, 'Boissons'),
(10, 'Surgelés'),
(11, 'Hygiène / beauté'),
(12, 'Entretien maison'),
(13, 'Bébé'),
(14, 'Animalerie'),
(15, 'Bazar / maison'),
(16, 'Textile'),
(17, 'Électroménager / multimédia'),
(18, 'Papeterie / librairie');

-- Utilisateurs (enseigne_id = 1 pour Carrefour)
INSERT INTO utilisateurs (id, nom, prenom, email, mot_de_passe, role, enseigne_id, actif, created_at) VALUES
(1, 'Diawara', 'Niakale', 'admin@stocksmart.pro', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 1, 1, '2026-04-09 09:59:04'),
(2, 'Renault', 'Thomas', 'thomas@carrefour.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employe', 1, 1, '2026-04-09 09:59:04'),
(3, 'Lambert', 'Marie', 'marie@carrefour.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employe', 1, 1, '2026-04-09 09:59:04'),
(4, 'Rousseau', 'Marc', 'marc@leclerc.fr', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'gerant', 1, 1, '2026-04-09 09:59:04');

-- Produits (enseigne_id = 1 pour Carrefour)
INSERT INTO produits (id, enseigne_id, reference, nom, marque, fournisseur, categorie_id, quantite, seuil_alerte, prix, image, created_at) VALUES
(1, 1, 'P001', 'Jus Orange 1L', 'Joker', '', 9, 3, 10, 1.29, 'assets/img/produits/img_69d817a739fb63.73291519.webp', '2026-04-09 09:59:04'),
(2, 1, 'P002', 'Eau minérale 1.5L', 'Évian', '', 9, 20, 5, 0.89, 'assets/img/produits/img_69d8177f8bb3e1.86314665.jpg', '2026-04-09 09:59:04'),
(3, 1, 'P003', 'Chips salés 200g', 'Lay\'s', '', 6, 1, 5, 1.80, 'assets/img/produits/img_69d8176ca88592.12030784.webp', '2026-04-09 09:59:04'),
(4, 1, 'P004', 'Yaourt nature x8', 'Danone', '', 5, 24, 5, 1.89, 'assets/img/produits/img_69d817ca135403.33479536.webp', '2026-04-09 09:59:04'),
(5, 1, 'P005', 'Savon liquide 500ml', 'Sanytol', '', 11, 16, 3, 3.20, 'assets/img/produits/img_69d817bba5ba16.31881112.jpg', '2026-04-09 09:59:04'),
(6, 1, 'P006', 'Biscuit chocolat', 'Lu', '', 7, 0, 5, 2.10, '', '2026-04-09 09:59:04'),
(7, 1, 'P007', 'Soda cola 33cl', 'Coca-Cola', '', 9, 50, 8, 1.20, 'assets/img/produits/img_69d817c2d949f1.22067776.webp', '2026-04-09 09:59:04'),
(8, 1, 'P008', 'Cahier 96p', 'Oxford', '', 18, 7, 15, 2.49, 'assets/img/produits/img_69d8176310c6b2.60308905.jpg', '2026-04-09 09:59:04'),
(9, 1, 'P009', 'Filets cabillaud 400g', 'Pescanova', '', 4, 32, 5, 4.99, 'assets/img/produits/img_69d8179b6e0c38.80120356.png', '2026-04-09 09:59:04'),
(10, 1, 'P010', 'Pain de mie spécial', 'Harry\'s', '', 8, 8, 15, 1.65, 'assets/img/produits/img_69d817b22ec8e3.55221778.webp', '2026-04-09 09:59:04'),
(11, 1, 'P011', 'Pommes Golden 1kg', 'Ferme Dupont', '', 1, 18, 6, 2.99, 'assets/img/produits/pommes-golden.jpg', '2026-04-09 09:59:04'),
(12, 1, 'P012', 'Bananes 1kg', 'Banana Corp', '', 1, 25, 8, 1.79, 'assets/img/produits/bananes.jpg', '2026-04-09 09:59:04'),
(13, 1, 'P013', 'Carottes 1kg', 'Ferme Bio', '', 1, 30, 10, 1.20, 'assets/img/produits/carottes.jpg', '2026-04-09 09:59:04'),
(14, 1, 'P014', 'Salade verte', 'Maraîcher Local', '', 1, 15, 5, 1.50, 'assets/img/produits/salade.jpg', '2026-04-09 09:59:04'),
(15, 1, 'P015', 'Tomates 500g', 'Maraîcher Local', '', 1, 12, 4, 2.20, 'assets/img/produits/tomates.jpg', '2026-04-09 09:59:04'),
(16, 1, 'P016', 'Pommes de terre 2kg', 'Ferme Dupont', '', 1, 40, 15, 2.49, 'assets/img/produits/pommes-terre.jpg', '2026-04-09 09:59:04'),
(17, 1, 'P017', 'Courgettes 1kg', 'Ferme Bio', '', 1, 8, 3, 2.10, 'assets/img/produits/courgettes.jpg', '2026-04-09 09:59:04'),
(18, 1, 'P018', 'Oignons 1kg', 'Ferme Dupont', '', 1, 22, 7, 1.80, 'assets/img/produits/oignons.jpg', '2026-04-09 09:59:04'),
(19, 1, 'P019', 'Ail 250g', 'Ferme Bio', '', 1, 35, 12, 1.90, 'assets/img/produits/ail.jpg', '2026-04-09 09:59:04'),
(20, 1, 'P020', 'Citrons 1kg', 'Agrumes Sud', '', 1, 14, 5, 3.20, 'assets/img/produits/citrons.jpg', '2026-04-09 09:59:04'),
(21, 1, 'P021', 'Escalopes poulet 1kg', 'Boucherie Martin', '', 3, 10, 4, 7.50, 'assets/img/produits/escalopes-poulet.jpg', '2026-04-09 09:59:04'),
(22, 1, 'P022', 'Steak haché 20%', 'Maison Bouvet', '', 3, 8, 3, 6.90, 'assets/img/produits/steak-hache.jpg', '2026-04-09 09:59:04'),
(23, 1, 'P023', 'Cuisses poulet', 'Volaille Express', '', 3, 15, 6, 5.80, 'assets/img/produits/cuisses-poulet.jpg', '2026-04-09 09:59:04'),
(24, 1, 'P024', 'Côtelettes porc', 'Boucherie Martin', '', 3, 12, 5, 8.20, 'assets/img/produits/cottelettes-porc.jpg', '2026-04-09 09:59:04'),
(25, 1, 'P025', 'Merguez 500g', 'Maison Bouvet', '', 3, 20, 8, 4.50, 'assets/img/produits/merguez.jpg', '2026-04-09 09:59:04'),
(26, 1, 'P026', 'Aiguillettes poulet', 'Volaille Express', '', 3, 6, 2, 7.90, 'assets/img/produits/aiguillettes.jpg', '2026-04-09 09:59:04'),
(27, 1, 'P027', 'Filet mignon porc', 'Boucherie Martin', '', 3, 5, 2, 12.50, 'assets/img/produits/filet-mignon.jpg', '2026-04-09 09:59:04'),
(28, 1, 'P028', 'Surlonge bœuf', 'Maison Bouvet', '', 3, 4, 2, 15.90, 'assets/img/produits/surlonge-boeuf.jpg', '2026-04-09 09:59:04'),
(29, 1, 'P029', 'Foie poulet 500g', 'Volaille Express', '', 3, 18, 7, 3.80, 'assets/img/produits/foie-poulet.jpg', '2026-04-09 09:59:04'),
(30, 1, 'P030', 'Haut de cuisse dinde', 'Boucherie Martin', '', 3, 9, 4, 9.20, 'assets/img/produits/cuisse-dinde.jpg', '2026-04-09 09:59:04'),
(31, 1, 'P031', 'Jambon blanc 200g', 'Charcuterie Du Coin', '', 2, 25, 10, 2.80, 'assets/img/produits/jambon-blanc.jpg', '2026-04-09 09:59:04'),
(32, 1, 'P032', 'Rillettes porc 180g', 'Maison Cendré', '', 2, 16, 6, 3.20, 'assets/img/produits/rillettes.jpg', '2026-04-09 09:59:04'),
(33, 1, 'P033', 'Pâté maison 200g', 'Maison Cendré', '', 2, 14, 5, 4.10, 'assets/img/produits/pate-maison.jpg', '2026-04-09 09:59:04'),
(34, 1, 'P034', 'Saucisson sec 200g', 'Charcuterie Du Coin', '', 2, 22, 8, 5.90, 'assets/img/produits/saucisson-sec.jpg', '2026-04-09 09:59:04'),
(35, 1, 'P035', 'Fromage de tête', 'Maison Cendré', '', 2, 12, 4, 4.50, 'assets/img/produits/fromage-tete.jpg', '2026-04-09 09:59:04'),
(36, 1, 'P036', 'Chorizo 200g', 'Charcuterie Du Coin', '', 2, 18, 7, 6.20, 'assets/img/produits/chorizo.jpg', '2026-04-09 09:59:04'),
(37, 1, 'P037', 'Jambon cru 100g', 'Maison Cendré', '', 2, 10, 3, 7.80, 'assets/img/produits/jambon-cru.jpg', '2026-04-09 09:59:04'),
(38, 1, 'P038', 'Terrine campagne', 'Charcuterie Du Coin', '', 2, 11, 4, 5.60, 'assets/img/produits/terrine.jpg', '2026-04-09 09:59:04'),
(39, 1, 'P039', 'Knacki 10x40g', 'Herta', '', 2, 30, 12, 3.90, 'assets/img/produits/knacki.jpg', '2026-04-09 09:59:04'),
(40, 1, 'P040', 'Salami 150g', 'Charcuterie Du Coin', '', 2, 15, 6, 6.80, 'assets/img/produits/salami.jpg', '2026-04-09 09:59:04'),
(41, 1, 'P041', 'Filets cabillaud 400g', 'Poisson Frais SA', '', 4, 8, 3, 9.90, 'assets/img/produits/cabillaud.jpg', '2026-04-09 09:59:04'),
(42, 1, 'P042', 'Crevettes roses 200g', 'Marée Atlantique', '', 4, 12, 4, 7.50, 'assets/img/produits/crevettes.jpg', '2026-04-09 09:59:04'),
(43, 1, 'P043', 'Saumon fumé 100g', 'Marée Atlantique', '', 4, 20, 8, 6.80, 'assets/img/produits/saumon-fume.jpg', '2026-04-09 09:59:04'),
(44, 1, 'P044', 'Filets maquereau', 'Poisson Frais SA', '', 4, 10, 4, 4.20, 'assets/img/produits/maquereau.jpg', '2026-04-09 09:59:04'),
(45, 1, 'P045', 'Moules décortiquées', 'Marée Atlantique', '', 4, 6, 2, 5.90, 'assets/img/produits/moules.jpg', '2026-04-09 09:59:04'),
(46, 1, 'P046', 'Thon au naturel', 'Conserverie Océane', '', 4, 25, 10, 1.80, 'assets/img/produits/thon-naturel.jpg', '2026-04-09 09:59:04'),
(47, 1, 'P047', 'Sardines en boîte', 'Conserverie Océane', '', 4, 35, 15, 1.20, 'assets/img/produits/sardines.jpg', '2026-04-09 09:59:04'),
(48, 1, 'P048', 'Surimi bâtonnets', 'Frais & Co', '', 4, 18, 7, 2.99, 'assets/img/produits/surimi.jpg', '2026-04-09 09:59:04'),
(49, 1, 'P049', 'Anchois marinade', 'Conserverie Océane', '', 4, 14, 5, 3.50, 'assets/img/produits/anchois.jpg', '2026-04-09 09:59:04'),
(50, 1, 'P050', 'Calmars anneaux', 'Poisson Frais SA', '', 4, 9, 3, 8.90, 'assets/img/produits/calmars.jpg', '2026-04-09 09:59:04'),
(51, 1, 'P051', 'Yaourt nature 4x125g', 'Danone', '', 5, 12, 4, 0.90, 'assets/img/produits/yaourt-nature.jpg', '2026-04-09 09:59:04'),
(52, 1, 'P052', 'Beurre demi-sel 250g', 'Lactalis', '', 5, 20, 8, 2.40, 'assets/img/produits/beurre.jpg', '2026-04-09 09:59:04'),
(53, 1, 'P053', 'Fromage emmental 300g', 'Fromagerie Centrale', '', 5, 15, 6, 4.80, 'assets/img/produits/emmental.jpg', '2026-04-09 09:59:04'),
(54, 1, 'P054', 'Camembert 250g', 'Fromagerie Centrale', '', 5, 10, 4, 3.90, 'assets/img/produits/camembert.jpg', '2026-04-09 09:59:04'),
(55, 1, 'P055', 'Crème fraîche 20%', 'Lactalis', '', 5, 18, 7, 1.60, 'assets/img/produits/creme-fraiche.jpg', '2026-04-09 09:59:04'),
(56, 1, 'P056', 'Lait entier 1L', 'Danone', '', 5, 30, 12, 1.20, 'assets/img/produits/lait-entier.jpg', '2026-04-09 09:59:04'),
(57, 1, 'P057', 'Fromage frais 150g', 'Fromagerie Centrale', '', 5, 22, 9, 1.99, 'assets/img/produits/fromage-frais.jpg', '2026-04-09 09:59:04'),
(58, 1, 'P058', 'Œufs moyens x12', 'Ferme du Nid', '', 5, 25, 10, 3.20, 'assets/img/produits/oeufs.jpg', '2026-04-09 09:59:04'),
(59, 1, 'P059', 'Roquefort 200g', 'Fromagerie Centrale', '', 5, 8, 3, 6.50, 'assets/img/produits/roquefort.jpg', '2026-04-09 09:59:04'),
(60, 1, 'P060', 'Petits suisses 4x60g', 'Danone', '', 5, 16, 6, 2.10, 'assets/img/produits/petits-suisses.jpg', '2026-04-09 09:59:04'),
(61, 1, 'P061', 'Jus orange 1L', 'Tropicana', '', 9, 5, 5, 2.50, 'assets/img/produits/jus-orange.jpg', '2026-04-09 09:59:04'),
(62, 1, 'P062', 'Eau minérale 1.5L', 'Evian', '', 9, 20, 5, 1.00, 'assets/img/produits/eau-minerale.jpg', '2026-04-09 09:59:04'),
(63, 1, 'P063', 'Coca Cola 33cl', 'Coca-Cola', '', 9, 25, 10, 1.20, 'assets/img/produits/coca-cola.jpg', '2026-04-09 09:59:04'),
(64, 1, 'P064', 'Eau pétillante 1L', 'Perrier', '', 9, 15, 6, 1.40, 'assets/img/produits/eau-petillante.jpg', '2026-04-09 09:59:04'),
(65, 1, 'P065', 'Jus multifruit 1L', 'Tropicana', '', 9, 8, 3, 2.80, 'assets/img/produits/jus-multifruit.jpg', '2026-04-09 09:59:04'),
(66, 1, 'P066', 'Thé glacé 1.5L', 'Lipton', '', 9, 12, 4, 2.10, 'assets/img/produits/the-glace.jpg', '2026-04-09 09:59:04'),
(67, 1, 'P067', 'Sprite 33cl', 'Sprite', '', 9, 18, 7, 1.30, 'assets/img/produits/sprite.jpg', '2026-04-09 09:59:04'),
(68, 1, 'P068', 'Bière blonde 33cl x6', 'Heineken', '', 9, 10, 4, 7.90, 'assets/img/produits/biere-blonde.jpg', '2026-04-09 09:59:04'),
(69, 1, 'P069', 'Sirop menthe 1L', 'Teisseire', '', 9, 14, 5, 4.50, 'assets/img/produits/sirop-menthe.jpg', '2026-04-09 09:59:04'),
(70, 1, 'P070', 'Limonade 1L', 'Lorina', '', 9, 11, 4, 2.20, 'assets/img/produits/limonade.jpg', '2026-04-09 09:59:04'),
(71, 1, 'P071', 'Savon liquide 500ml', 'Dove', '', 11, 8, 3, 3.20, 'assets/img/produits/savon-liquide.jpg', '2026-04-09 09:59:04'),
(72, 1, 'P072', 'Shampoing 400ml', 'L’Oréal', '', 11, 12, 4, 4.90, 'assets/img/produits/shampoing.jpg', '2026-04-09 09:59:04'),
(73, 1, 'P073', 'Dentifrice 100ml', 'Colgate', '', 11, 25, 10, 2.80, 'assets/img/produits/dentifrice.jpg', '2026-04-09 09:59:04'),
(74, 1, 'P074', 'Déodorant spray', 'Nivea', '', 11, 18, 7, 3.50, 'assets/img/produits/deodorant.jpg', '2026-04-09 09:59:04'),
(75, 1, 'P075', 'Gel douche 250ml', 'Dove', '', 11, 15, 6, 2.99, 'assets/img/produits/gel-douche.jpg', '2026-04-09 09:59:04'),
(76, 1, 'P076', 'Crème hydratante', 'Nivea', '', 11, 10, 4, 6.80, 'assets/img/produits/creme-hydratante.jpg', '2026-04-09 09:59:04'),
(77, 1, 'P077', 'Rasoir 5 lames', 'Gillette', '', 11, 22, 9, 8.90, 'assets/img/produits/rasoir.jpg', '2026-04-09 09:59:04'),
(78, 1, 'P078', 'Papier toilette x12', 'Lotus', '', 12, 30, 12, 7.50, 'assets/img/produits/papier-toilette.jpg', '2026-04-09 09:59:04'),
(79, 1, 'P079', 'Serviettes hygiéniques', 'Always', '', 11, 16, 6, 3.20, 'assets/img/produits/serviettes.jpg', '2026-04-09 09:59:04'),
(80, 1, 'P080', 'Aftershave 100ml', 'Nivea Men', '', 11, 14, 5, 5.90, 'assets/img/produits/aftershave.jpg', '2026-04-09 09:59:04'),
(81, 1, 'P081', 'Liquide vaisselle 1L', 'Paic', '', 12, 20, 8, 2.49, 'assets/img/produits/liquide-vaisselle.jpg', '2026-04-09 09:59:04'),
(82, 1, 'P082', 'Lessive liquide 2L', 'Ariel', '', 12, 12, 4, 6.90, 'assets/img/produits/lessive-liquide.jpg', '2026-04-09 09:59:04'),
(83, 1, 'P083', 'Produits multi-surfaces', 'Mr Propre', '', 12, 15, 6, 3.80, 'assets/img/produits/multi-surfaces.jpg', '2026-04-09 09:59:04'),
(84, 1, 'P084', 'Eau de javel 1L', 'Ajax', '', 12, 18, 7, 1.99, 'assets/img/produits/eau-javel.jpg', '2026-04-09 09:59:04'),
(85, 1, 'P085', 'Sac poubelle 50L x50', 'Spontex', '', 12, 25, 10, 9.50, 'assets/img/produits/sac-poubelle.jpg', '2026-04-09 09:59:04'),
(86, 1, 'P086', 'Destructeur graisse', 'Cillit Bang', '', 12, 10, 4, 4.20, 'assets/img/produits/destructeur-graisse.jpg', '2026-04-09 09:59:04'),
(87, 1, 'P087', 'Eponges x4', 'Scotch-Brite', '', 12, 30, 12, 2.10, 'assets/img/produits/eponges.jpg', '2026-04-09 09:59:04'),
(88, 1, 'P088', 'Produits vitres 750ml', 'Ajax', '', 12, 16, 6, 2.80, 'assets/img/produits/vitres.jpg', '2026-04-09 09:59:04'),
(89, 1, 'P089', 'Gants caoutchouc', 'Spontex', '', 12, 22, 9, 1.80, 'assets/img/produits/gants-caoutchouc.jpg', '2026-04-09 09:59:04'),
(90, 1, 'P090', 'Chiffons microfibres x5', 'Vileda', '', 12, 28, 11, 4.90, 'assets/img/produits/chiffons.jpg', '2026-04-09 09:59:04'),
(91, 1, 'P091', 'Couches taille 2 x40', 'Pampers', '', 13, 8, 3, 12.90, 'assets/img/produits/couches-t2.jpg', '2026-04-09 09:59:04'),
(92, 1, 'P092', 'Lait 1er âge 400g', 'Gallia', '', 13, 12, 4, 15.50, 'assets/img/produits/lait-bebe.jpg', '2026-04-09 09:59:04'),
(93, 1, 'P093', 'Lingettes x80', 'Pampers', '', 13, 15, 6, 3.99, 'assets/img/produits/lingettes.jpg', '2026-04-09 09:59:04'),
(94, 1, 'P094', 'Compote pomme x4', 'Good Gout', '', 13, 20, 8, 2.20, 'assets/img/produits/compote-pomme.jpg', '2026-04-09 09:59:04'),
(95, 1, 'P095', 'Biberon 260ml', 'Avent', '', 13, 10, 4, 7.80, 'assets/img/produits/biberon.jpg', '2026-04-09 09:59:04'),
(96, 1, 'P096', 'Eau bébé 1L', 'Evian', '', 13, 18, 7, 1.60, 'assets/img/produits/eau-bebe.jpg', '2026-04-09 09:59:04'),
(97, 1, 'P097', 'Couches taille 1 x40', 'Pampers', '', 13, 9, 3, 12.90, 'assets/img/produits/couches-t1.jpg', '2026-04-09 09:59:04'),
(98, 1, 'P098', 'Tetine silicone', 'Avent', '', 13, 25, 10, 4.50, 'assets/img/produits/tetine.jpg', '2026-04-09 09:59:04'),
(99, 1, 'P099', 'Linge bébé x3', 'Petit Bateau', '', 16, 14, 5, 8.90, 'assets/img/produits/linge-bebe.jpg', '2026-04-09 09:59:04'),
(100, 1, 'P100', 'Doudou ours', 'Kaloo', '', 13, 16, 6, 9.99, 'assets/img/produits/doudou.jpg', '2026-04-09 09:59:04');

INSERT INTO mouvements (id, enseigne_id, produit_id, utilisateur_id, type_mouvement, quantite, commentaire, date_mouvement) VALUES
(1, 1, 9, NULL, 'approvisionnement', 6, 'Réception commande fournisseur', '2026-04-09 09:59:04'),
(2, 1, 8, NULL, 'vente', 5, 'Vente en caisse', '2026-04-09 06:59:04'),
(3, 1, 4, NULL, 'approvisionnement', 12, 'Approvisionnement yaourts', '2026-04-08 11:59:04'),
(4, 1, 1, NULL, 'vente', 2, 'Vente directe', '2026-04-08 11:59:04'),
(5, 1, 7, NULL, 'approvisionnement', 25, 'Livraison hebdomadaire', '2026-04-07 11:59:04'),
(6, 1, 6, NULL, 'vente', 5, 'Vente biscuits chocolat', '2026-04-06 11:59:04'),
(7, 1, 3, NULL, 'perte', 2, 'Emballage abîmé', '2026-04-05 11:59:04'),
(8, 1, 5, NULL, 'approvisionnement', 8, 'Réassort hygiène', '2026-04-04 11:59:04'),
(9, 1, 10, NULL, 'retour_fournisseur', 1, 'Produit retourné fournisseur', '2026-04-04 10:59:04'),
(10, 1, 11, NULL, 'inventaire_regularisation', 2, 'Correction d’inventaire', '2026-04-03 09:59:04');

DROP TRIGGER IF EXISTS after_mouvement_insert;
DELIMITER $$
CREATE TRIGGER after_mouvement_insert
AFTER INSERT ON mouvements
FOR EACH ROW
BEGIN
  IF NEW.type_mouvement IN ('approvisionnement', 'retour_fournisseur', 'inventaire_regularisation') THEN
    UPDATE produits
    SET quantite = quantite + NEW.quantite
    WHERE id = NEW.produit_id;
  ELSE
    UPDATE produits
    SET quantite = GREATEST(0, quantite - NEW.quantite)
    WHERE id = NEW.produit_id;
  END IF;
END$$
DELIMITER ;


