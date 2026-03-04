# FS25 - DB API 🚜 💾

[🇬🇧 English](#english) | [🇫🇷 Français](#francais)

---

<a id="english"></a>
## 🇬🇧 English

### Overview
This mod introduces [FlatDB](https://github.com/uleelx/FlatDB) integration for **Farming Simulator 25 (FS25)**. It provides a lightweight, flat-file database solution for modders and server admins who need fast, structured, and local data storage without the overhead of a traditional SQL database. 

Built with **Clean Architecture** principles, this project is highly modular, testable, and easy to extend.

### ✨ Features
* **FlatDB Integration:** Harness the power of FlatDB for your FS25 saves and custom mod data.
* **Clean Architecture:** Strict separation of concerns (Domain, Application, Infrastructure, Presentation).
* **Performance Optimized:** Flat-file storage ensures fast read/write operations with minimal impact on the game loop.
* **Developer Friendly:** Clean interfaces make it easy for other mods to hook into the database.

### 🏗️ Architecture
This mod follows Clean Architecture to ensure maintainability:
1. **Domain:** Core entities and database interfaces.
2. **Application (Use Cases):** Business logic for handling game events and data transactions.
3. **Infrastructure:** The actual FlatDB implementation and FS25 Lua API adapters.
4. **Presentation:** The entry points connecting the FS25 engine to the mod logic.

### 💻 For Developers
To use this database in your own mods, you can access the core repository instance. 
*(Add a quick code snippet here later if you have a public API for other mods to use)*

### 📜 License & Credits
* Core Database Engine: [FlatDB by uleelx](https://github.com/uleelx/FlatDB)
* Mod created by: **LeGrizzly**
* License: MIT

---

<a id="francais"></a>
## 🇫🇷 Français

### Présentation
Ce mod intègre [FlatDB](https://github.com/uleelx/FlatDB) dans **Farming Simulator 25 (FS25)**. Il fournit une solution de base de données légère (fichiers plats) pour les moddeurs et les administrateurs de serveurs qui ont besoin d'un stockage de données rapide, structuré et local, sans la lourdeur d'une base de données SQL traditionnelle.

Développé en suivant les principes de la **Clean Architecture**, ce projet est hautement modulaire, testable et facile à faire évoluer.

### ✨ Fonctionnalités
* **Intégration de FlatDB :** Exploitez la puissance de FlatDB pour vos sauvegardes FS25 et les données de vos mods personnalisés.
* **Clean Architecture :** Séparation stricte des responsabilités (Domaine, Application, Infrastructure, Présentation).
* **Performances optimisées :** Le stockage en fichiers plats garantit des opérations de lecture/écriture rapides avec un impact minimal sur la boucle de jeu.
* **Conçu pour les développeurs :** Des interfaces claires permettent aux autres mods de se connecter facilement à la base de données.

### 🏗️ Architecture
Ce mod suit la "Clean Architecture" pour garantir sa maintenabilité :
1. **Domaine (Domain) :** Entités principales et interfaces de la base de données.
2. **Application (Cas d'utilisation) :** Logique métier pour la gestion des événements du jeu et des transactions de données.
3. **Infrastructure :** L'implémentation réelle de FlatDB et les adaptateurs pour l'API Lua de FS25.
4. **Présentation (Presentation) :** Les points d'entrée reliant le moteur FS25 à la logique du mod.

### 💻 Pour les développeurs
Pour utiliser cette base de données dans vos propres mods, vous pouvez accéder à l'instance principale du repository.
*(Ajoutez ici un extrait de code si vous avez une API publique)*

### 📜 Licence et Crédits
* Moteur de base de données : [FlatDB par uleelx](https://github.com/uleelx/FlatDB)
* Mod créé par : **LeGrizzly**
* Licence : MIT
