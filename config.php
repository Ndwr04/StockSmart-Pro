<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$host     = '127.0.0.1';
$port     = '3307';
$dbname   = 'stocksmart_v2';
$username = 'root';
$password = '';

try {
    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    $code = $e->getCode();
    if ($code == 2002) {
        die(erreurDB(
            "MySQL n'est pas démarré",
            "Le serveur MySQL est inaccessible sur 127.0.0.1:3306",
            ["Ouvre XAMPP Control Panel", "Clique Start sur MySQL", "Recharge la page"]
        ));
    } elseif ($code == 1049) {
        die(erreurDB(
            "Base de données introuvable",
            "La base stocksmart_v2 n'existe pas encore.",
            ["Va sur phpMyAdmin", "Importe stocksmart_v2.sql", "Recharge la page"]
        ));
    } else {
        die(erreurDB("Erreur de connexion", htmlspecialchars($e->getMessage()), []));
    }
}

function erreurDB(string $titre, string $desc, array $etapes): string {
    $li = implode('', array_map(fn($e) => "<li style='margin:8px 0;'>$e</li>", $etapes));
    return "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Erreur</title></head>
    <body style='font-family:sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;'>
    <div style='background:#1e293b;border:1px solid #334155;border-radius:16px;padding:40px;max-width:500px;width:100%;'>
    <h2 style='color:#f87171;'>⚠ $titre</h2>
    <p style='color:#94a3b8;margin:16px 0;'>$desc</p>
    <ol style='padding-left:20px;line-height:2;'>$li</ol>
    </div></body></html>";
}

function isLoggedIn(): bool {
    return isset($_SESSION['user_id']);
}

function requireLogin(): void {
    if (!isLoggedIn()) {
        header('Location: /stocksmart/pages/login.php');
        exit;
    }
}

function isAdmin(): bool {
    return ($_SESSION['user_role'] ?? '') === 'admin';
}

function canEdit(): bool {
    return in_array($_SESSION['user_role'] ?? '', ['admin', 'gerant', 'chef_rayon', 'magasinier']);
}

function canDelete(): bool {
    return in_array($_SESSION['user_role'] ?? '', ['admin', 'gerant']);
}

function h(string $s): string {
    return htmlspecialchars($s, ENT_QUOTES, 'UTF-8');
}

function getSessionEnseigneId(): int {
    return (int)($_SESSION['enseigne_id'] ?? 0);
}

function requireEnseigne(): void {
    if (getSessionEnseigneId() <= 0) {
        die("Enseigne de session introuvable.");
    }
}
