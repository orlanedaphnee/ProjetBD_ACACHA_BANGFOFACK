-- Requêtes d'interrogation

USE streamingdb;
SET NAMES utf8mb4;


-- 1. PROJECTIONS ET SÉLECTIONS (tri, DISTINCT, LIKE, IN, BETWEEN)

-- 1.1 Films récents (sortis entre 2022 et 2026) pour la vitrine "Nouveautés",
--     du plus récent au plus ancien.
SELECT titre, date_sortie, duree_film
FROM Contenu
WHERE type_contenu = 'film'
  AND date_sortie BETWEEN '2022-01-01' AND '2026-12-31'
ORDER BY date_sortie DESC;

-- 1.2 Langues préférées (sans doublon) des profils standard, pour savoir
--     dans quelles langues traduire les bannières de la campagne.
SELECT DISTINCT langue_preferee
FROM Profil
WHERE type_profil = 'standard'
ORDER BY langue_preferee;

-- 1.3 Comptes ayant une adresse Gmail (campagne e-mail ciblée par fournisseur).
SELECT id_compte, email, date_creation
FROM Compte
WHERE email LIKE '%@gmail.com'
ORDER BY date_creation;

-- 1.4 Contenus dont le titre commence par "Les " ou contient le mot "Code"
--     (idée de collection thématique).
SELECT id_contenu, titre, type_contenu
FROM Contenu
WHERE titre LIKE 'Les %' OR titre LIKE '%Code%'
ORDER BY titre;

-- 1.5 Caractéristiques des formules "haut de gamme" à mettre en avant.
SELECT nom_formule, prix_mensuel, nb_ecran_max, qualite_max
FROM Formule
WHERE nom_formule IN ('Standard', 'Premium')
ORDER BY prix_mensuel DESC;

-- 1.6 Souscriptions suspendues ou résiliées depuis 2025 (comptes à surveiller
--     pour la fidélisation), les plus récentes en premier.
SELECT id_compte, id_formule, etat, date_debut, date_fin
FROM Souscrire
WHERE etat IN ('suspendu', 'résilié')
  AND (date_fin IS NULL OR date_fin >= '2025-01-01')
ORDER BY date_fin DESC;

-- 1.7 Longues sessions (plus de 90 min) sur grand écran (téléviseur ou console)
--     pendant le mois de septembre 2026.
SELECT id_profil, date_heure_debut, duree_regardee, type_appareil
FROM Visionnage
WHERE type_appareil IN ('téléviseur', 'console')
  AND duree_regardee > 90
  AND date_heure_debut BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59'
ORDER BY duree_regardee DESC;


-- 2. FONCTIONS D'AGRÉGATION (GROUP BY, HAVING)

-- 2.1 Nombre de visionnages et temps total regardé (en heures) par appareil :
--     sur quel support communiquer en priorité ?
SELECT type_appareil,
       COUNT(*)                          AS nb_visionnages,
       ROUND(SUM(duree_regardee) / 60.0, 1) AS heures_regardees
FROM Visionnage
GROUP BY type_appareil
ORDER BY nb_visionnages DESC;

-- 2.2 Comptes "familles" : comptes ayant au moins 4 profils
--     (cibles naturelles de la formule Premium à 4 écrans).
SELECT id_compte, COUNT(*) AS nb_profils
FROM Profil
GROUP BY id_compte
HAVING COUNT(*) >= 4
ORDER BY nb_profils DESC;

-- 2.3 Contenus les plus populaires : ceux vus plus de 10 fois.
SELECT id_contenu, COUNT(*) AS nb_visionnages
FROM Visionnage
GROUP BY id_contenu
HAVING COUNT(*) > 10
ORDER BY nb_visionnages DESC;

-- 2.4 Durée moyenne, minimale et maximale regardée par type de contenu.
SELECT c.type_contenu,
       COUNT(*)                         AS nb_visionnages,
       ROUND(AVG(v.duree_regardee), 1)  AS duree_moyenne,
       MIN(v.duree_regardee)            AS duree_min,
       MAX(v.duree_regardee)            AS duree_max
FROM Visionnage v
JOIN Contenu c ON c.id_contenu = v.id_contenu
GROUP BY c.type_contenu;

-- 2.5 Évolution mensuelle de l'activité en 2026 : mois ayant plus de 15 visionnages.
SELECT EXTRACT(MONTH FROM date_heure_debut) AS mois,
       COUNT(*)                             AS nb_visionnages
FROM Visionnage
WHERE EXTRACT(YEAR FROM date_heure_debut) = 2026
GROUP BY EXTRACT(MONTH FROM date_heure_debut)
HAVING COUNT(*) > 15
ORDER BY mois;

-- 2.6 Revenu mensuel actuel par formule (souscriptions à l'état 'actif' uniquement).
SELECT f.nom_formule,
       COUNT(*)                   AS nb_abonnes,
       SUM(f.prix_mensuel)        AS revenu_mensuel
FROM Souscrire s
JOIN Formule f ON f.id_formule = s.id_formule
WHERE s.etat = 'actif'
GROUP BY f.nom_formule
ORDER BY revenu_mensuel DESC;


-- 3. JOINTURES (internes, externes, auto-jointure, multiples)

-- 3.1 Jointure interne simple : chaque profil avec l'e-mail du compte
--     auquel il appartient (pour personnaliser les e-mails).
SELECT p.nom_profil, p.type_profil, c.email
FROM Profil p
INNER JOIN Compte c ON c.id_compte = p.id_compte
ORDER BY c.email, p.nom_profil;

-- 3.2 Jointure multiple (4 tables) : casting complet des séries
--     (titre, acteur, personnage incarné) pour les visuels de la campagne.
SELECT ct.titre, a.nom_acteur, pe.nom_personnage
FROM Incarner i
JOIN Contenu    ct ON ct.id_contenu    = i.id_contenu
JOIN Acteur     a  ON a.id_acteur      = i.id_acteur
JOIN Personnage pe ON pe.id_personnage = i.id_personnage
WHERE ct.type_contenu = 'série'
ORDER BY ct.titre, a.nom_acteur;

-- 3.3 Jointure externe gauche : tous les contenus avec leur nombre de
--     visionnages, y compris ceux jamais vus (0), contenus à relancer.
SELECT ct.titre, ct.type_contenu, COUNT(v.id_contenu) AS nb_visionnages
FROM Contenu ct
LEFT JOIN Visionnage v ON v.id_contenu = ct.id_contenu
GROUP BY ct.id_contenu, ct.titre, ct.type_contenu
ORDER BY nb_visionnages ASC, ct.titre;

-- 3.4 Auto-jointure (externe) sur Genre : chaque genre avec son genre parent
--     (NULL pour les genres principaux), arborescence du catalogue.
SELECT g.nom_genre AS genre, parent.nom_genre AS genre_parent
FROM Genre g
LEFT JOIN Genre parent ON parent.nom_genre = g.nom_genre_parent
ORDER BY genre_parent, genre;

-- 3.5 Jointure multiple : formule actuellement souscrite par chaque compte
--     (souscription active ou suspendue).
SELECT c.email, f.nom_formule, f.prix_mensuel, s.date_debut, s.etat
FROM Compte c
JOIN Souscrire s ON s.id_compte  = c.id_compte
JOIN Formule   f ON f.id_formule = s.id_formule
WHERE s.etat IN ('actif', 'suspendu')
ORDER BY f.prix_mensuel DESC, c.email;

-- 3.6 Jointure externe + test de NULL : profils qui n'ont encore rien regardé
--     (à relancer avec des recommandations).
SELECT p.id_profil, p.nom_profil, p.type_profil, p.id_compte
FROM Profil p
LEFT JOIN Visionnage v ON v.id_profil = p.id_profil
WHERE v.id_profil IS NULL;

-- 3.7 Jointure multiple + sélection : titres des genres "Animation"
--     effectivement regardés par des profils jeunesse, avec l'appareil utilisé.
SELECT DISTINCT ct.titre, v.type_appareil
FROM Visionnage v
JOIN Profil  p  ON p.id_profil   = v.id_profil
JOIN Contenu ct ON ct.id_contenu = v.id_contenu
JOIN Classer cl ON cl.id_contenu = ct.id_contenu
WHERE p.type_profil = 'jeunesse' AND cl.nom_genre = 'Animation'
ORDER BY ct.titre;


-- 4. REQUÊTES IMBRIQUÉES ((NOT) IN, (NOT) EXISTS, ANY, ALL)

-- 4.1 NOT EXISTS : comptes qui ont tout résilié (aucune souscription active
--     ni suspendue), cible de la campagne "Revenez chez nous".
SELECT c.id_compte, c.email
FROM Compte c
WHERE NOT EXISTS (SELECT *
                  FROM Souscrire s
                  WHERE s.id_compte = c.id_compte
                    AND s.etat IN ('actif', 'suspendu'));

-- 4.2 IN : acteurs ayant joué dans au moins un contenu classé Thriller
--     ou dans un sous-genre du Thriller (Policier, Espionnage).
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

-- 4.3 >= ALL : le (ou les) contenu(s) le(s) plus regardé(s) de la plateforme
--    , tête d'affiche de la campagne.
SELECT ct.titre, COUNT(*) AS nb_visionnages
FROM Visionnage v
JOIN Contenu ct ON ct.id_contenu = v.id_contenu
GROUP BY ct.id_contenu, ct.titre
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM Visionnage
                        GROUP BY id_contenu);

-- 4.4 > ANY : comptes actuellement en formule Standard ou Standard avec publicité qui regardent
--     plus que certains comptes Premium, cibles d'une offre de passage en Premium.
SELECT p.id_compte, SUM(v.duree_regardee) AS minutes_totales
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
ORDER BY minutes_totales DESC;

-- 4.5 NOT IN : contenus jamais regardés par aucun profil, toutes catégories
--     confondues (à retirer ou à remettre en avant).
SELECT id_contenu, titre, type_contenu
FROM Contenu
WHERE id_contenu NOT IN (SELECT id_contenu FROM Visionnage);

-- 4.6 EXISTS (deux fois) : contenus regardés à la fois sur téléviseur et sur smartphone
--     (contenus "multi-écrans" pour la publicité cross-device).
SELECT ct.titre
FROM Contenu ct
WHERE EXISTS (SELECT * FROM Visionnage v
              WHERE v.id_contenu = ct.id_contenu AND v.type_appareil = 'téléviseur')
  AND EXISTS (SELECT * FROM Visionnage v
              WHERE v.id_contenu = ct.id_contenu AND v.type_appareil = 'smartphone')
ORDER BY ct.titre;

-- 4.7 Sous-requête dans le WHERE avec agrégat : films dont la durée est
--     supérieure à la durée moyenne des films.
SELECT titre, duree_film
FROM Contenu
WHERE type_contenu = 'film'
  AND duree_film > (SELECT AVG(duree_film) FROM Contenu WHERE type_contenu = 'film')
ORDER BY duree_film DESC;


-- 5. Requête étudiée dans le README (plans d'exécution)
-- titres des films regardés sur smartphone
SELECT DISTINCT ct.titre
FROM Visionnage v
JOIN Contenu ct ON ct.id_contenu = v.id_contenu
WHERE ct.type_contenu = 'film'
  AND v.type_appareil = 'smartphone';
