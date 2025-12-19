HOMEALONE = {
    registered = false
}

function HOMEALONE:RegisterRole()
    if self.registered then return end

    self.registered = true

    -- Register Kevin
    local role = {
        nameraw = "kevin",
        name = "Kevin",
        nameplural = "Kevins",
        nameext = "Kevin",
        nameshort = "kvn",
        team = ROLE_TEAM_INDEPENDENT,
        blockspawnconvars = true,
        canlootcredits = true,
        startingcredits = 3,
        shop = {
            laserpointer,
            surprisesoldiers,
            ttt_combine_sniper_summoner,
            ttt_weeping_angel,
            weapon_amongussummoner,
            weapon_antlionsummoner,
            weapon_controllable_manhack,
            weapon_doncombinesummoner,
            weapon_sharkulonsummoner,
            weapon_ttt_artillery,
            weapon_ttt_barnacle,
            weapon_ttt_beartrap,
            weapon_ttt_bonk_bat,
            weapon_ttt_dead_ringer,
            weapon_ttt_deadringer,
            weapon_ttt_fortnite_building,
            weapon_ttt_freezegun,
            weapon_ttt_id_bomb,
            weapon_ttt_moonball,
            weapon_ttt_rsb,
            weapon_ttt_shocktrap,
            weapon_ttt_slam,
            weapon_unoreverse,
            zombiegunspawn
        }
    }
    CreateConVar("ttt_kevin_starting_health", "150")
    CreateConVar("ttt_kevin_max_health", "150")
    CreateConVar("ttt_kevin_name", role.name, FCVAR_REPLICATED)
    CreateConVar("ttt_kevin_name_plural", role.nameplural, FCVAR_REPLICATED)
    CreateConVar("ttt_kevin_name_article", "", FCVAR_REPLICATED)
    CreateConVar("ttt_kevin_can_see_jesters", "1", FCVAR_REPLICATED)
    CreateConVar("ttt_kevin_update_scoreboard", "1", FCVAR_REPLICATED)

    RegisterRole(role)

    CreateShopConVars(ROLE_KEVIN)

    if SERVER then
        -- Generate this after registering the roles so we have the role IDs
        WIN_KEVIN = GenerateNewWinID(ROLE_KEVIN)

        -- And sync the ID to the client
        net.Start("TTT_SyncWinIDs")
        net.WriteTable(WINS_BY_ROLE)
        net.WriteUInt(WIN_MAX, 16)
        net.Broadcast()
    end

    if CLIENT then
        hook.Add("TTTSyncWinIDs", "RdmtKevinsWin_TTTWinIDsSynced", function()
            -- Grab the new win ID from the lookup table
            WIN_KEVIN = WINS_BY_ROLE[ROLE_KEVIN]
        end)

        LANG.AddToLanguage("english", "hilite_win_kevin", "KEVIN WINS")
        LANG.AddToLanguage("english", "win_kevin", "Kevin has escaped the Wet Bandits for a win!")
        LANG.AddToLanguage("english", "ev_win_kevin", "Kevin has escaped the Wet Bandits for a win!")

        -- Popup
        LANG.AddToLanguage("english", "info_popup_kevin", [[You are {role}!

Use your shop to buy and place traps to aid your fight
against the Wet Bandits!]])
    end
end