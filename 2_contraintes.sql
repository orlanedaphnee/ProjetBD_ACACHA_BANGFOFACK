USE streamingdb;


ALTER TABLE Formule
  ADD CONSTRAINT CK_FORMULE_NOM CHECK (nom_formule <> ''),
  ADD CONSTRAINT CK_FORMULE_PRIX CHECK (prix_mensuel > 0),
  ADD CONSTRAINT CK_FORMULE_ECRAN CHECK (nb_ecran_max BETWEEN 1 AND 9),
  ADD CONSTRAINT CK_FORMULE_QUALITE CHECK (qualite_max IN ('HD', 'Full HD', '4K'));


ALTER TABLE Compte
  ADD CONSTRAINT CK_COMPTE_EMAIL CHECK (email LIKE '%_@_%._%'),
  ADD CONSTRAINT CK_COMPTE_MDP CHECK (LENGTH(mot_de_passe) >= 8),
  ADD CONSTRAINT CK_COMPTE_DATE CHECK (date_creation >= '2007-01-01');


ALTER TABLE Souscrire
  ADD CONSTRAINT CK_SOUSCRIRE_DATES CHECK (date_fin IS NULL OR date_fin > date_debut),
  ADD CONSTRAINT CK_SOUSCRIRE_ETAT CHECK (etat IN ('actif', 'suspendu', 'résilié')),
  ADD CONSTRAINT CK_SOUSCRIRE_FIN CHECK ((etat = 'résilié' AND date_fin IS NOT NULL)
                                      OR (etat IN ('actif', 'suspendu') AND date_fin IS NULL));


ALTER TABLE Profil
  ADD CONSTRAINT UQ_PROFIL_NOM UNIQUE (id_compte, nom_profil),
  ADD CONSTRAINT CK_PROFIL_NOM CHECK (nom_profil <> ''),
  ADD CONSTRAINT CK_PROFIL_TYPE CHECK (type_profil IN ('standard', 'jeunesse')),
  ADD CONSTRAINT CK_PROFIL_LANGUE CHECK (langue_preferee IN ('fr', 'en', 'es', 'de', 'it', 'pt', 'ar', 'ja', 'ko')),
  ADD CONSTRAINT CK_PROFIL_AGE CHECK (categorie_age_max IN ('7+', '12+', '16+', '18+')),
  ADD CONSTRAINT CK_PROFIL_JEUNESSE CHECK (type_profil = 'standard' OR categorie_age_max IN ('7+', '12+'));


ALTER TABLE Genre
  ADD CONSTRAINT CK_GENRE_NOM CHECK (nom_genre <> '');


ALTER TABLE Contenu
  ADD CONSTRAINT CK_CONTENU_TITRE CHECK (titre <> ''),
  ADD CONSTRAINT CK_CONTENU_TYPE CHECK (type_contenu IN ('film', 'série')),
  ADD CONSTRAINT CK_CONTENU_DUREE CHECK (duree_film IS NULL OR duree_film BETWEEN 1 AND 999),
  ADD CONSTRAINT CK_CONTENU_FILM CHECK ((type_contenu = 'film' AND duree_film IS NOT NULL)
                                     OR (type_contenu = 'série' AND duree_film IS NULL)),
  ADD CONSTRAINT CK_CONTENU_DATE CHECK (date_sortie >= '1900-01-01');


ALTER TABLE Acteur
  ADD CONSTRAINT CK_ACTEUR_NOM CHECK (nom_acteur <> '');

ALTER TABLE Personnage
  ADD CONSTRAINT CK_PERSONNAGE_NOM CHECK (nom_personnage <> '');


ALTER TABLE Visionnage
  ADD CONSTRAINT CK_VISIONNAGE_DUREE CHECK (duree_regardee BETWEEN 1 AND 9999),
  ADD CONSTRAINT CK_VISIONNAGE_APPAREIL CHECK (type_appareil IN ('téléviseur', 'ordinateur', 'smartphone', 'tablette', 'console'));
