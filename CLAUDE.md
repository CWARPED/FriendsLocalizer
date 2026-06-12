# FriendsLocalizer — instructions projet

## S'orienter avec graphify avant d'agir

Ce projet a un graphe de connaissances graphify dans `graphify-out/` (carte de l'architecture :
crypto → mesh → BLE → application → UI, plus les 10 plans de conception).

**Règle — consulter graphify pour s'orienter :**

- **Avant un développement** (ajout/modif de feature, refactor) : commencer par interroger le
  graphe pour situer le code concerné — quels fichiers, quelles dépendances, quels points de
  branchement. Ex. : `graphify query "où est branché le chiffrement des positions ?"` ou
  `graphify explain "MeshEngine"`.

- **Avant de répondre à une question sur le projet** (« comment marche X ? », « qu'est-ce qui
  touche à Y ? », « trace le flux Z ») : interroger d'abord le graphe pour avoir une vue
  d'ensemble, puis répondre.

**Important — le graphe est une photo, pas la vérité :**

- Le graphe est figé à sa dernière génération ; il ne se met pas à jour tout seul. **Le vrai code
  reste la source de vérité.** Toujours vérifier dans les fichiers réels avant de modifier quoi que
  ce soit ou d'affirmer un détail précis.
- Utiliser graphify pour **s'orienter** (gagner du temps, ne rien oublier), pas pour **décider** à
  la place de la lecture du code.
- Si le code a beaucoup changé depuis la dernière carte, rafraîchir : `graphify . --update`
  (ne ré-analyse que ce qui a changé).

**Comment lancer graphify :** l'interpréteur Python qui a le package est enregistré dans
`graphify-out/.graphify_python`. Si la commande `graphify` n'est pas sur le PATH, passer par cet
interpréteur (voir le skill `/graphify`).
