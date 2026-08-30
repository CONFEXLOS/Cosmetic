# Sécurité

1. RLS activée sur toutes les tables privées.
2. Les utilisateurs accèdent à leurs propres données via `current_profile_id()`.
3. Les professionnels accèdent seulement à leurs données ou aux ressources explicitement partagées.
4. Les notes cliniques privées ne sont pas accessibles au CRM commercial.
5. Les buckets cliniques et privés ne sont jamais publics.
6. Les secrets de paiement, IA, e-mail, WhatsApp et service role restent côté serveur.
7. Toute opération sensible doit alimenter `audit_logs`.
8. Des tests négatifs RLS doivent accompagner chaque évolution du schéma.
