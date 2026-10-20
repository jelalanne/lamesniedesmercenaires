<#
.SYNOPSIS
    Prépare les photos du site puis le publie sur GitHub Pages.

.DESCRIPTION
    1. Récupère d'abord les dernières publications (git pull), sauf avec -SansDeploiement.
    2. Réduit les photos trop grandes du bureau (images/bureau) et de la galerie (images/galerie).
    3. Crée les miniatures de la galerie (images/galerie/miniatures) et supprime celles des photos retirées.
    4. Régénère la liste des photos de la page Galerie (assets/js/galerie-data.js), avec les
       légendes de images/galerie/legendes.txt ou, à défaut, déduites du nom de chaque fichier.
    5. Publie le site sur GitHub : git add, git commit, git pull puis git push (sauf avec -SansDeploiement).
       Sur une clé USB préparée par preparer-cle.ps1, utilise Git portable et demande le mot de passe
       qui déchiffre le jeton GitHub de la Mesnie.

    Les photos trop grandes sont réduites SUR PLACE : gardez vos originaux ailleurs si besoin.
    Seuls les .jpg, .jpeg et .png sont réduits ; les .webp, .gif et .svg sont utilisés tels quels.

.PARAMETER SansDeploiement
    Prépare les photos et la galerie sans rien publier.

.PARAMETER Apercu
    Ouvre le site dans le navigateur à la fin.

.PARAMETER Message
    Message du commit. Par défaut : "Mise à jour du site du <date et heure>".

.EXAMPLE
    .\scripts\deployer.ps1
    Prépare les photos puis publie le site.

.EXAMPLE
    .\scripts\deployer.ps1 -SansDeploiement -Apercu
    Prépare les photos et ouvre le site en local, sans le publier (ce que fait apercu.bat).

.EXAMPLE
    .\scripts\deployer.ps1 -Message "Ajout des photos du tournoi de juin"
    Publie avec un message de commit personnalisé.
#>
[CmdletBinding()]
param(
    [switch]$SansDeploiement,
    [switch]$Apercu,
    [string]$Message = ''
)

$ErrorActionPreference = 'Stop'

# --- Réglages -----------------------------------------------------------------
$TailleMaxGalerie = 1600   # plus grand côté des photos de la galerie, en pixels
$TailleMiniature  = 480    # plus grand côté des miniatures de la galerie
$TailleMaxBureau  = 500    # plus grand côté des photos de profil du bureau
$QualiteJpeg      = 82     # qualité JPEG des images réduites (0 à 100)

$Racine            = Split-Path -Parent $PSScriptRoot
$DossierBureau     = Join-Path $Racine 'images\bureau'
$DossierGalerie    = Join-Path $Racine 'images\galerie'
$DossierMiniatures = Join-Path $DossierGalerie 'miniatures'
$FichierLegendes   = Join-Path $DossierGalerie 'legendes.txt'
$FichierDonnees    = Join-Path $Racine 'assets\js\galerie-data.js'
$FichierJeton      = Join-Path $Racine '.cle\jeton.json'

# Git portable de la clé USB s'il existe, sinon le Git installé sur le PC
$GitPortable = Join-Path $Racine 'outils\git\cmd\git.exe'
$Git = if (Test-Path -LiteralPath $GitPortable) { $GitPortable } else { 'git' }

# Autorise Git à travailler dans ce dossier même si son propriétaire est invérifiable
# (cas d'une clé USB en FAT/exFAT). Réglage transmis à git par variables d'environnement.
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = '*'

. (Join-Path $PSScriptRoot 'identifiants.ps1')

$ExtensionsReductibles = @('.jpg', '.jpeg', '.png')
$ExtensionsAcceptees   = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.svg')

# --- Fonctions ----------------------------------------------------------------

function Write-Etape {
    <#
    .SYNOPSIS
        Affiche le titre d'une étape du script.
    #>
    param([string]$Texte)
    Write-Host ''
    Write-Host "==> $Texte" -ForegroundColor Yellow
}

function Set-OrientationNormale {
    <#
    .SYNOPSIS
        Redresse une image selon son orientation EXIF (photos prises au téléphone tenu de côté).
    .PARAMETER Image
        Image chargée avec System.Drawing ; elle est modifiée directement.
    #>
    param([System.Drawing.Image]$Image)

    if ($Image.PropertyIdList -notcontains 0x0112) { return }
    $valeur = $Image.GetPropertyItem(0x0112).Value
    $orientation = if ($valeur[0] -ne 0) { [int]$valeur[0] } else { [int]$valeur[1] }

    $rotation = switch ($orientation) {
        2 { 'RotateNoneFlipX' }
        3 { 'Rotate180FlipNone' }
        4 { 'Rotate180FlipX' }
        5 { 'Rotate90FlipX' }
        6 { 'Rotate90FlipNone' }
        7 { 'Rotate270FlipX' }
        8 { 'Rotate270FlipNone' }
        default { $null }
    }
    if ($rotation) { $Image.RotateFlip([System.Drawing.RotateFlipType]$rotation) }
}

function Test-ImageTropGrande {
    <#
    .SYNOPSIS
        Indique si le plus grand côté d'une image dépasse une taille donnée.
    .PARAMETER Chemin
        Chemin complet de l'image.
    .PARAMETER TailleMax
        Taille maximale en pixels.
    .OUTPUTS
        System.Boolean
    #>
    param([string]$Chemin, [int]$TailleMax)

    $image = [System.Drawing.Image]::FromFile($Chemin)
    try {
        return ([Math]::Max($image.Width, $image.Height) -gt $TailleMax)
    } finally {
        $image.Dispose()
    }
}

function Save-ImageReduite {
    <#
    .SYNOPSIS
        Enregistre une copie réduite et redressée d'une image (JPEG ou PNG selon l'extension).
    .DESCRIPTION
        Les métadonnées (EXIF, position GPS...) ne sont pas conservées.
        Source et Destination peuvent être le même fichier.
    .PARAMETER Source
        Chemin de l'image d'origine.
    .PARAMETER Destination
        Chemin du fichier à écrire (remplacé s'il existe).
    .PARAMETER TailleMax
        Plus grand côté souhaité en pixels ; une image plus petite n'est pas agrandie.
    #>
    param([string]$Source, [string]$Destination, [int]$TailleMax)

    $temporaire = "$Destination.tmp"
    $image = [System.Drawing.Image]::FromFile($Source)
    try {
        Set-OrientationNormale $image
        $ratio = [Math]::Min(1.0, $TailleMax / [double][Math]::Max($image.Width, $image.Height))
        $largeur = [Math]::Max(1, [int][Math]::Round($image.Width * $ratio))
        $hauteur = [Math]::Max(1, [int][Math]::Round($image.Height * $ratio))

        $bitmap = New-Object System.Drawing.Bitmap -ArgumentList $largeur, $hauteur
        try {
            $graphique = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphique.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphique.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphique.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphique.DrawImage($image, 0, 0, $largeur, $hauteur)
            } finally {
                $graphique.Dispose()
            }

            # Écrit d'abord dans un fichier temporaire : la source reste verrouillée tant qu'elle est ouverte
            if ([IO.Path]::GetExtension($Destination).ToLowerInvariant() -eq '.png') {
                $bitmap.Save($temporaire, [System.Drawing.Imaging.ImageFormat]::Png)
            } else {
                $bitmap.Save($temporaire, $script:EncodeurJpeg, $script:ParametresJpeg)
            }
        } finally {
            $bitmap.Dispose()
        }
    } finally {
        $image.Dispose()
    }
    Move-Item -LiteralPath $temporaire -Destination $Destination -Force
}

function Optimize-Dossier {
    <#
    .SYNOPSIS
        Réduit sur place les images .jpg/.jpeg/.png d'un dossier qui dépassent une taille donnée.
    .PARAMETER Dossier
        Dossier à traiter (non récursif). Ignoré s'il n'existe pas.
    .PARAMETER TailleMax
        Plus grand côté autorisé en pixels.
    #>
    param([string]$Dossier, [int]$TailleMax)

    if (-not (Test-Path -LiteralPath $Dossier)) { return }
    $fichiers = @(Get-ChildItem -LiteralPath $Dossier -File |
        Where-Object { $ExtensionsReductibles -contains $_.Extension.ToLowerInvariant() })

    $nombre = 0
    foreach ($fichier in $fichiers) {
        try {
            if (Test-ImageTropGrande -Chemin $fichier.FullName -TailleMax $TailleMax) {
                Save-ImageReduite -Source $fichier.FullName -Destination $fichier.FullName -TailleMax $TailleMax
                Write-Host "  Photo réduite : $($fichier.Name)"
                $nombre++
            }
        } catch {
            Write-Warning "Impossible de traiter $($fichier.Name) : $($_.Exception.Message)"
        }
    }
    if ($nombre -eq 0) { Write-Host '  Aucune photo à réduire.' }
}

function Get-Legendes {
    <#
    .SYNOPSIS
        Lit le fichier legendes.txt de la galerie.
    .OUTPUTS
        Hashtable : nom de fichier -> légende (vide si le fichier n'existe pas).
    #>
    $legendes = @{}
    if (-not (Test-Path -LiteralPath $FichierLegendes)) { return $legendes }

    foreach ($ligne in Get-Content -LiteralPath $FichierLegendes -Encoding UTF8) {
        $ligne = $ligne.Trim()
        if (-not $ligne -or $ligne.StartsWith('#')) { continue }
        $morceaux = $ligne -split '\|', 2
        if ($morceaux.Count -eq 2) { $legendes[$morceaux[0].Trim()] = $morceaux[1].Trim() }
    }
    return $legendes
}

function Get-LegendeParDefaut {
    <#
    .SYNOPSIS
        Déduit une légende du nom d'un fichier.
    .EXAMPLE
        Get-LegendeParDefaut '2025-06-tournoi-de-provins.jpg'   # renvoie "Tournoi de provins"
    #>
    param([string]$NomFichier)

    $texte = [IO.Path]::GetFileNameWithoutExtension($NomFichier)
    $texte = $texte -replace '^[\d\s_-]+', ''          # retire le numéro ou la date de tête
    $texte = ($texte -replace '[_-]+', ' ').Trim()     # tirets et soulignés deviennent des espaces
    if (-not $texte) { return '' }
    return $texte.Substring(0, 1).ToUpper() + $texte.Substring(1)
}

function Update-Galerie {
    <#
    .SYNOPSIS
        Met à jour les miniatures et régénère assets/js/galerie-data.js.
    .DESCRIPTION
        Les photos sont affichées dans l'ordre alphabétique de leur nom de fichier.
        Une miniature n'est recréée que si elle manque ou si la photo est plus récente.
    .OUTPUTS
        System.Int32 : nombre de photos dans la galerie.
    #>
    if (-not (Test-Path -LiteralPath $DossierMiniatures)) {
        New-Item -ItemType Directory -Path $DossierMiniatures | Out-Null
    }

    $legendes = Get-Legendes
    $photos = @(Get-ChildItem -LiteralPath $DossierGalerie -File |
        Where-Object { $ExtensionsAcceptees -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object Name)

    # Supprime les miniatures des photos retirées de la galerie
    $noms = @($photos | ForEach-Object { $_.Name })
    foreach ($miniature in @(Get-ChildItem -LiteralPath $DossierMiniatures -File)) {
        if ($noms -notcontains $miniature.Name) {
            Remove-Item -LiteralPath $miniature.FullName
            Write-Host "  Miniature supprimée : $($miniature.Name)"
        }
    }

    $entrees = @(foreach ($photo in $photos) {
        $nomEncode = [Uri]::EscapeDataString($photo.Name)
        $cheminMiniature = Join-Path $DossierMiniatures $photo.Name
        $urlMiniature = "images/galerie/$nomEncode"

        # Les formats non réductibles (svg, webp, gif) servent eux-mêmes de miniature
        if ($ExtensionsReductibles -contains $photo.Extension.ToLowerInvariant()) {
            $aJour = (Test-Path -LiteralPath $cheminMiniature) -and
                ((Get-Item -LiteralPath $cheminMiniature).LastWriteTime -ge $photo.LastWriteTime)
            if (-not $aJour) {
                try {
                    Save-ImageReduite -Source $photo.FullName -Destination $cheminMiniature -TailleMax $TailleMiniature
                    Write-Host "  Miniature créée : $($photo.Name)"
                } catch {
                    Write-Warning "Miniature impossible pour $($photo.Name) : $($_.Exception.Message)"
                }
            }
            if (Test-Path -LiteralPath $cheminMiniature) { $urlMiniature = "images/galerie/miniatures/$nomEncode" }
        }

        $legende = if ($legendes.ContainsKey($photo.Name)) { $legendes[$photo.Name] } else { Get-LegendeParDefaut $photo.Name }

        [pscustomobject]@{
            image     = "images/galerie/$nomEncode"
            miniature = $urlMiniature
            legende   = $legende
        }
    })

    $json = if ($entrees.Count -eq 0) { '[]' } else { ConvertTo-Json -InputObject $entrees -Depth 3 }
    $contenu = "/* Fichier généré automatiquement par scripts/deployer.ps1 : ne pas le modifier à la main. */`r`n" +
        "window.GALERIE_PHOTOS = $json;`r`n"
    [IO.File]::WriteAllText($FichierDonnees, $contenu, (New-Object System.Text.UTF8Encoding -ArgumentList $false))

    return $photos.Count
}

function Invoke-Git {
    <#
    .SYNOPSIS
        Lance une commande git dans le dossier du site et s'arrête en cas d'échec.
    .EXAMPLE
        Invoke-Git status
    #>
    & $Git -C $Racine @args
    if ($LASTEXITCODE -ne 0) { throw "La commande 'git $($args -join ' ')' a échoué (code $LASTEXITCODE)." }
}

function Set-AuthentificationGitHub {
    <#
    .SYNOPSIS
        Sur une clé USB préparée par preparer-cle.ps1 : demande le mot de passe, déchiffre le
        jeton GitHub et le transmet à git pour la durée du script (variables d'environnement).
        Ne fait rien si .cle\jeton.json n'existe pas (git utilise alors les identifiants du PC).
    #>
    if (-not (Test-Path -LiteralPath $FichierJeton)) { return }

    for ($essai = 1; $essai -le 3; $essai++) {
        $jeton = Unprotect-Jeton -MotDePasse (Read-MotDePasse -Invite '  Mot de passe de publication') -Fichier $FichierJeton
        if ($jeton) { break }
        Write-Host '  Mot de passe incorrect.' -ForegroundColor Yellow
    }
    if (-not $jeton) { throw 'Mot de passe incorrect : rien n''a été publié.' }

    # En-tête d'authentification HTTPS ajouté par git à chaque échange avec GitHub
    $base64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$jeton"))
    $env:GIT_CONFIG_COUNT = '2'
    $env:GIT_CONFIG_KEY_1 = 'http.https://github.com/.extraheader'
    $env:GIT_CONFIG_VALUE_1 = "AUTHORIZATION: basic $base64"
}

function Sync-Site {
    <#
    .SYNOPSIS
        Vérifie Git, prépare l'accès à GitHub puis récupère les dernières publications (git pull),
        avant toute modification des photos.
    #>
    if (-not (Get-Command $Git -ErrorAction SilentlyContinue)) {
        throw "Git n'est pas installé. Voir la section 'Première mise en ligne' du README."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Racine '.git'))) {
        throw "Ce dossier n'est pas encore relié à GitHub. Voir la section 'Première mise en ligne' du README."
    }
    Set-AuthentificationGitHub

    # Récupère les publications faites depuis une autre clé ou un autre PC
    Invoke-GitPull
}

function Invoke-GitPull {
    <#
    .SYNOPSIS
        git pull --rebase qui résout seul les conflits en gardant les modifications locales.
    .DESCRIPTION
        Les modifications non enregistrées sont mises de côté (autostash) puis réappliquées.
        En cas de conflit :
          - pendant le rebase : il est annulé puis relancé avec -X theirs (dans un rebase,
            "theirs" désigne les commits locaux rejoués) ;
          - à la réapplication des modifications non enregistrées : la version locale
            (celle mise de côté) est gardée pour chaque fichier en conflit.
    .EXAMPLE
        Invoke-GitPull
    #>
    & $Git -C $Racine pull --rebase --autostash
    if ($LASTEXITCODE -eq 0 -and -not (Get-FichiersEnConflit)) { return }

    if (Test-Path -LiteralPath (Join-Path $Racine '.git\rebase-merge')) {
        Write-Host '  Conflit avec les dernières publications : les modifications locales sont gardées.' -ForegroundColor Yellow
        & $Git -C $Racine rebase --abort
        Invoke-Git pull --rebase --autostash -X theirs
    }

    # Conflit à la réapplication des modifications mises de côté : on garde la version locale
    $conflits = Get-FichiersEnConflit
    if ($conflits) {
        Write-Host '  Conflit sur des fichiers modifiés : la version locale est gardée.' -ForegroundColor Yellow
        foreach ($fichier in $conflits) { Invoke-Git checkout --theirs -- $fichier }
        Invoke-Git reset --quiet
        & $Git -C $Racine stash drop --quiet
    }
}

function Get-FichiersEnConflit {
    <#
    .SYNOPSIS
        Liste les fichiers en conflit dans le dossier du site.
    .OUTPUTS
        Chemins relatifs des fichiers en conflit (vide s'il n'y en a pas).
    #>
    & $Git -C $Racine diff --name-only --diff-filter=U
}

function Publish-Site {
    <#
    .SYNOPSIS
        Enregistre toutes les modifications (commit) puis les envoie sur GitHub (pull puis push).
    #>
    Invoke-Git add --all
    $modifications = & $Git -C $Racine status --porcelain
    if ($modifications) {
        $texte = if ($Message) { $Message } else { "Mise à jour du site du $(Get-Date -Format 'dd/MM/yyyy HH:mm')" }
        Invoke-Git commit "--message=$texte"
    } else {
        Write-Host '  Aucune modification à enregistrer.'
    }

    # Nouveau pull juste avant l'envoi, au cas où quelqu'un aurait publié entre-temps
    Invoke-GitPull
    # Envoie aussi les éventuels commits restés en attente d'un envoi précédent
    Invoke-Git push
    Write-Host "  Site envoyé sur GitHub : il sera en ligne d'ici une à deux minutes."
}

# --- Programme principal ------------------------------------------------------

try {
    Add-Type -AssemblyName System.Drawing
    $EncodeurJpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
    $ParametresJpeg = New-Object System.Drawing.Imaging.EncoderParameters -ArgumentList 1
    $ParametresJpeg.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter -ArgumentList ([System.Drawing.Imaging.Encoder]::Quality), ([long]$QualiteJpeg)

    if (-not $SansDeploiement) {
        Write-Etape 'Récupération des dernières modifications'
        Sync-Site
    }

    Write-Etape 'Photos du bureau'
    Optimize-Dossier -Dossier $DossierBureau -TailleMax $TailleMaxBureau

    Write-Etape 'Photos de la galerie'
    Optimize-Dossier -Dossier $DossierGalerie -TailleMax $TailleMaxGalerie

    Write-Etape 'Miniatures et liste de la galerie'
    $nombrePhotos = Update-Galerie
    Write-Host "  $nombrePhotos photo(s) dans la galerie."

    if (-not $SansDeploiement) {
        Write-Etape 'Publication sur GitHub'
        Publish-Site
    }

    if ($Apercu) {
        Start-Process -FilePath (Join-Path $Racine 'index.html')
    }

    Write-Host ''
    Write-Host 'Terminé.' -ForegroundColor Green
} catch {
    Write-Host ''
    Write-Host "ERREUR : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
