# Journal de réparation GitHub

## Constat

La branche précédente contenait un faux dossier `feat/beautylink-africa-mvp/`, des migrations SQL réduites à une ligne, un `index.html` référençant un fichier `src/main.tsx` absent et un hook Supabase incomplet.

## Correction

- sauvegarde de l’état cassé dans `backup/bionic-broken-20260830` ;
- remplacement atomique de l’arborescence de `feat/beautylink-africa-mvp` ;
- suppression de tous les fichiers factices et incomplets ;
- ajout d’un MVP PWA fonctionnel ;
- ajout de migrations Supabase versionnées ;
- ajout de contrôles statiques et d’une CI ;
- validation locale avec `npm run check` et `npm run build`.

## Important

Les migrations doivent être comparées au schéma du projet Supabase distant avant application sur une base déjà peuplée.
