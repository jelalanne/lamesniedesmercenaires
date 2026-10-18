/**
 * @file Éléments communs à toutes les pages : en-tête (logo + menu), pied de page
 * et listes de liens vers les réseaux sociaux.
 * Le nom du site et les réseaux viennent de assets/js/config.js.
 *
 * Utilisation dans une page :
 *   <div id="entete"></div>        → remplacé par l'en-tête
 *   <div id="pied-de-page"></div>  → remplacé par le pied de page
 *   <ul data-reseaux></ul>         → rempli avec les liens des réseaux sociaux
 */
(function () {
  "use strict";

  /** Pages du menu principal, dans l'ordre d'affichage. */
  const PAGES = [
    { titre: "Accueil", fichier: "index.html" },
    { titre: "L'association", fichier: "association.html" },
    { titre: "Prestations", fichier: "prestations.html" },
    { titre: "Galerie", fichier: "galerie.html" },
    { titre: "Contact", fichier: "contact.html" },
  ];

  const config = window.SITE_CONFIG || {};
  const nomSite = config.nom || "La Mesnie Des Mercenaires";

  /**
   * Échappe les caractères spéciaux HTML d'un texte avant de l'insérer dans la page.
   * @param {string} texte - Texte brut.
   * @returns {string} Texte sans risque pour innerHTML.
   */
  function echapper(texte) {
    const entites = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
    return String(texte).replace(/[&<>"']/g, (caractere) => entites[caractere]);
  }

  /**
   * Donne le nom de fichier de la page affichée, pour surligner l'entrée du menu.
   * @returns {string} Ex. "galerie.html" ; "index.html" pour la racine du site.
   */
  function pageCourante() {
    let fichier = decodeURIComponent(window.location.pathname.split("/").pop() || "");
    if (!fichier) return "index.html";
    // GitHub Pages sert aussi les pages sans extension (ex. /galerie)
    if (!fichier.includes(".")) fichier += ".html";
    return fichier;
  }

  /**
   * Construit les éléments <li> des liens vers les réseaux sociaux (ceux dont l'url est vide sont ignorés).
   * @returns {string} HTML des éléments de liste.
   */
  function construireReseaux() {
    return (config.reseaux || [])
      .filter((reseau) => reseau && reseau.url)
      .map((reseau) => `<li><a href="${echapper(reseau.url)}" target="_blank" rel="noopener">${echapper(reseau.nom)}</a></li>`)
      .join("");
  }

  /**
   * Remplace #entete par l'en-tête du site et active le bouton de menu sur mobile.
   * @returns {void}
   */
  function afficherEntete() {
    const emplacement = document.getElementById("entete");
    if (!emplacement) return;

    const courante = pageCourante();
    const liens = PAGES.map((page) => {
      const actif = page.fichier === courante ? ' aria-current="page"' : "";
      return `<li><a href="${page.fichier}"${actif}>${echapper(page.titre)}</a></li>`;
    }).join("");

    emplacement.outerHTML = `
      <a class="lien-evitement" href="#contenu">Aller au contenu</a>
      <header class="entete">
        <div class="entete-interieur">
          <a class="marque" href="index.html">
            <img src="images/logo.jpg" alt="" width="53" height="53">
            <span>${echapper(nomSite)}</span>
          </a>
          <button type="button" class="menu-bouton" aria-expanded="false" aria-controls="menu-principal">&#9776; Menu</button>
          <nav id="menu-principal" class="menu-principal" aria-label="Navigation principale">
            <ul>${liens}</ul>
          </nav>
        </div>
      </header>`;

    // Ouverture / fermeture du menu sur petit écran
    const bouton = document.querySelector(".menu-bouton");
    const menu = document.getElementById("menu-principal");
    bouton.addEventListener("click", () => {
      const ouvert = menu.classList.toggle("ouvert");
      bouton.setAttribute("aria-expanded", String(ouvert));
    });
  }

  /**
   * Remplace #pied-de-page par le pied de page (réseaux, copyright, mentions légales).
   * @returns {void}
   */
  function afficherPiedDePage() {
    const emplacement = document.getElementById("pied-de-page");
    if (!emplacement) return;

    emplacement.outerHTML = `
      <footer class="pied">
        <ul class="reseaux" data-reseaux></ul>
        <p>&copy; ${new Date().getFullYear()} ${echapper(nomSite)} &middot; Association loi 1901
          &middot; <a href="mentions-legales.html">Mentions légales</a></p>
      </footer>`;
  }

  /**
   * Remplit toutes les listes marquées data-reseaux ; masque celles qui restent vides.
   * @returns {void}
   */
  function remplirListesReseaux() {
    const html = construireReseaux();
    document.querySelectorAll("[data-reseaux]").forEach((liste) => {
      liste.innerHTML = html;
      liste.hidden = !html;
    });
  }

  afficherEntete();
  afficherPiedDePage();
  remplirListesReseaux();
})();
