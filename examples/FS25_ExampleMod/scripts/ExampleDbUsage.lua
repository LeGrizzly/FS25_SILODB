ExampleDbUsage = {}

function ExampleDbUsage:loadMap(name)
    print("ExampleDbUsage: Chargement...")

    local SILODB = g_globalMods and g_globalMods["FS25_SILODB"]
    if not SILODB or not SILODB.isReady() then
        print("ExampleDbUsage ERROR: SILODB non disponible.")
        return
    end

    print("ExampleDbUsage: SILODB v" .. SILODB.getVersion() .. " pret.")

    -- Etape 1 : Lier le namespace et obtenir une instance ORM
    local db = SILODB.bind("FS25_ExampleMod")

    -- Etape 2 : Definir un modele
    local schema, err = db:define("Player", {
        fields = {
            name  = { type = "string", required = true },
            money = { type = "number", default = 0 },
            level = { type = "number", default = 1 }
        }
    })
    if err then
        print("ExampleDbUsage ERROR: define -> " .. tostring(err))
        return
    end

    -- Etape 3 : Creer un enregistrement
    local record, createErr = db:create("Player", {
        name  = "Fermier Testeur",
        money = 15000,
        level = 3
    })
    if createErr then
        print("ExampleDbUsage ERROR: create -> " .. tostring(createErr))
        return
    end
    print(string.format("ExampleDbUsage: Player cree (id=%d, name=%s)", record.id, record.name))

    -- Etape 4 : Lire par ID
    local found, findErr = db:findById("Player", record.id)
    if found then
        print(string.format("ExampleDbUsage: findById -> %s, money=%d", found.name, found.money))
    end

    -- Etape 5 : Mettre a jour
    local updated, updateErr = db:update("Player", record.id, { money = 25000 })
    if updated then
        print(string.format("ExampleDbUsage: update -> money=%d", updated.money))
    end

    -- Etape 6 : Compter
    local total = db:count("Player")
    print("ExampleDbUsage: " .. tostring(total) .. " joueur(s) en base.")

    -- Etape 7 : Recherche avec filtre
    local highLevel, queryErr = db:findAll("Player", { where = { level = 3 } })
    if highLevel then
        print("ExampleDbUsage: " .. #highLevel .. " joueur(s) niveau 3.")
    end
end

addModEventListener(ExampleDbUsage)
