<#
.SYNOPSIS
    Chiffrement du jeton GitHub stocké sur les clés USB du bureau.

.DESCRIPTION
    Le jeton d'accès GitHub du compte de la Mesnie est chiffré (AES-256) avec une clé dérivée
    d'un mot de passe (PBKDF2-SHA256). Le fichier chiffré ne sert à rien sans ce mot de passe.
    Ce fichier est chargé par deployer.ps1 et preparer-cle.ps1 (dot-sourcing).
#>

$IterationsPbkdf2 = 200000

function Get-CleDerivee {
    <#
    .SYNOPSIS
        Dérive 64 octets (32 pour le chiffrement, 32 pour le contrôle) depuis le mot de passe.
    .PARAMETER MotDePasse
        Mot de passe saisi.
    .PARAMETER Sel
        Sel aléatoire stocké avec le jeton.
    .OUTPUTS
        byte[] de 64 octets.
    #>
    param([string]$MotDePasse, [byte[]]$Sel)
    $derivation = New-Object System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList $MotDePasse, $Sel, $IterationsPbkdf2, ([System.Security.Cryptography.HashAlgorithmName]::SHA256)
    try { return $derivation.GetBytes(64) } finally { $derivation.Dispose() }
}

function Protect-Jeton {
    <#
    .SYNOPSIS
        Chiffre le jeton GitHub avec le mot de passe et l'écrit dans un fichier.
    .PARAMETER Jeton
        Jeton d'accès GitHub en clair.
    .PARAMETER MotDePasse
        Mot de passe qui sera demandé à chaque publication.
    .PARAMETER Fichier
        Fichier de destination (créé ou remplacé).
    .EXAMPLE
        Protect-Jeton -Jeton 'github_pat_...' -MotDePasse 'secret' -Fichier 'E:\Site\.cle\jeton.json'
    #>
    param([string]$Jeton, [string]$MotDePasse, [string]$Fichier)

    $aleatoire = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $sel = New-Object byte[] 16; $aleatoire.GetBytes($sel)
    $cle = Get-CleDerivee -MotDePasse $MotDePasse -Sel $sel

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $cle[0..31]
    $aes.GenerateIV()
    $clair = [Text.Encoding]::UTF8.GetBytes($Jeton)
    $chiffre = $aes.CreateEncryptor().TransformFinalBlock($clair, 0, $clair.Length)

    # Code de contrôle : permet de reconnaître un mauvais mot de passe
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (, [byte[]]$cle[32..63])
    $controle = $hmac.ComputeHash([byte[]]($aes.IV + $chiffre))

    $contenu = [ordered]@{
        sel      = [Convert]::ToBase64String($sel)
        iv       = [Convert]::ToBase64String($aes.IV)
        donnees  = [Convert]::ToBase64String($chiffre)
        controle = [Convert]::ToBase64String($controle)
    } | ConvertTo-Json

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Fichier) | Out-Null
    [IO.File]::WriteAllText($Fichier, $contenu)
}

function Unprotect-Jeton {
    <#
    .SYNOPSIS
        Déchiffre le jeton GitHub avec le mot de passe.
    .PARAMETER MotDePasse
        Mot de passe saisi.
    .PARAMETER Fichier
        Fichier écrit par Protect-Jeton.
    .OUTPUTS
        Le jeton en clair, ou $null si le mot de passe est faux.
    #>
    param([string]$MotDePasse, [string]$Fichier)

    $contenu = [IO.File]::ReadAllText($Fichier) | ConvertFrom-Json
    $sel = [Convert]::FromBase64String($contenu.sel)
    $iv = [Convert]::FromBase64String($contenu.iv)
    $chiffre = [Convert]::FromBase64String($contenu.donnees)
    $cle = Get-CleDerivee -MotDePasse $MotDePasse -Sel $sel

    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (, [byte[]]$cle[32..63])
    $attendu = [Convert]::ToBase64String($hmac.ComputeHash([byte[]]($iv + $chiffre)))
    if ($attendu -ne $contenu.controle) { return $null }

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $cle[0..31]
    $aes.IV = $iv
    $clair = $aes.CreateDecryptor().TransformFinalBlock($chiffre, 0, $chiffre.Length)
    return [Text.Encoding]::UTF8.GetString($clair)
}

function Read-MotDePasse {
    <#
    .SYNOPSIS
        Demande un mot de passe sans l'afficher à l'écran.
    .PARAMETER Invite
        Texte affiché.
    .OUTPUTS
        Le mot de passe en clair.
    #>
    param([string]$Invite)
    $securise = Read-Host -Prompt $Invite -AsSecureString
    $pointeur = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securise)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointeur) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointeur) }
}
