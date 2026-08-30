# BeautyLink Africa — MVP stable

BeautyLink Africa est une plateforme africaine de beauté et de bien-être qui relie consommateurs, professionnels beauté, dermatologues, marques et produits.

Cette branche contient la version propre, fonctionnelle et autonome du MVP BeautyLink Africa. Elle fonctionne immédiatement en mode démonstration, sans dépendance npm et sans exposer de secret.

## Fonctionnalités visibles

- dashboard consommateur ;
- Beauty Passport et évolution déclarative ;
- réseau social beauté avec publication, likes, sauvegarde et signalement ;
- annuaire de professionnels et réservation démo ;
- messagerie et appel vidéo simulés ;
- boutique skincare, parfums, grooming et accessoires ;
- Care Cart persistant dans le navigateur ;
- checkout Wave, Orange Money, carte et paiement à la livraison en **sandbox** ;
- routines, rappels et feedbacks ;
- dashboards professionnel, médecin, vendeur et administration ;
- assistant IA non médical avec orientation humaine en cas de signes préoccupants ;
- PWA et fonctionnement hors ligne de base.

## Démarrer

```bash
npm run check
npm run dev
```

Puis ouvrir `http://localhost:5173`.

Aucune installation de dépendances n'est nécessaire. Node.js 20 ou plus récent suffit.

## Construire

```bash
npm run build
npm run preview
```

Le build statique est produit dans `dist/`.

## Supabase

Le site fonctionne sans Supabase grâce au mode démonstration. Pour tester la lecture des produits de la base :

1. copier `config.example.js` vers `config.local.js` localement ;
2. renseigner uniquement la Project URL et la clé publique `anon` dans `config.local.js` ;
3. mettre `mode: 'connected'` ;
4. ne jamais placer de clé `service_role` ou de secret fournisseur dans le navigateur.

Le frontend essaie alors de lire les produits actifs par l'API REST Supabase. En cas d'échec, il revient automatiquement aux données locales.

Les migrations propres sont dans `supabase/migrations/`. Elles sont conçues comme référence versionnée. Avant de les appliquer sur une base déjà remplie, comparer le schéma distant et faire une sauvegarde.

## Sécurité

- aucune clé secrète dans GitHub ;
- données cliniques séparées des données communautaires et commerciales ;
- aucun diagnostic ni prescription par l'IA ;
- aucun paiement réel dans le MVP ;
- aucune commission médicale liée à la vente de produits ;
- fichiers cliniques privés et URLs signées dans l'architecture cible.

## Structure

```text
.
├── index.html
├── assets/
│   ├── app.css
│   └── app.js
├── config.js
├── config.example.js
├── manifest.webmanifest
├── sw.js
├── tools/
│   ├── serve.mjs
│   ├── build.mjs
│   └── check.mjs
├── supabase/
│   ├── config.toml
│   └── migrations/
├── docs/
└── .github/workflows/ci.yml
```

## Limites actuelles

Le MVP constitue une démonstration produit stable et une base de développement versionnée. Les connexions réelles à Wave, Orange Money, cartes, WhatsApp, SMS, WebRTC et modèles IA doivent être réalisées côté serveur via des Edge Functions. Une revue juridique, médicale et sécurité est requise avant toute donnée de santé réelle.


## Historique de réparation

L’état précédent de Bionic est conservé dans la branche `backup/bionic-broken-20260830`. Les fichiers factices, le faux dossier imbriqué et le scaffold Vite incomplet ont été supprimés de la branche active.

Pour un aperçu autonome sans serveur, ouvrir `preview.html`.
