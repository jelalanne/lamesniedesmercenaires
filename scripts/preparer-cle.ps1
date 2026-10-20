<#
.SYNOPSIS
    Prépare une clé USB pour que le bureau puisse publier le site sans rien installer.

.DESCRIPTION
    Script guidé, sans paramètre, lancé par un double-clic sur preparer-cle.bat :
      1. propose les clés USB branchées et fait choisir la bonne ;
      2. télécharge Git portable (dernière version, depuis GitHub) ;
      3. demande le jeton GitHub de la Mesnie et vérifie qu'il permet de publier ;
      4. demande le mot de passe de publication (deux fois) ;
      5. remplit la clé.

    Contenu créé à la racine de la clé :
      - Code Source Site Web\   le site (git clone), Git portable (outils\git) et le jeton
                                chiffré (.cle\jeton.json) ;
      - Photos de la galerie    raccourci vers Code Source Site Web\images\galerie ;
      - Photos du bureau        raccourci vers Code Source Site Web\images\bureau ;
      - Publier le site.bat     lance scripts\deployer.ps1 ;
      - Mode d'emploi.pdf       copie de scripts\cle\Mode d'emploi.pdf.

    Les raccourcis utilisent un chemin relatif : ils fonctionnent quelle que soit la lettre de la clé.

.EXAMPLE
    Double-cliquer sur preparer-cle.bat, à la racine du site.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
. (Join-Path $PSScriptRoot 'identifiants.ps1')

$Proprietaire = 'lamesniedesmercenaires'
$NomDepot     = 'lamesniedesmercenaires'
$Depot        = "https://github.com/$Proprietaire/$NomDepot.git"
$NomAuteur    = 'La Mesnie Des Mercenaires'
$EmailAuteur  = 'lamesniedesmercenaires@users.noreply.github.com'
$NomDossier   = 'Code Source Site Web'

# --- Affichage ----------------------------------------------------------------

function Write-Titre {
    <#
    .SYNOPSIS
        Efface l'écran et affiche le bandeau du script avec l'étape en cours.
    .PARAMETER Etape
        Texte de l'étape, par exemple "Étape 1 sur 4 : choisir la clé USB".
    #>
    param([string]$Etape)
    Clear-Host
    Write-Host ''
    Write-Host '  ====================================================' -ForegroundColor DarkYellow
    Write-Host '     LA MESNIE DES MERCENAIRES - Préparer une clé USB' -ForegroundColor Yellow
    Write-Host '  ====================================================' -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host "  $Etape" -ForegroundColor Cyan
    Write-Host ''
}

function Write-Info { param([string]$Texte) Write-Host "  $Texte" }
function Write-Ok { param([string]$Texte) Write-Host "  [OK] $Texte" -ForegroundColor Green }
function Write-Attention { param([string]$Texte) Write-Host "  /!\ $Texte" -ForegroundColor Yellow }

function Wait-Touche {
    <#
    .SYNOPSIS
        Attend que l'utilisateur appuie sur Entrée.
    #>
    Write-Host ''
    Read-Host '  Appuyez sur Entrée pour continuer' | Out-Null
}

# --- Étapes -------------------------------------------------------------------

function Select-CleUsb {
    <#
    .SYNOPSIS
        Liste les clés USB branchées et fait choisir l'une d'elles.
    .OUTPUTS
        La racine de la clé choisie, par exemple "E:\".
    #>
    while ($true) {
        Write-Titre 'Étape 1 sur 4 : choisir la clé USB'
        Write-Info 'Avant de commencer :'
        Write-Info '  - une connexion Internet est nécessaire pendant toute la préparation ;'
        Write-Info '  - la préparation dure en général 5 à 10 minutes ;'
        Write-Info '  - TOUT le contenu de la clé choisie sera effacé.'
        Write-Host ''
        $cles = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 2')
        if ($cles.Count -eq 0) {
            Write-Attention 'Aucune clé USB détectée.'
            Write-Info 'Branchez la clé, attendez quelques secondes puis appuyez sur Entrée.'
            Wait-Touche
            continue
        }

        Write-Info 'Clés USB branchées :'
        Write-Host ''
        for ($i = 0; $i -lt $cles.Count; $i++) {
            $nom = if ($cles[$i].VolumeName) { $cles[$i].VolumeName } else { 'Sans nom' }
            $taille = if ($cles[$i].Size) { '{0:N1} Go' -f ($cles[$i].Size / 1GB) } else { '?' }
            Write-Host ("    [{0}]  {1}  {2}  ({3})" -f ($i + 1), $cles[$i].DeviceID, $nom, $taille) -ForegroundColor White
        }
        Write-Host ''
        $choix = Read-Host '  Tapez le numéro de la clé puis Entrée (ou Entrée seule pour actualiser)'
        if ($choix -match '^\d+$' -and [int]$choix -ge 1 -and [int]$choix -le $cles.Count) {
            $racine = $cles[[int]$choix - 1].DeviceID + '\'
            if (@(Get-ChildItem -LiteralPath $racine -Force | Where-Object { $_.Name -ne 'System Volume Information' }).Count -gt 0) {
                Write-Host ''
                Write-Attention "La clé $racine n'est pas vide : tout son contenu sera effacé."
                $reponse = Read-Host '  Tapez OUI pour confirmer (ou Entrée pour choisir une autre clé)'
                if ($reponse -ne 'OUI') { continue }
            }
            return $racine
        }
    }
}

function Clear-Cle {
    <#
    .SYNOPSIS
        Efface tout le contenu de la clé (sauf le dossier système de Windows).
    .PARAMETER Racine
        Racine de la clé USB.
    #>
    param([string]$Racine)
    Get-ChildItem -LiteralPath $Racine -Force |
        Where-Object { $_.Name -ne 'System Volume Information' } |
        Remove-Item -Recurse -Force
}

function Invoke-GitMuet {
    <#
    .SYNOPSIS
        Lance git sans afficher ses messages et s'arrête avec un message clair en cas d'échec.
    .PARAMETER Git
        Chemin de git.exe.
    .PARAMETER Arguments
        Arguments de la commande git.
    .PARAMETER Erreur
        Message affiché si la commande échoue.
    .EXAMPLE
        Invoke-GitMuet -Git $git -Arguments @('clone', $Depot, $DossierSite) -Erreur 'La récupération du site a échoué.'
    #>
    param([string]$Git, [string[]]$Arguments, [string]$Erreur)
    $sortie = [IO.Path]::GetTempFileName()
    $erreurs = [IO.Path]::GetTempFileName()
    try {
        $ligne = ($Arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
        $processus = Start-Process -FilePath $Git -ArgumentList $ligne -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $sortie -RedirectStandardError $erreurs
        if ($processus.ExitCode -ne 0) {
            $detail = (Get-Content -LiteralPath $erreurs | Where-Object { $_ } | Select-Object -Last 1)
            throw "$Erreur ($detail)"
        }
    } finally {
        Remove-Item -LiteralPath $sortie, $erreurs -Force -ErrorAction SilentlyContinue
    }
}

function Get-GitPortable {
    <#
    .SYNOPSIS
        Télécharge et décompresse la dernière version 64 bits de Git portable.
    .PARAMETER Dossier
        Dossier temporaire de travail.
    .OUTPUTS
        Le dossier de Git portable (celui qui contient cmd\git.exe).
    #>
    param([string]$Dossier)
    $version = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing
    $fichier = $version.assets | Where-Object { $_.name -match '^PortableGit-.*-64-bit\.7z\.exe$' } | Select-Object -First 1
    if (-not $fichier) { throw 'Git portable introuvable sur GitHub.' }

    $archive = Join-Path $Dossier $fichier.name
    $cible = Join-Path $Dossier 'git'
    Invoke-WebRequest -Uri $fichier.browser_download_url -OutFile $archive -UseBasicParsing
    # L'archive se décompresse elle-même, sans fenêtre
    Start-Process -FilePath $archive -ArgumentList '-y', "-o`"$cible`"" -Wait -WindowStyle Hidden
    if (-not (Test-Path -LiteralPath (Join-Path $cible 'cmd\git.exe'))) { throw 'La décompression de Git portable a échoué.' }
    return $cible
}

function Read-Jeton {
    <#
    .SYNOPSIS
        Demande le jeton GitHub et vérifie qu'il permet de publier sur le dépôt du site.
    .OUTPUTS
        Le jeton vérifié.
    #>
    while ($true) {
        Write-Titre 'Étape 2 sur 4 : jeton GitHub de la Mesnie'
        Write-Info 'Collez le jeton GitHub (il commence par ghp_) : clic droit dans cette'
        Write-Info 'fenêtre, puis Entrée. Rien ne s''affiche pendant la saisie, c''est normal.'
        Write-Host ''
        $jeton = (Read-MotDePasse -Invite '  Jeton').Trim()
        if (-not $jeton) { continue }

        Write-Info 'Vérification du jeton...'
        try {
            $entetes = @{ Authorization = "token $jeton"; 'User-Agent' = 'preparer-cle' }
            $infos = Invoke-RestMethod -Uri "https://api.github.com/repos/$Proprietaire/$NomDepot" -Headers $entetes -UseBasicParsing
            if ($infos.permissions.push) { Write-Ok 'Jeton valide.'; Start-Sleep -Seconds 1; return $jeton }
            Write-Attention 'Ce jeton ne permet pas de publier : cochez la permission "repo" en le créant.'
        } catch {
            Write-Attention 'Jeton refusé par GitHub : vérifiez qu''il est complet et toujours actif.'
        }
        Wait-Touche
    }
}

function Read-NouveauMotDePasse {
    <#
    .SYNOPSIS
        Fait choisir le mot de passe de publication (saisi deux fois).
    .OUTPUTS
        Le mot de passe choisi.
    #>
    while ($true) {
        Write-Titre 'Étape 3 sur 4 : mot de passe de publication'
        Write-Info 'Choisissez le mot de passe que le bureau tapera pour publier le site.'
        Write-Info 'Au moins 8 caractères. Rien ne s''affiche pendant la saisie, c''est normal.'
        Write-Host ''
        $motDePasse = Read-MotDePasse -Invite '  Mot de passe'
        $confirmation = Read-MotDePasse -Invite '  Retapez-le'
        if ($motDePasse.Length -lt 8) { Write-Attention 'Trop court : 8 caractères minimum.'; Wait-Touche; continue }
        if ($motDePasse -ne $confirmation) { Write-Attention 'Les deux saisies sont différentes.'; Wait-Touche; continue }
        return $motDePasse
    }
}

function New-RaccourciRelatif {
    <#
    .SYNOPSIS
        Crée un raccourci .lnk qui ouvre un dossier désigné par un chemin relatif à la clé.
    .PARAMETER Fichier
        Chemin complet du raccourci à créer (.lnk).
    .PARAMETER CheminRelatif
        Dossier à ouvrir, relatif au dossier du raccourci.
    .PARAMETER Icone
        Icône du raccourci (fichier,index).
    #>
    param([string]$Fichier, [string]$CheminRelatif, [string]$Icone)
    # Sans dossier de démarrage, cmd démarre dans le dossier du raccourci : le chemin relatif suit la clé
    $raccourci = (New-Object -ComObject WScript.Shell).CreateShortcut($Fichier)
    $raccourci.TargetPath = '%ComSpec%'
    $raccourci.Arguments = "/c start `"`" `"$CheminRelatif`""
    $raccourci.WorkingDirectory = ''
    $raccourci.WindowStyle = 7
    $raccourci.IconLocation = $Icone
    $raccourci.Save()
}

function Initialize-Cle {
    <#
    .SYNOPSIS
        Remplit la clé : site, Git portable, jeton chiffré, raccourcis, script et mode d'emploi.
    .PARAMETER Racine
        Racine de la clé USB.
    .PARAMETER Jeton
        Jeton GitHub vérifié.
    .PARAMETER MotDePasse
        Mot de passe de publication.
    #>
    param([string]$Racine, [string]$Jeton, [string]$MotDePasse)
    Write-Titre 'Étape 4 sur 4 : remplissage de la clé (5 à 10 minutes)'
    Write-Info 'Ne retirez pas la clé et ne coupez pas Internet pendant cette étape.'
    Write-Host ''
    $DossierSite = Join-Path $Racine $NomDossier
    $temporaire = Join-Path $env:TEMP ('preparer-cle-' + [Guid]::NewGuid())
    New-Item -ItemType Directory -Path $temporaire | Out-Null

    try {
        Write-Info 'Effacement du contenu de la clé...'
        Clear-Cle -Racine $Racine
        Write-Ok 'Clé vidée.'

        Write-Info 'Téléchargement de Git portable...'
        $gitPortable = Get-GitPortable -Dossier $temporaire
        $git = Join-Path $gitPortable 'cmd\git.exe'
        Write-Ok 'Git portable téléchargé.'

        Write-Info 'Récupération du site depuis GitHub...'
        Invoke-GitMuet -Git $git -Arguments @('clone', '--quiet', $Depot, $DossierSite) -Erreur 'La récupération du site a échoué.'
        if (-not (Test-Path -LiteralPath (Join-Path $DossierSite '.git'))) { throw 'La récupération du site a échoué.' }
        # Auteur des commits publiés depuis la clé
        Invoke-GitMuet -Git $git -Arguments @('-C', $DossierSite, 'config', 'user.name', $NomAuteur) -Erreur 'Réglage de Git impossible.'
        Invoke-GitMuet -Git $git -Arguments @('-C', $DossierSite, 'config', 'user.email', $EmailAuteur) -Erreur 'Réglage de Git impossible.'
        Write-Ok 'Site copié.'

        Write-Info 'Copie de Git portable sur la clé (c''est l''étape la plus longue)...'
        Copy-Item -LiteralPath $gitPortable -Destination (Join-Path $DossierSite 'outils\git') -Recurse
        Write-Ok 'Git portable copié.'

        Protect-Jeton -Jeton $Jeton -MotDePasse $MotDePasse -Fichier (Join-Path $DossierSite '.cle\jeton.json')
        Write-Ok 'Jeton enregistré (chiffré).'

        New-RaccourciRelatif -Fichier (Join-Path $Racine 'Photos de la galerie.lnk') `
            -CheminRelatif "$NomDossier\images\galerie" -Icone '%SystemRoot%\System32\imageres.dll,108'
        New-RaccourciRelatif -Fichier (Join-Path $Racine 'Photos du bureau.lnk') `
            -CheminRelatif "$NomDossier\images\bureau" -Icone '%SystemRoot%\System32\imageres.dll,117'
        $lanceur = "@echo off`r`n" +
            "rem Prepare les photos et publie le site. Voir le Mode d'emploi.`r`n" +
            "powershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0$NomDossier\scripts\deployer.ps1`"`r`n" +
            "pause`r`n"
        [IO.File]::WriteAllText((Join-Path $Racine 'Publier le site.bat'), $lanceur, [Text.Encoding]::ASCII)
        Write-Ok 'Raccourcis et script de publication créés.'

        $pdf = Join-Path $DossierSite "scripts\cle\Mode d'emploi.pdf"
        if (-not (Test-Path -LiteralPath $pdf)) { throw 'Mode d''emploi absent du site sur GitHub : publiez d''abord la dernière version du site.' }
        Copy-Item -LiteralPath $pdf -Destination $Racine
        Write-Ok 'Mode d''emploi copié.'
    } finally {
        Remove-Item -LiteralPath $temporaire -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- Programme principal ------------------------------------------------------

try {
    $racine = Select-CleUsb
    $jeton = Read-Jeton
    $motDePasse = Read-NouveauMotDePasse
    Initialize-Cle -Racine $racine -Jeton $jeton -MotDePasse $motDePasse

    Write-Host ''
    Write-Host '  ====================================================' -ForegroundColor Green
    Write-Host "     CLÉ PRÊTE ($racine)" -ForegroundColor Green
    Write-Host '  ====================================================' -ForegroundColor Green
    Write-Host ''
    Write-Info 'Éjectez la clé proprement avant de la retirer.'
    Write-Info 'Le bureau trouvera le mode d''emploi à la racine de la clé.'
    Start-Process -FilePath 'explorer.exe' -ArgumentList $racine
} catch {
    Write-Host ''
    Write-Host '  ====================================================' -ForegroundColor Red
    Write-Host '     ERREUR' -ForegroundColor Red
    Write-Host '  ====================================================' -ForegroundColor Red
    Write-Host ''
    Write-Info $_.Exception.Message
    Write-Info 'Vérifiez la connexion Internet et la clé, puis relancez preparer-cle.bat :'
    Write-Info 'la clé sera de nouveau vidée avant d''être remplie.'
    exit 1
}
