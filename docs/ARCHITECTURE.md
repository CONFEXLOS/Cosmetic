# Architecture

## Principe

GitHub est la source de vérité. Le frontend est une PWA statique sans dépendance, afin de garantir un aperçu immédiatement exécutable. Supabase fournit progressivement l'authentification, PostgreSQL, Storage, Realtime et les Edge Functions.

## Domaines de données

- **community** : posts, commentaires, réactions, abonnements et groupes ;
- **commerce** : produits, Care Cart, commandes, paiements et livraisons ;
- **clinical** : consultations, notes, plans de suivi et pièces privées ;
- **identity** : profils, adresses et consentements ;
- **system** : audit, modération, IA et demandes de données.

## Intégrations

Toutes les intégrations sensibles passent par des fonctions serveur. Le navigateur ne reçoit que des clés publiques.
