# RAHETI — Infrastructure Intelligente de Confort Public

## SPÉCIFICATION DE PLATEFORME DIGITALE

Application mobile, plateforme web, tableaux de bord et infrastructure Cloud/IoT

| | |
|---|---|
| **Document** | RAH-DOC-005 |
| **Version** | 1.0 (brouillon — premier jet) |
| **Statut** | Confidentiel |
| **Date** | 27 juillet 2026 |
| **Public** | Équipe produit, développeurs, designers UX, partenaires technologiques |

> **Note** : ce document formalise la spécification fonctionnelle et technique de l'écosystème digital RAHETI, en s'appuyant sur le prototype d'interface déjà produit (`rahati_v2_2.html`) et sur l'Écosystème Produit défini au Livre de Conception (RAH-DOC-003, §2). Les choix d'architecture technique (§7) sont indicatifs et à confirmer avec l'équipe d'ingénierie logicielle retenue.

---

## 0. Objet du document

Cette spécification décrit l'ensemble de la couche digitale RAHETI : l'application mobile grand public, la plateforme web vitrine, les tableaux de bord opérateur et sponsor, et l'infrastructure Cloud/IoT qui les relie à chaque station physique. Elle traduit en exigences fonctionnelles et techniques le prototype d'interface déjà réalisé, et sert de cahier des charges pour le développement.

## 1. Vue d'ensemble de la plateforme

La plateforme RAHETI relie trois types d'utilisateurs à un même socle de données temps réel : l'usager final (application mobile), l'opérateur de terrain (tableau de bord opérateur) et le sponsor ou partenaire (tableau de bord sponsor). Chaque station physique remonte en continu son état via le réseau IoT (voir Livre d'Ingénierie Technique, RAH-DOC-004 §8), ce qui alimente les trois interfaces sans ressaisie manuelle.

| Composant | Utilisateur principal |
|---|---|
| Application mobile | Usager final — recherche, réservation implicite, paiement, navigation |
| Plateforme Web vitrine | Grand public, partenaires potentiels, presse |
| Tableau de bord Opérateur | Équipe technique et exploitation RAHETI |
| Tableau de bord Sponsor | Annonceurs et partenaires de visibilité |
| Plateforme Cloud | Infrastructure partagée — aucun accès direct utilisateur |

## 2. Application mobile — spécification fonctionnelle

### 2.1 Carte temps réel

Écran principal de l'application. Affiche la position de l'usager et l'ensemble des lieux à proximité, codés par couleur selon la typologie déjà établie dans la Brand Identity Guidelines (RAH-DOC-002 §4.2) : vert (WC gratuit), bleu (WC payant), ambre (unité mobile RAHETI), magenta (Slatoki). Chaque lieu est représenté par un pin cliquable ouvrant une fiche lieu (§2.2).

- Barre de recherche en tête d'écran, bilingue FR/AR, avec suggestion de lieux à proximité.
- Filtres rapides sous forme de puces (chips) : Tout / WC Gratuit / WC Payant / Unités RAHETI / Slatoki — sélection multiple possible.
- Recentrage automatique sur la position de l'usager, avec option de verrouillage/déverrouillage du suivi.
- Mode hors connexion : affichage des derniers lieux mis en cache si perte de réseau, avec indicateur de fraîcheur des données.

### 2.2 Fiche lieu

- Nom du lieu (FR + AR), distance, note moyenne (étoiles) et nombre d'avis.
- Statut de disponibilité en temps réel (Libre / Occupé), actualisé par le réseau IoT pour les unités RAHETI, déclaratif/communautaire pour les lieux tiers référencés (mosquées, commerces).
- Type d'accès (gratuit / payant, avec tarif affiché) et moyens de paiement acceptés.
- Tags de qualification : Femmes ✓, Wudu ✓, PMR, Ouvert/Fermé — cohérents avec la palette fonctionnelle de marque.
- Itinéraire en un tap vers l'application de navigation par défaut de l'appareil.

### 2.3 Fonctionnalité Slatoki (صلاتكِ)

Fonctionnalité différenciante de l'application : localisation d'espaces de prière et d'ablution spécifiquement qualifiés pour les femmes, avec une identité visuelle dédiée (magenta) distincte du reste de l'application.

- Boussole Qibla intégrée, orientation permanente vers La Mecque, disponible en widget sur l'écran d'accueil et en plein écran.
- Filtres dédiés : Prière seule / Wudu seul / Prière + Wudu, et distinction mosquées vérifiées avec section femmes confirmée vs espaces génériques.
- Affichage spécifique pour les tentes Slatoki déployées sur les unités mobiles RAHETI : statut déployée/repliée, capacité (nombre de tapis), équipements (éclairage, rideau occultant).
- Onglet dédié dans la barre de navigation basse de l'application (Carte / Slatoki / Urgence / Profil), signe de l'importance stratégique de cette fonctionnalité plutôt qu'un simple filtre secondaire.

### 2.4 Mode Urgence

- Accès en un tap depuis la barre de navigation basse, sans étape intermédiaire.
- Ciblage initial : usagers diabétiques — géolocalisation immédiate du lieu accessible le plus proche, sans dépendre des filtres actifs.
- Remise de 50 % sur les WC payants pour les usagers diabétiques vérifiés — nécessite un mécanisme de vérification (voir §2.6, profil usager) et une intégration avec le système de paiement des lieux partenaires.
- Extension future envisageable à d'autres profils d'urgence (personnes âgées, femmes enceintes) — à cadrer en atelier produit, hors périmètre de la version 1.

### 2.5 Parcours de paiement et déverrouillage (unités RAHETI)

1. L'usager scanne le QR code affiché sur la cabine choisie.
2. L'application identifie la cabine et vérifie sa disponibilité en temps réel.
3. Paiement déclenché si applicable (carte enregistrée, wallet mobile, ou abonnement) ; accès direct si gratuit.
4. Confirmation transmise à la plateforme Cloud, qui envoie l'ordre de déverrouillage à la serrure électronique de la station (voir RAH-DOC-004 §10).
5. Statut de la cabine mis à jour en temps réel pour tous les autres usagers de l'application et sur le tableau de bord opérateur.
6. À la sortie, fermeture et libération automatique du statut, détectées par le capteur de porte.

### 2.6 Profil utilisateur

- Compte optionnel (l'usage de base ne nécessite pas d'inscription obligatoire) pour l'historique, les moyens de paiement enregistrés et les avis laissés.
- Statut « usager vérifié diabétique » activable sur justificatif, conditionnant l'accès au tarif réduit du Mode Urgence (§2.4).
- Historique des lieux visités, favoris, notifications de disponibilité pour un lieu suivi.

### 2.7 Exigences bilingues FR/AR

- Bascule de langue accessible en un tap, mémorisée par utilisateur.
- Support natif de l'affichage RTL (right-to-left) pour l'ensemble des écrans en arabe — pas de simple miroir visuel, mais une adaptation réelle de la mise en page.
- Contenus rédigés nativement dans chaque langue (voir Brand Identity Guidelines RAH-DOC-002 §7), jamais de traduction automatique en production.

## 3. Plateforme Web (vitrine)

- Site public bilingue FR/AR présentant la mission RAHETI, la carte des stations, les liens de téléchargement de l'application (Google Play / App Store) et un point de contact partenaires.
- Sections reflétant le prototype existant : Station (présentation de l'unité mobile), Carte WC (réseau de lieux), Slatoki (fonctionnalité dédiée), App (téléchargement).
- Optimisation pour le référencement naturel sur les recherches locales liées aux sanitaires publics, à la prière et aux points d'eau en Algérie.

## 4. Tableau de bord Opérateur

- Vue consolidée de toutes les stations du réseau : statut batterie, niveau d'eau, occupation par cabine, alertes actives.
- File d'alertes priorisée (incendie et SOS en tête, puis anomalies techniques, puis maintenance préventive) — voir Manuel de Maintenance (RAH-DOC-007) pour les procédures associées.
- Planification et suivi des interventions de maintenance et de vidange/remplissage.
- Historique d'occupation et de fréquentation par station, pour appuyer les décisions de redéploiement (particulièrement utile pour les configurations Event).
- Gestion des accès et rôles pour les équipes multi-sites.

## 5. Tableau de bord Sponsor

- Statistiques de visibilité par station sponsorisée : fréquentation estimée, durée d'exposition, zone géographique.
- Rapports de performance de campagne exportables, alignés sur les niveaux de sponsoring définis au Modèle Économique Détaillé (§3, paliers de sponsoring).
- Visualisation cartographique des stations sponsorisées par le partenaire.
- Accès en lecture seule, strictement cantonné aux données agrégées — aucune donnée personnelle d'usager n'est exposée à ce niveau.

## 6. Plateforme Cloud et intégration IoT

- Point d'agrégation unique de toutes les données remontées par le réseau IoT embarqué (RAH-DOC-004 §8) : occupation, niveaux, état batterie, alertes.
- Orchestration des ordres vers les stations (déverrouillage, activation d'alerte) en réponse aux actions initiées côté application ou tableau de bord.
- Service de notification (statut de disponibilité, alertes opérateur, confirmations de paiement usager).
- Journalisation complète des transactions et des accès, à des fins d'audit et de support usager.

## 7. Architecture technique indicative

Les choix ci-dessous sont des recommandations de cadrage, à valider avec l'équipe d'ingénierie retenue lors du développement.

- **Application mobile** : développement cross-platform (type React Native ou Flutter) pour un déploiement simultané Android/iOS avec une base de code unique.
- **Backend** : API REST ou GraphQL exposée par la plateforme Cloud, architecture par microservices pour séparer gestion des stations, paiement, utilisateurs et notifications.
- **Base de données** : base relationnelle pour les données transactionnelles (usagers, paiements, réservations implicites) + base orientée séries temporelles pour les flux IoT (occupation, capteurs).
- **Communication IoT** : MQTT entre passerelle station et Cloud (voir RAH-DOC-004 §8), webhooks vers le backend applicatif.
- **Paiement** : intégration à un ou plusieurs prestataires de paiement mobile et carte locaux, conformité aux standards de sécurité des données de paiement (PCI-DSS ou équivalent local).
- **Hébergement** : infrastructure Cloud avec présence régionale proche du marché algérien pour la latence, plan de reprise d'activité formalisé.

## 8. Modèle de données — entités principales

| Entité | Attributs clés (indicatif) |
|---|---|
| Station | Identifiant, configuration, position GPS, statut, capacités (cabines, réservoirs) |
| Cabine | Identifiant, station parente, type (H/F/Slatoki/PMR), statut occupation |
| Lieu tiers | Identifiant, nom, type (mosquée/commerce/station-service), tags, note moyenne |
| Utilisateur | Identifiant, préférence de langue, statut vérifié, moyens de paiement, favoris |
| Transaction | Identifiant, utilisateur, cabine/lieu, montant, statut, horodatage |
| Alerte | Identifiant, station, type, sévérité, statut de traitement |
| Sponsor | Identifiant, stations associées, palier, période de campagne |

## 9. Exigences non-fonctionnelles

- Disponibilité cible de la plateforme Cloud : 99,5 % minimum, avec plan de dégradation gracieuse de l'application en cas d'indisponibilité (cache local, mode hors connexion).
- Temps de réponse de la carte et de la fiche lieu : sous 1,5 seconde en conditions de réseau mobile standard.
- Sécurité : chiffrement des données en transit et au repos, authentification forte pour les tableaux de bord opérateur et sponsor.
- Accessibilité de l'application conforme aux bonnes pratiques mobiles usuelles (contraste, taille de police ajustable, compatibilité lecteurs d'écran).
- Conformité à la réglementation locale de protection des données personnelles pour l'ensemble des profils utilisateurs.

## 10. Roadmap fonctionnelle indicative

| Version | Périmètre |
|---|---|
| V1 | Carte, fiche lieu, Slatoki, QR/paiement pour unités RAHETI, profil de base, bilinguisme FR/AR |
| V1.1 | Mode Urgence diabétiques, notifications de disponibilité, avis usagers |
| V2 | Tableau de bord Sponsor complet, extension du Mode Urgence à d'autres profils, programme de fidélité |
| V3 | Ouverture API à des partenaires tiers (mosquées, municipalités) pour l'auto-déclaration de lieux |

## 11. Prochaines étapes

- Atelier de cadrage technique avec l'équipe ou le prestataire de développement pour valider l'architecture proposée au §7.
- Production des maquettes haute-fidélité à partir du prototype existant, en cohérence avec la Brand Identity Guidelines (RAH-DOC-002).
- Sélection des prestataires de paiement mobile locaux et cadrage de l'intégration.
- Définition détaillée du mécanisme de vérification du statut diabétique pour le Mode Urgence, en lien avec les partenaires de santé pertinents.
