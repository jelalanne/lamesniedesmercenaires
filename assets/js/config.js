/**
 * @file Réglages généraux du site : c'est le seul fichier à modifier pour changer
 * le nom affiché, la clé du formulaire de contact ou les liens vers les réseaux sociaux.
 *
 * @typedef {Object} Reseau
 * @property {string} nom - Texte du lien (ex. "Facebook").
 * @property {string} url - Adresse complète de la page. Laisser "" pour masquer le lien.
 *
 * @type {{nom: string, web3formsCle: string, reseaux: Reseau[]}}
 */
window.SITE_CONFIG = {
  /** Nom affiché dans l'en-tête et le pied de page. */
  nom: "La Mesnie Des Mercenaires",

  /**
   * Clé d'accès Web3Forms du formulaire de contact (voir le README, section
   * « Formulaire de contact »). Cette clé peut être publique sans risque.
   */
  web3formsCle: "6461cc21-4ac0-48e0-92be-acf002d7ca18",

  /** Liens vers les réseaux sociaux, affichés en pied de page et sur la page Contact. */
  reseaux: [
    { nom: "Facebook", url: "https://www.facebook.com/" }, // À REMPLACER par la page de l'asso
    { nom: "Instagram", url: "https://www.instagram.com/" }, // À REMPLACER par le compte de l'asso
  ],
};
