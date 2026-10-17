/**
 * @file Page Contact : envoie le formulaire au service Web3Forms, qui transmet
 * le message par e-mail à l'association, puis affiche le résultat sans changer de page.
 * La clé Web3Forms se règle dans assets/js/config.js.
 *
 * Un lien du type contact.html?objet=prestation présélectionne l'objet du message
 * (valeurs possibles : celles des attributs data-raccourci du menu « Objet »).
 */
(function () {
  "use strict";

  const ADRESSE_WEB3FORMS = "https://api.web3forms.com/submit";

  const formulaire = document.getElementById("formulaire-contact");
  if (!formulaire) return;

  const etat = document.getElementById("etat-envoi");
  const boutonEnvoi = formulaire.querySelector('button[type="submit"]');
  const champObjet = document.getElementById("objet");
  const cle = (window.SITE_CONFIG && window.SITE_CONFIG.web3formsCle) || "";
  const nomSite = (window.SITE_CONFIG && window.SITE_CONFIG.nom) || "La Mesnie Des Mercenaires";

  /**
   * Affiche un message sous le formulaire.
   * @param {string} texte - Message à afficher ("" pour l'effacer).
   * @param {"succes"|"erreur"|""} [type=""] - Style du message.
   * @returns {void}
   */
  function afficherEtat(texte, type = "") {
    etat.textContent = texte;
    etat.className = "message-etat" + (type ? " " + type : "");
  }

  /**
   * Présélectionne l'objet du message d'après le paramètre ?objet= de l'adresse.
   * @returns {void}
   */
  function preselectionnerObjet() {
    const raccourci = new URLSearchParams(window.location.search).get("objet");
    if (!raccourci) return;
    const option = champObjet.querySelector(`option[data-raccourci="${CSS.escape(raccourci)}"]`);
    if (option) option.selected = true;
  }

  /**
   * Envoie le formulaire à Web3Forms et affiche la réussite ou l'erreur.
   * @param {SubmitEvent} evenement - Événement de soumission du formulaire.
   * @returns {Promise<void>}
   */
  async function envoyer(evenement) {
    evenement.preventDefault();

    if (!cle || cle.startsWith("VOTRE")) {
      afficherEtat("Le formulaire n'est pas encore configuré : merci de nous écrire via nos réseaux sociaux.", "erreur");
      return;
    }

    const donnees = Object.fromEntries(new FormData(formulaire));
    donnees.access_key = cle;
    donnees.from_name = "Site web - " + nomSite;
    donnees.subject = `[Site web] ${donnees.objet} - ${donnees.nom}`;

    boutonEnvoi.disabled = true;
    afficherEtat("Envoi en cours…");

    try {
      const reponse = await fetch(ADRESSE_WEB3FORMS, {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify(donnees),
      });
      const resultat = await reponse.json();

      if (reponse.ok && resultat.success) {
        formulaire.reset();
        afficherEtat("Merci ! Votre message nous est bien parvenu, nous vous répondrons au plus vite.", "succes");
      } else {
        afficherEtat("L'envoi a échoué : " + (resultat.message || "erreur inconnue") + ". Merci de réessayer plus tard.", "erreur");
      }
    } catch (erreur) {
      afficherEtat("Impossible de joindre le service d'envoi. Vérifiez votre connexion puis réessayez.", "erreur");
    } finally {
      boutonEnvoi.disabled = false;
    }
  }

  preselectionnerObjet();
  formulaire.addEventListener("submit", envoyer);
})();
