# Supabase

Ordre d'application sur un projet **neuf** :

1. `000_preflight.sql`
2. `001_schema.sql`
3. `002_auth_and_rls.sql`
4. `003_storage.sql`
5. `004_seed.sql`

Ne pas appliquer aveuglément ces migrations sur une base existante qui contient déjà des tables BeautyLink. Comparer d'abord le schéma distant, sauvegarder la base et préparer une migration de réconciliation.

Les clés `service_role`, paiements, IA et messagerie ne doivent jamais être exposées dans le frontend.
