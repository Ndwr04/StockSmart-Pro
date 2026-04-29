# 🚀 StockSmart Pro 
Application web de gestion de stock multi-enseignes, développée en PHP, MySQL, HTML, CSS et JavaScript.

Aperçu
StockSmart Pro permet à des enseignes commerciales de gérer leur inventaire en temps réel depuis n'importe quel navigateur. Chaque enseigne dispose d'un espace totalement isolé, avec ses propres produits, mouvements et utilisateurs.

Fonctionnalités

Gestion des produits — ajout, modification, suppression. Photos récupérées automatiquement via l'API Open Food Facts
Mouvements de stock — approvisionnement, vente, perte, casse, retour fournisseur, régularisation d'inventaire
Dashboard temps réel — KPIs, alertes de rupture, activité récente
Système multi-enseignes — chaque enseigne est cloisonnée, les données ne se mélangent jamais
Gestion des rôles — Admin, Gérant, Chef rayon, Magasinier, Caissier, Employé, Lecture, Consultant
Invitation par code — un admin crée son enseigne et invite ses employés via un code unique
Trigger SQL — mise à jour automatique du stock à chaque mouvement enregistré


Stack technique
CoucheTechnologieBackendPHP 8+Base de donnéesMySQL / MariaDBFrontendHTML, CSS, JavaScriptSécuritépassword_hash(), sessions PHP, PDO préparéAPI externeOpen Food Facts

Installation locale (XAMPP)

Clone le dépôt dans C:/xampp/htdocs/ :

bashgit clone https://github.com/ton-user/stocksmart.git StockSmart

Importe la base de données dans phpMyAdmin :

http://localhost/phpmyadmin
→ Importer → stocksmart_v2.sql

Configure la connexion dans config.php :

php$host     = '127.0.0.1';
$port     = '3307';        // adapte selon ton XAMPP
$dbname   = 'stocksmart_v2';
$username = 'root';
$password = '';            // ton mot de passe local

Lance le site :

http://localhost/StockSmart

Compte de démonstration
EmailMot de passeRôleadmin@stocksmart.propasswordAdmin — Carrefour Paris-Est

Structure du projet
StockSmart/
├── config.php              # Configuration centrale, helpers

├── index.php               # Landing page

├── dashboard.php           # Tableau de bord

├── pages/

│   ├── register.php        # Inscription / création d'enseigne
│   ├── login.php           # Connexion
│   ├── produits.php        # Gestion des produits
│   ├── categories.php      # Gestion des catégories
│   ├── mouvements.php      # Enregistrement des mouvements
│   └── admin.php           # Administration
├── assets/
│   ├── css/style.css       # Design global
│   ├── js/script.js        # Interactions
│   └── js/off-photos.js    # API Open Food Facts + cache
└── stocksmart_v2.sql       # Base de données complète

Auteurs
Projet réalisé dans le cadre d'un cours de développement web.

Mahjoub Omaima
Niakale Diawara
