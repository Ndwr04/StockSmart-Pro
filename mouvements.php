<?php
require_once '../config.php';
requireLogin();
requireEnseigne();

$enseigne_id = getSessionEnseigneId();

$message = '';
$success = false;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $produit_id  = (int)($_POST['produit_id'] ?? 0);
    $type        = $_POST['type_mouvement'] ?? '';
    $quantite    = (int)($_POST['quantite'] ?? 0);
    $commentaire = trim($_POST['commentaire'] ?? '');
    $enseigne_id = $_SESSION['enseigne_id'];

    // ✅ Types mis à jour selon ta BDD
    $typesValides = [
        'approvisionnement',
        'vente',
        'perte_peremption',
        'casse',
        'retour_fournisseur',
        'inventaire_regularisation',
        'transfert',
        'perte'
    ];

    if (!$produit_id || !in_array($type, $typesValides) || $quantite <= 0) {
        $message = "Données invalides. Vérifiez tous les champs.";
    } else {
        // ✅ Vérifier que le produit appartient bien à l'enseigne
        $stmtProd = $pdo->prepare("SELECT id, nom, quantite FROM produits WHERE id = ? AND enseigne_id = ?");
        $stmtProd->execute([$produit_id, $enseigne_id]);
        $produit = $stmtProd->fetch();

        if (!$produit) {
            $message = "Produit introuvable.";
        } elseif (!in_array($type, ['approvisionnement','retour_fournisseur','inventaire_regularisation']) && $quantite > $produit['quantite']) {
            $message = "Stock insuffisant. Stock actuel : <strong>{$produit['quantite']}</strong> unité(s).";
        } else {
            // ✅ enseigne_id ajouté dans l'INSERT
            $pdo->prepare("
                INSERT INTO mouvements (enseigne_id, produit_id, utilisateur_id, type_mouvement, quantite, commentaire)
                VALUES (?,?,?,?,?,?)
            ")->execute([$enseigne_id, $produit_id, $_SESSION['user_id'], $type, $quantite, $commentaire]);

            // ✅ Message adapté selon le type
            $typesEntree = ['approvisionnement', 'retour_fournisseur', 'inventaire_regularisation'];
            $action  = in_array($type, $typesEntree) ? 'ajouté au' : 'retiré du';
            $message = "{$quantite} unité(s) de <strong>" . h($produit['nom']) . "</strong> $action stock.";
            $success = true;
        }
    }
}

$stmt = $pdo->prepare("SELECT id, nom, quantite FROM produits WHERE enseigne_id = ? ORDER BY nom");
$stmt->execute([$enseigne_id]);
$produits = $stmt->fetchAll();

$stmt = $pdo->prepare("
    SELECT m.date_mouvement, m.type_mouvement, m.quantite, m.commentaire,
           p.nom AS produit_nom,
           CONCAT(u.prenom, ' ', u.nom) AS utilisateur
    FROM mouvements m
    JOIN produits p ON m.produit_id = p.id
    LEFT JOIN utilisateurs u ON m.utilisateur_id = u.id
    WHERE p.enseigne_id = ?
    ORDER BY m.date_mouvement DESC
    LIMIT 50
");
$stmt->execute([$enseigne_id]);
$historique = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mouvements — StockSmart Pro</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
    :root { --red:#e94560; --mid:#64748b; --border:#e2e8f0; --light:#f8fafc; }
    body { font-family:'Inter',system-ui,sans-serif; background:var(--light); color:#0d1117; }

    .msg-success { background:#dcfce7; color:#166534; padding:14px 18px; border-radius:10px; font-size:13px; font-weight:600; margin-bottom:1.5rem; border:1px solid #bbf7d0; }
    .msg-error   { background:#fee2e2; color:#991b1b; padding:14px 18px; border-radius:10px; font-size:13px; font-weight:600; margin-bottom:1.5rem; border:1px solid #fecdd3; }

    .container  { max-width:1100px; margin:2rem auto; padding:0 2rem; }
    .page-title { font-size:20px; font-weight:800; margin-bottom:1.5rem; }
    .grid       { display:grid; grid-template-columns:360px 1fr; gap:1.5rem; }

    .form-card    { background:#fff; border-radius:14px; border:1px solid var(--border); padding:1.5rem; position:sticky; top:75px; }
    .form-card h3 { font-size:15px; font-weight:700; margin-bottom:1.25rem; }

    .field        { margin-bottom:14px; }
    .field label  { display:block; font-size:11px; font-weight:700; color:var(--mid); margin-bottom:7px; text-transform:uppercase; letter-spacing:.4px; }
    .field select,
    .field input  { width:100%; padding:11px 13px; border-radius:9px; border:1px solid var(--border); font-family:inherit; font-size:13px; outline:none; transition:border-color .15s; background:#fff; }
    .field select:focus,
    .field input:focus { border-color:#e94560; }

    optgroup { font-size:11px; font-weight:700; color:var(--mid); text-transform:uppercase; letter-spacing:.4px; }

    .btn-submit       { width:100%; padding:13px; border-radius:10px; border:none; background:#e94560; color:#fff; font-size:14px; font-weight:700; cursor:pointer; font-family:inherit; transition:all .15s; }
    .btn-submit:hover { box-shadow:0 4px 14px rgba(233,69,96,.35); transform:translateY(-1px); }

    .table-card   { background:#fff; border-radius:14px; border:1px solid var(--border); overflow:hidden; }
    .table-header { padding:1.25rem 1.5rem; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
    .table-title  { font-size:15px; font-weight:700; }

    table       { width:100%; border-collapse:collapse; }
    thead th    { background:var(--light); font-size:11px; font-weight:600; color:var(--mid); text-transform:uppercase; letter-spacing:.4px; padding:10px 16px; text-align:left; border-bottom:1px solid var(--border); }
    tbody tr    { border-bottom:1px solid #f5f7fa; }
    tbody tr:last-child { border-bottom:none; }
    tbody tr:hover      { background:#fafbff; }
    tbody td    { padding:12px 16px; font-size:13px; }

    .type-pill  { display:inline-flex; align-items:center; padding:4px 10px; border-radius:10px; font-size:11px; font-weight:700; }

    /* Entrées */
    .type-approvisionnement,
    .type-retour_fournisseur,
    .type-inventaire_regularisation { background:#dcfce7; color:#166534; }

    /* Sorties */
    .type-vente,
    .type-perte,
    .type-perte_peremption,
    .type-casse,
    .type-transfert { background:#fee2e2; color:#991b1b; }

    @media(max-width:800px) {
      .grid { grid-template-columns:1fr; }
      .form-card { position:static; }
    }
  </style>
</head>
<body>
<?php require_once '../_nav.php'; ?>

<div class="container">
  <div class="page-title">Mouvements de stock</div>

  <?php if ($message): ?>
    <div class="<?= $success ? 'msg-success' : 'msg-error' ?>"><?= $message ?></div>
  <?php endif; ?>

  <div class="grid">

    <?php if (canEdit()): ?>
    <div class="form-card">
      <h3>Enregistrer un mouvement</h3>
      <form method="POST">

        <div class="field">
          <label>Produit</label>
          <select name="produit_id" required>
            <option value="">Choisir un produit...</option>
            <?php foreach ($produits as $p): ?>
              <option value="<?= $p['id'] ?>"><?= h($p['nom']) ?> (Stock : <?= $p['quantite'] ?>)</option>
            <?php endforeach; ?>
          </select>
        </div>

        <div class="field">
          <label>Type de mouvement</label>
          <select name="type_mouvement" required>
            <option value="">Choisir...</option>
            <optgroup label="── Entrées">
              <option value="approvisionnement">Approvisionnement</option>
              <option value="retour_fournisseur">Retour fournisseur</option>
              <option value="inventaire_regularisation">Régularisation inventaire</option>
            </optgroup>
            <optgroup label="── Sorties">
              <option value="vente">Vente</option>
              <option value="perte">Perte</option>
              <option value="perte_peremption">Perte — Péremption</option>
              <option value="casse">Casse</option>
              <option value="transfert">Transfert</option>
            </optgroup>
          </select>
        </div>

        <div class="field">
          <label>Quantité</label>
          <input type="number" name="quantite" min="1" placeholder="Ex: 6" required>
        </div>

        <div class="field">
          <label>Commentaire (optionnel)</label>
          <input type="text" name="commentaire" placeholder="Ex: Livraison fournisseur #42">
        </div>

        <button type="submit" class="btn-submit">Enregistrer le mouvement</button>
      </form>
    </div>
    <?php endif; ?>

    <div class="table-card">
      <div class="table-header">
        <div class="table-title">Historique (<?= count($historique) ?>)</div>
      </div>
      <table>
        <thead>
          <tr>
            <th>Date</th>
            <th>Produit</th>
            <th>Type</th>
            <th>Qté</th>
            <th>Employé</th>
            <th>Commentaire</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($historique)): ?>
            <tr>
              <td colspan="6" style="text-align:center;padding:2rem;color:var(--mid);">Aucun mouvement enregistré.</td>
            </tr>
          <?php else: ?>
            <?php foreach ($historique as $m):
              $typesEntree = ['approvisionnement','retour_fournisseur','inventaire_regularisation'];
              $entree = in_array($m['type_mouvement'], $typesEntree);

              $labels = [
                'approvisionnement'        => 'Approvisionnement',
                'retour_fournisseur'       => 'Retour fournisseur',
                'inventaire_regularisation'=> 'Régularisation',
                'vente'                    => 'Vente',
                'perte'                    => 'Perte',
                'perte_peremption'         => 'Péremption',
                'casse'                    => 'Casse',
                'transfert'                => 'Transfert',
              ];
              $label = $labels[$m['type_mouvement']] ?? ucfirst($m['type_mouvement']);
            ?>
            <tr>
              <td style="white-space:nowrap;color:var(--mid);font-size:12px;">
                <?= date('d/m/Y H:i', strtotime($m['date_mouvement'])) ?>
              </td>
              <td style="font-weight:700;"><?= h($m['produit_nom']) ?></td>
              <td>
                <span class="type-pill type-<?= h($m['type_mouvement']) ?>">
                  <?= $label ?>
                </span>
              </td>
              <td style="font-weight:800;color:<?= $entree ? '#16a34a' : '#991b1b' ?>;">
                <?= $entree ? '+' : '-' ?><?= (int)$m['quantite'] ?>
              </td>
              <td style="font-size:12px;"><?= h($m['utilisateur'] ?? 'Système') ?></td>
              <td style="font-size:12px;color:var(--mid);"><?= h($m['commentaire'] ?? '—') ?></td>
            </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>

  </div>
</div>

<footer style="text-align:center;padding:2rem;color:#94a3b8;font-size:12px;">
  © <?= date('Y') ?> StockSmart Pro
</footer>
<script src="../js/script.js"></script>
</body>
</html>
