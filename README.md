# Site web de La Mesnie Des Mercenaires

Site vitrine de **La Mesnie Des Mercenaires**, association de reconstitution médiévale spécialisée dans l'archerie.

- **Adresse du site :** https://jelalanne.github.io/lamesniedesmercenaires/
- **Dépôt GitHub :** https://github.com/jelalanne/lamesniedesmercenaires

Le site est volontairement simple : de simples pages HTML/CSS et un peu de JavaScript, sans framework, sans compilation et sans base de données. Tout est gratuit :

| Besoin | Solution | Coût |
|---|---|---|
| Hébergement | [GitHub Pages](https://pages.github.com/) | gratuit |
| Envoi du formulaire de contact par e-mail | [Web3Forms](https://web3forms.com/) | gratuit jusqu'à 250 messages/mois |
| Polices médiévales | [Google Fonts](https://fonts.google.com/) : *MedievalSharp* (titres) et *EB Garamond* (texte), licence libre OFL | gratuit |
| Préparation des photos et mise en ligne | script PowerShell fourni (déjà installé sur Windows) | gratuit |

Aucune bibliothèque JavaScript externe n'est utilisée.

## Sommaire

1. [Pages du site](#pages-du-site)
2. [Structure du projet](#structure-du-projet)
3. [Voir le site sur son ordinateur](#voir-le-site-sur-son-ordinateur)
4. [Modifier le contenu](#modifier-le-contenu)
   - [Réglages généraux](#réglages-généraux)
   - [Textes des pages](#textes-des-pages)
   - [Membres du bureau](#membres-du-bureau)
   - [Prestations](#prestations)
   - [Photos de la galerie](#photos-de-la-galerie)
   - [Logo et couleurs](#logo-et-couleurs)
5. [Formulaire de contact (Web3Forms)](#formulaire-de-contact-web3forms)
6. [Mise en ligne sur GitHub Pages](#mise-en-ligne-sur-github-pages)
   - [Première mise en ligne](#première-mise-en-ligne)
   - [Mettre à jour le site en ligne](#mettre-à-jour-le-site-en-ligne)
7. [Fonctionnalités supplémentaires](#fonctionnalités-supplémentaires)
8. [Avant la première mise en ligne](#avant-la-première-mise-en-ligne)
9. [Limites connues](#limites-connues)

## Pages du site

| Page | Fichier | Contenu |
|---|---|---|
| Accueil | `index.html` | Présentation rapide et liens vers les autres pages |
| L'association | `association.html` | Histoire, pratique de l'archerie, membres du bureau avec photo |
| Prestations | `prestations.html` | Prestations proposées et demande de devis |
| Galerie | `galerie.html` | Photos, agrandissables en plein écran |
| Contact | `contact.html` | Formulaire envoyé par e-mail à l'association |
| Mentions légales | `mentions-legales.html` | Obligatoires en France (lien en pied de page) |
| Page introuvable | `404.html` | Affichée par GitHub Pages pour une adresse inexistante |

## Structure du projet

```
SiteWeb/
├── index.html, association.html, prestations.html,
│   galerie.html, contact.html, mentions-legales.html, 404.html
├── apercu.bat              ← double-clic : prépare les photos et ouvre le site en local
├── deployer.bat            ← double-clic : prépare les photos et publie le site
├── assets/
│   ├── css/style.css       ← mise en page, couleurs, polices
│   └── js/
│       ├── config.js       ← RÉGLAGES : nom, clé du formulaire, réseaux sociaux
│       ├── commun.js       ← en-tête, menu et pied de page de toutes les pages
│       ├── galerie.js      ← affichage de la galerie et visionneuse
│       ├── galerie-data.js ← liste des photos (GÉNÉRÉE par le script, ne pas modifier)
│       └── contact.js      ← envoi du formulaire de contact
├── images/
│   ├── logo.jpg            ← emblème (aussi utilisé comme icône d'onglet)
│   ├── bureau/             ← photos de profil des membres du bureau
│   └── galerie/            ← photos de la galerie
│       ├── legendes.txt    ← légendes des photos (facultatif)
│       └── miniatures/     ← miniatures (GÉNÉRÉES par le script)
└── scripts/
    └── deployer.ps1        ← script de préparation des photos et de mise en ligne
```

## Voir le site sur son ordinateur

- **Double-cliquer sur `apercu.bat`** : le script prépare les photos, met à jour la galerie puis ouvre le site dans le navigateur. Rien n'est publié.
- Ou simplement double-cliquer sur `index.html` (la galerie n'affichera alors pas les photos ajoutées depuis le dernier lancement du script).

Le formulaire de contact fonctionne aussi en local, une fois la clé Web3Forms renseignée.

## Modifier le contenu

Les fichiers `.html`, `.js`, `.css` et `.txt` s'ouvrent avec n'importe quel éditeur de texte (Bloc-notes, ou mieux [Visual Studio Code](https://code.visualstudio.com/), gratuit). Les passages à adapter sont repérés par des commentaires `<!-- À ADAPTER -->` / `<!-- À COMPLÉTER -->` et par des crochets `[…]` dans le texte.

### Réglages généraux

Tout se trouve dans [assets/js/config.js](assets/js/config.js) :

- `nom` : nom affiché dans l'en-tête et le pied de page ;
- `web3formsCle` : clé du formulaire de contact (voir [plus bas](#formulaire-de-contact-web3forms)) ;
- `reseaux` : liens vers les réseaux sociaux, affichés en pied de page et sur la page Contact. Ajouter une ligne `{ nom: "YouTube", url: "https://…" },` pour un nouveau réseau ; mettre `url: ""` pour en masquer un.

Le **menu** (liste des pages) se modifie dans la constante `PAGES` en haut de [assets/js/commun.js](assets/js/commun.js).

### Textes des pages

Les textes s'écrivent directement dans les fichiers `.html`, entre les balises (`<p>…</p>` pour un paragraphe, `<h2>…</h2>` pour un titre). Pour une espace insécable avant `:` `!` `?`, utiliser `&nbsp;` comme dans les textes existants.

### Membres du bureau

Dans [association.html](association.html), chaque membre est un bloc `<article class="carte membre">…</article>` :

1. déposer la photo dans `images/bureau/` (ex. `jean-dupont.jpg`). Format carré de préférence ; le script la réduira automatiquement à 500 px ;
2. dans le bloc du membre, remplacer `images/bureau/silhouette.svg` par `images/bureau/jean-dupont.jpg` ;
3. modifier le nom, le rôle, la description et le texte `alt` de la photo (« Photo de Jean Dupont »).

Pour ajouter un membre, copier/coller un bloc `<article>` complet ; pour en retirer un, supprimer son bloc.

### Prestations

Dans [prestations.html](prestations.html), chaque prestation est un bloc `<article class="carte">…</article>` : même principe que pour le bureau.

### Photos de la galerie

La galerie se met à jour **toute seule** à partir du contenu du dossier `images/galerie/` :

1. **Ajouter** des photos : les copier dans `images/galerie/` (formats `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.svg`). Des photos de téléphone en pleine taille conviennent, le script les réduit.
2. **Retirer** une photo : la supprimer du dossier.
3. **Ordre d'affichage** : ordre alphabétique des noms de fichier. Préfixer par un numéro ou une date pour choisir l'ordre, ex. `01-campement.jpg`, `2025-06-tournoi-de-provins.jpg`.
4. **Légendes** (facultatif) : par défaut, la légende vient du nom du fichier (`2025-06-tournoi-de-provins.jpg` donne « Tournoi de provins »). Pour une légende précise, ajouter une ligne dans [images/galerie/legendes.txt](images/galerie/legendes.txt) :
   ```
   2025-06-tournoi-de-provins.jpg | Tournoi de Provins, juin 2025
   ```
5. Lancer **`apercu.bat`** pour vérifier, puis **`deployer.bat`** pour publier.

> Les trois images `exemple-*.svg` sont des exemples : supprimez-les (ainsi que leurs lignes dans `legendes.txt`) dès que vous ajoutez vos vraies photos.

> Les photos trop grandes sont **réduites sur place** : gardez vos originaux ailleurs (téléphone, Drive…) si vous voulez les conserver en pleine résolution.

### Logo et couleurs

- **Logo** : remplacer `images/logo.jpg` par la nouvelle image en gardant le même nom. Pour un autre format (`.png`, `.svg`), changer `images/logo.jpg` dans toutes les pages `.html` et dans `assets/js/commun.js`.
- **Couleurs et polices** : variables en haut de [assets/css/style.css](assets/css/style.css) (bloc `:root`).

## Formulaire de contact (Web3Forms)

Un site hébergé sur GitHub Pages ne peut pas envoyer d'e-mail lui-même : le formulaire passe par le service gratuit Web3Forms, qui transfère chaque message à l'adresse e-mail de l'association.

1. Aller sur https://web3forms.com/, saisir l'adresse e-mail qui doit **recevoir** les messages et cliquer sur *Create Access Key* (aucun compte nécessaire).
2. Récupérer la clé reçue par e-mail (forme `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
3. La coller dans [assets/js/config.js](assets/js/config.js) à la place de `VOTRE-CLE-WEB3FORMS`.
4. Publier le site (`deployer.bat`) et faire un essai depuis la page Contact.

La clé n'est pas secrète : elle ne permet que d'envoyer des messages à votre adresse, qui elle n'apparaît jamais dans le code du site. Le sujet de l'e-mail reçu indique l'objet choisi et le nom de l'expéditeur ; « Répondre » dans la messagerie répond directement au visiteur.

Pour changer l'adresse de réception, créer une nouvelle clé avec la nouvelle adresse et remplacer l'ancienne dans `config.js`.

## Mise en ligne sur GitHub Pages

### Première mise en ligne

À faire **une seule fois**, sur un ordinateur Windows :

1. **Installer Git** : https://git-scm.com/download/win (options par défaut). Puis, dans PowerShell, indiquer son nom et son e-mail (utilisés pour signer les modifications) :
   ```powershell
   git config --global user.name "Prénom Nom"
   git config --global user.email "adresse@exemple.fr"
   ```
2. **Relier le dossier au dépôt GitHub** : ouvrir PowerShell dans le dossier du site (dans l'explorateur : clic droit dans le dossier > *Ouvrir dans le Terminal*), puis :
   ```powershell
   git init -b main
   git add --all
   git commit -m "Première version du site"
   git remote add origin https://github.com/jelalanne/lamesniedesmercenaires.git
   git push -u origin main
   ```
   Au premier envoi, une fenêtre de connexion à GitHub s'ouvre : se connecter avec le compte propriétaire du dépôt.
3. **Activer GitHub Pages** : sur la page du dépôt, *Settings* > *Pages* > *Build and deployment* > *Source* : **Deploy from a branch**, *Branch* : **main** et **/ (root)**, puis *Save*.
4. Au bout d'une à deux minutes, le site est visible à l'adresse https://jelalanne.github.io/lamesniedesmercenaires/.

> GitHub Pages est gratuit pour un dépôt **public**. Le contenu du dossier (textes, photos) est donc visible de tous sur GitHub, comme sur le site lui-même.

**Pour un autre membre qui reprend la maintenance** : installer Git (étape 1), demander à être ajouté comme collaborateur du dépôt (*Settings* > *Collaborators*), puis récupérer le site avec `git clone https://github.com/jelalanne/lamesniedesmercenaires.git`.

### Mettre à jour le site en ligne

Après toute modification (textes, photos, réglages) : **double-cliquer sur `deployer.bat`**.

Le script :
1. réduit les photos trop grandes (`images/bureau/` et `images/galerie/`) ;
2. crée les miniatures et met à jour la liste des photos de la galerie ;
3. enregistre les modifications (*commit*) et les envoie sur GitHub (*push*) ;
4. GitHub Pages met le site à jour d'ici une à deux minutes.

La fenêtre reste ouverte à la fin : un message vert `Terminé.` confirme la réussite, un message rouge `ERREUR` explique le problème.

Options, depuis PowerShell dans le dossier du site :

```powershell
.\deployer.bat -Message "Ajout des photos du tournoi de juin"   # message de commit personnalisé
.\deployer.bat -SansDeploiement                                  # prépare les photos sans publier
Get-Help .\scripts\deployer.ps1 -Full                            # aide complète du script
```

## Fonctionnalités supplémentaires

- **Préparation automatique des photos** (`scripts/deployer.ps1`) : réduction des photos trop grandes (1600 px pour la galerie, 500 px pour le bureau, réglables en haut du script), redressement des photos prises téléphone tourné, suppression des métadonnées (dont la position GPS) des photos réduites, création des miniatures et suppression de celles des photos retirées.
- **Galerie générée automatiquement** : le script écrit la liste des photos dans `assets/js/galerie-data.js`, avec les légendes de `legendes.txt` ou déduites du nom de fichier. La visionneuse s'utilise à la souris, au doigt ou au clavier (flèches, Échap).
- **Objet du message présélectionné** : un lien vers `contact.html?objet=prestation` (ou `adhesion`, `informations`, `autre`) présélectionne l'objet du formulaire. C'est le cas des boutons « Demander un devis » et « Nous écrire ». Les valeurs possibles sont les attributs `data-raccourci` du menu « Objet » dans `contact.html`.
- **Protection anti-spam** du formulaire : champ piège invisible (filtré par Web3Forms).
- **En-tête et pied de page communs** : générés par `assets/js/commun.js`, donc une modification du menu ou des réseaux s'applique à toutes les pages.
- **Mentions légales** et **page 404** personnalisée.
- **Affichage mobile** : mise en page adaptée aux petits écrans, menu repliable.
- **Agrandissement sur grand écran** : à partir de 1140 px de large, tout le site s'affiche à 150 % (comme un zoom navigateur). Le facteur se règle avec la variable `--zoom` dans `assets/css/style.css`.

## Avant la première mise en ligne

- [ ] Remplacer tous les passages entre crochets `[…]` (`association.html`, `prestations.html`, `mentions-legales.html`).
- [ ] Renseigner les vrais liens des réseaux sociaux et la clé Web3Forms dans `assets/js/config.js`.
- [ ] Ajouter les photos du bureau et de la galerie, supprimer les images d'exemple.
- [x] Remplacer le logo provisoire (fait : `images/logo.jpg`).
- [ ] Relire les textes d'exemple de l'accueil, de l'association et des prestations.

## Limites connues

- **JavaScript requis** pour l'en-tête, le menu, la galerie et le formulaire (activé sur tous les navigateurs courants).
- **Web3Forms gratuit** : 250 messages par mois maximum.
- **Google Fonts** : l'adresse IP des visiteurs est transmise à Google au chargement des polices (mentionné dans les mentions légales). Pour l'éviter, les polices peuvent être téléchargées et hébergées dans le site.
- **Script de photos** : Windows uniquement (utilise PowerShell et les composants graphiques de Windows). Les `.webp`, `.gif` et `.svg` ne sont ni réduits ni miniaturisés : préférer le `.jpg` pour les photos.
- **Miniature pas à jour** : si une photo est remplacée par un fichier de même nom mais plus ancien, sa miniature n'est pas recréée. Il suffit alors de supprimer le dossier `images/galerie/miniatures/` et de relancer le script.
- **Dossier OneDrive** : Git fonctionne dans un dossier synchronisé par OneDrive, mais éviter de modifier le site sur deux ordinateurs en même temps.
