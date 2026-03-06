ExampleDbUsage = {}
local MOD_NAME = g_currentModName

function ExampleDbUsage:loadMap(name)
    print("ExampleDbUsage: Chargement...")

    -- On récupère l'API via g_globalMods comme demandé
    if g_globalMods then
        self.DBAPI = g_globalMods["FS25_DBAPI"]
    end

    -- Étape 1 : Vérifier la présence de l'API
    if self.DBAPI == nil then
        print("ExampleDbUsage ERROR: DBAPI n'est pas chargé dans g_globalMods ! Vérifiez vos dépendances.")
        return
    end

    if not self.DBAPI.isReady() then
        print("ExampleDbUsage WARNING: DBAPI est présent mais pas encore prêt.")
        return
    end

    print("ExampleDbUsage: API DBAPI trouvée.")

    print("ExampleDbUsage: Initialisation des données de test...")

    -- Étape 2 : Écrire une donnée (setValue)
    local myData = {
        playerName = "Fermier Testeur",
        money = 15000,
        vehicles = {"Tractor1", "Harvester2"}
    }

    local success, err = self.DBAPI.setValue(MOD_NAME, "player_stats", myData)

    if success then
        print("ExampleDbUsage: Données écrites avec succès !")
    else
        print("ExampleDbUsage ERROR: Échec de l'écriture : " .. tostring(err))
    end

    -- Étape 3 : Lire une donnée (getValue)
    self:testRead()
end

function ExampleDbUsage:testRead()
    if self.DBAPI == nil then return end

    -- Syntaxe : self.DBAPI.getValue(votre_mod_name, cle)
    local loadedData = self.DBAPI.getValue(MOD_NAME, "player_stats")

    if loadedData then
        print(string.format("ExampleDbUsage: Données lues -> Nom: %s, Argent: %d", 
            loadedData.playerName, loadedData.money))
    else
        print("ExampleDbUsage: Aucune donnée trouvée (ou erreur de lecture).")
    end
end

-- Enregistrement du listener
addModEventListener(ExampleDbUsage)
