/**
 * @file Page Galerie : affiche les vignettes des photos listées dans galerie-data.js
 * (fichier généré par scripts/deployer.ps1) et les ouvre en grand dans une visionneuse.
 * Navigation : boutons ‹ ›, flèches gauche/droite du clavier, Échap ou clic à côté pour fermer.
 */
(function () {
  "use strict";

  /** @type {{image: string, miniature: string, legende: string}[]} */
  const photos = Array.isArray(window.GALERIE_PHOTOS) ? window.GALERIE_PHOTOS : [];

  const liste = document.getElementById("galerie");
  const messageVide = document.getElementById("galerie-vide");
  const visionneuse = document.getElementById("visionneuse");
  const imageGrande = document.getElementById("visionneuse-image");
  const legendeGrande = document.getElementById("visionneuse-legende");
  let indexCourant = 0;

  /**
   * Crée la vignette cliquable d'une photo.
   * @param {{image: string, miniature: string, legende: string}} photo - Photo à afficher.
   * @param {number} index - Position de la photo dans la galerie.
   * @returns {HTMLLIElement} Élément à ajouter à la liste #galerie.
   */
  function creerVignette(photo, index) {
    const element = document.createElement("li");
    const figure = document.createElement("figure");
    const bouton = document.createElement("button");
    const image = document.createElement("img");

    bouton.type = "button";
    bouton.className = "vignette";
    bouton.setAttribute("aria-label", "Agrandir : " + (photo.legende || "photo " + (index + 1)));
    bouton.addEventListener("click", () => ouvrir(index));

    image.src = photo.miniature || photo.image;
    image.alt = photo.legende || "";
    image.loading = "lazy";

    bouton.appendChild(image);
    figure.appendChild(bouton);

    if (photo.legende) {
      const legende = document.createElement("figcaption");
      legende.textContent = photo.legende;
      figure.appendChild(legende);
    }

    element.appendChild(figure);
    return element;
  }

  /**
   * Affiche une photo dans la visionneuse ; l'index boucle d'une extrémité à l'autre.
   * @param {number} index - Position de la photo (peut être -1 ou photos.length).
   * @returns {void}
   */
  function afficher(index) {
    indexCourant = (index + photos.length) % photos.length;
    const photo = photos[indexCourant];
    const position = `${indexCourant + 1} / ${photos.length}`;

    imageGrande.src = photo.image;
    imageGrande.alt = photo.legende || "";
    legendeGrande.textContent = photo.legende ? `${photo.legende} (${position})` : position;
  }

  /**
   * Ouvre la visionneuse sur une photo.
   * @param {number} index - Position de la photo à afficher.
   * @returns {void}
   */
  function ouvrir(index) {
    afficher(index);
    if (!visionneuse.open) visionneuse.showModal();
  }

  if (!liste) return;

  if (photos.length === 0) {
    messageVide.hidden = false;
    return;
  }

  photos.forEach((photo, index) => liste.appendChild(creerVignette(photo, index)));

  // Boutons précédent / suivant inutiles s'il n'y a qu'une photo
  if (photos.length < 2) {
    visionneuse.querySelectorAll('[data-action="precedent"], [data-action="suivant"]').forEach((b) => (b.hidden = true));
  }

  // Clic sur un bouton de la visionneuse, ou à côté de la photo pour fermer
  visionneuse.addEventListener("click", (evenement) => {
    const cible = evenement.target.closest("[data-action]");
    const action = cible ? cible.dataset.action : null;

    if (action === "fermer" || evenement.target === visionneuse) visionneuse.close();
    else if (action === "precedent") afficher(indexCourant - 1);
    else if (action === "suivant") afficher(indexCourant + 1);
  });

  // Flèches du clavier (Échap est géré nativement par <dialog>)
  visionneuse.addEventListener("keydown", (evenement) => {
    if (evenement.key === "ArrowLeft") afficher(indexCourant - 1);
    else if (evenement.key === "ArrowRight") afficher(indexCourant + 1);
  });
})();
