USE streamingdb;
SET NAMES utf8mb4;

-- 1. Projections et sélections

-- 1.1 films sortis entre 2022 et 2026
SELECT titre, date_sortie, duree_film
FROM Contenu
WHERE type_contenu = 'film'
  AND date_sortie BETWEEN '2022-01-01' AND '2026-12-31'
ORDER BY date_sortie DESC;

-- 1.2 langues des profils standard
SELECT DISTINCT langue_preferee
FROM Profil
WHERE type_profil = 'standard'
ORDER BY langue_preferee;

-- 1.3 comptes avec une adresse gmail
SELECT id_compte, email, date_creation
FROM Compte
WHERE email LIKE '%@gmail.com'
ORDER BY date_creation;

-- 1.4 souscriptions suspendues ou résiliées depuis 2025
SELECT id_compte, id_formule, etat, date_debut, date_fin
FROM Souscrire
WHERE etat IN ('suspendu', 'résilié')
  AND (date_fin IS NULL OR date_fin >= '2025-01-01')
ORDER BY date_fin DESC;

-- 1.5 visionnages de plus de 90 min sur téléviseur ou console en septembre 2026
SELECT id_profil, date_heure_debut, duree_regardee, type_appareil
FROM Visionnage
WHERE type_appareil IN ('téléviseur', 'console')
  AND duree_regardee > 90
  AND date_heure_debut BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59'
ORDER BY duree_regardee DESC;


-- 2. Agrégations

-- 2.1 nombre de visionnages et heures regardées par appareil
SELECT type_appareil, COUNT(*) AS nb_visionnages, ROUND(SUM(duree_regardee) / 60.0, 1) AS heures
FROM Visionnage
GROUP BY type_appareil
ORDER BY nb_visionnages DESC;

-- 2.2 comptes qui ont au moins 4 profils
SELECT id_compte, COUNT(*) AS nb_profils
FROM Profil
GROUP BY id_compte
HAVING COUNT(*) >= 4
ORDER BY nb_profils DESC;

-- 2.3 durée moyenne, min et max regardée par type de contenu
SELECT c.type_contenu, COUNT(*) AS nb_visionnages, ROUND(AVG(v.duree_regardee), 1) AS moyenne,
       MIN(v.duree_regardee) AS mini, MAX(v.duree_regardee) AS maxi
FROM Visionnage v
JOIN Contenu c ON c.id_contenu = v.id_contenu
GROUP BY c.type_contenu;

-- 2.4 mois de 2026 avec plus de 15 visionnages
SELECT EXTRACT(MONTH FROM date_heure_debut) AS mois, COUNT(*) AS nb_visionnages
FROM Visionnage
WHERE EXTRACT(YEAR FROM date_heure_debut) = 2026
GROUP BY EXTRACT(MONTH FROM date_heure_debut)
HAVING COUNT(*) > 15
ORDER BY mois;

-- 2.5 nombre d'abonnés actifs et revenu mensuel par formule
SELECT f.nom_formule, COUNT(*) AS nb_abonnes, SUM(f.prix_mensuel) AS revenu
FROM Souscrire s
JOIN Formule f ON f.id_formule = s.id_formule
WHERE s.etat = 'actif'
GROUP BY f.nom_formule
ORDER BY revenu DESC;


-- 3. Jointures

-- 3.1 pour chaque série : acteur et personnage joué (4 tables)
SELECT ct.titre, a.nom_acteur, pe.nom_personnage
FROM Incarner i
JOIN Contenu ct ON ct.id_contenu = i.id_contenu
JOIN Acteur a ON a.id_acteur = i.id_acteur
JOIN Personnage pe ON pe.id_personnage = i.id_personnage
WHERE ct.type_contenu = 'série'
ORDER BY ct.titre, a.nom_acteur;

-- 3.2 nombre de visionnages de chaque contenu, même ceux jamais vus
SELECT ct.titre, ct.type_contenu, COUNT(v.id_contenu) AS nb_visionnages
FROM Contenu ct
LEFT JOIN Visionnage v ON v.id_contenu = ct.id_contenu
GROUP BY ct.id_contenu, ct.titre, ct.type_contenu
ORDER BY nb_visionnages, ct.titre;

-- 3.3 chaque genre avec son genre parent (auto-jointure)
SELECT g.nom_genre AS genre, parent.nom_genre AS genre_parent
FROM Genre g
LEFT JOIN Genre parent ON parent.nom_genre = g.nom_genre_parent
ORDER BY genre_parent, genre;

-- 3.4 profils qui n'ont rien regardé
SELECT p.id_profil, p.nom_profil, p.type_profil, p.id_compte
FROM Profil p
LEFT JOIN Visionnage v ON v.id_profil = p.id_profil
WHERE v.id_profil IS NULL;

-- 3.5 contenus d'animation regardés par des profils jeunesse
SELECT DISTINCT ct.titre, v.type_appareil
FROM Visionnage v
JOIN Profil p ON p.id_profil = v.id_profil
JOIN Contenu ct ON ct.id_contenu = v.id_contenu
JOIN Classer cl ON cl.id_contenu = ct.id_contenu
WHERE p.type_profil = 'jeunesse' AND cl.nom_genre = 'Animation'
ORDER BY ct.titre;


-- 4. Requêtes imbriquées

-- 4.1 comptes sans souscription active ni suspendue
SELECT c.id_compte, c.email
FROM Compte c
WHERE NOT EXISTS (SELECT *
                  FROM Souscrire s
                  WHERE s.id_compte = c.id_compte
                    AND s.etat IN ('actif', 'suspendu'));

-- 4.2 acteurs qui ont joué dans un thriller (ou un sous-genre du thriller)
SELECT nom_acteur
FROM Acteur
WHERE id_acteur IN (SELECT i.id_acteur
                    FROM Incarner i
                    WHERE i.id_contenu IN (SELECT cl.id_contenu
                                           FROM Classer cl
                                           WHERE cl.nom_genre = 'Thriller'
                                              OR cl.nom_genre IN (SELECT nom_genre
                                                                  FROM Genre
                                                                  WHERE nom_genre_parent = 'Thriller')))
ORDER BY nom_acteur;

-- 4.3 contenu le plus regardé
SELECT ct.titre, COUNT(*) AS nb_visionnages
FROM Visionnage v
JOIN Contenu ct ON ct.id_contenu = v.id_contenu
GROUP BY ct.id_contenu, ct.titre
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM Visionnage
                        GROUP BY id_contenu);

-- 4.4 comptes Standard qui regardent plus qu'au moins un compte Premium
SELECT p.id_compte, SUM(v.duree_regardee) AS minutes
FROM Visionnage v
JOIN Profil p ON p.id_profil = v.id_profil
WHERE p.id_compte IN (SELECT s.id_compte
                      FROM Souscrire s
                      JOIN Formule f ON f.id_formule = s.id_formule
                      WHERE s.etat = 'actif'
                        AND f.nom_formule IN ('Standard avec publicité', 'Standard'))
GROUP BY p.id_compte
HAVING SUM(v.duree_regardee) > ANY (SELECT SUM(v2.duree_regardee)
                                    FROM Visionnage v2
                                    JOIN Profil p2 ON p2.id_profil = v2.id_profil
                                    WHERE p2.id_compte IN (SELECT s2.id_compte
                                                           FROM Souscrire s2
                                                           JOIN Formule f2 ON f2.id_formule = s2.id_formule
                                                           WHERE s2.etat = 'actif'
                                                             AND f2.nom_formule = 'Premium')
                                    GROUP BY p2.id_compte)
ORDER BY minutes DESC;

-- 4.5 contenus jamais regardés
SELECT id_contenu, titre, type_contenu
FROM Contenu
WHERE id_contenu NOT IN (SELECT id_contenu FROM Visionnage);


-- 5. Requête utilisée pour l'étude des plans d'exécution (README)
-- titres des films regardés sur smartphone
SELECT DISTINCT ct.titre
FROM Visionnage v
JOIN Contenu ct ON ct.id_contenu = v.id_contenu
WHERE ct.type_contenu = 'film'
  AND v.type_appareil = 'smartphone';